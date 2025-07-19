;; Dispute Resolution Contract
;; Handles conflicts between buyers and sellers

;; Error constants
(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-INVALID-INPUT u101)
(define-constant ERR-DISPUTE-NOT-FOUND u102)
(define-constant ERR-DISPUTE-EXISTS u103)
(define-constant ERR-ALREADY-RESOLVED u104)
(define-constant ERR-INVALID-RESOLUTION u105)

;; Data variables
(define-data-var next-dispute-id uint u1)
(define-data-var arbitrator principal tx-sender)

;; Data maps
(define-map disputes
  { dispute-id: uint }
  {
    auction-id: uint,
    complainant: principal,
    respondent: principal,
    dispute-type: (string-ascii 50),
    description: (string-ascii 500),
    status: (string-ascii 20),
    created-block: uint,
    resolution-block: uint,
    resolution: (string-ascii 500)
  }
)

(define-map auction-disputes
  { auction-id: uint }
  { dispute-id: uint, has-dispute: bool }
)

(define-map user-dispute-history
  { user: principal }
  {
    total-disputes: uint,
    resolved-disputes: uint,
    last-dispute-block: uint
  }
)

;; Read-only functions
(define-read-only (get-dispute (dispute-id uint))
  (map-get? disputes { dispute-id: dispute-id })
)

(define-read-only (get-auction-dispute (auction-id uint))
  (match (map-get? auction-disputes { auction-id: auction-id })
    dispute-ref (if (get has-dispute dispute-ref)
      (map-get? disputes { dispute-id: (get dispute-id dispute-ref) })
      none
    )
    none
  )
)

(define-read-only (has-active-dispute (auction-id uint))
  (match (map-get? auction-disputes { auction-id: auction-id })
    dispute-ref (get has-dispute dispute-ref)
    false
  )
)

(define-read-only (get-user-dispute-stats (user principal))
  (map-get? user-dispute-history { user: user })
)

;; Public functions
(define-public (create-dispute
  (auction-id uint)
  (respondent principal)
  (dispute-type (string-ascii 50))
  (description (string-ascii 500))
)
  (let
    (
      (dispute-id (var-get next-dispute-id))
      (current-user-stats (default-to
        { total-disputes: u0, resolved-disputes: u0, last-dispute-block: u0 }
        (map-get? user-dispute-history { user: tx-sender })
      ))
    )
    ;; Input validation
    (asserts! (> (len dispute-type) u0) (err ERR-INVALID-INPUT))
    (asserts! (> (len description) u0) (err ERR-INVALID-INPUT))
    (asserts! (not (is-eq tx-sender respondent)) (err ERR-INVALID-INPUT))

    ;; Check if dispute already exists for this auction
    (asserts! (not (has-active-dispute auction-id)) (err ERR-DISPUTE-EXISTS))

    ;; Create dispute record
    (map-set disputes
      { dispute-id: dispute-id }
      {
        auction-id: auction-id,
        complainant: tx-sender,
        respondent: respondent,
        dispute-type: dispute-type,
        description: description,
        status: "open",
        created-block: block-height,
        resolution-block: u0,
        resolution: ""
      }
    )

    ;; Link auction to dispute
    (map-set auction-disputes
      { auction-id: auction-id }
      { dispute-id: dispute-id, has-dispute: true }
    )

    ;; Update user dispute history
    (map-set user-dispute-history
      { user: tx-sender }
      {
        total-disputes: (+ (get total-disputes current-user-stats) u1),
        resolved-disputes: (get resolved-disputes current-user-stats),
        last-dispute-block: block-height
      }
    )

    ;; Increment dispute ID
    (var-set next-dispute-id (+ dispute-id u1))

    (ok dispute-id)
  )
)

(define-public (resolve-dispute
  (dispute-id uint)
  (resolution (string-ascii 500))
  (winner (string-ascii 20))
)
  (let
    (
      (dispute-data (unwrap! (map-get? disputes { dispute-id: dispute-id }) (err ERR-DISPUTE-NOT-FOUND)))
      (complainant-stats (default-to
        { total-disputes: u0, resolved-disputes: u0, last-dispute-block: u0 }
        (map-get? user-dispute-history { user: (get complainant dispute-data) })
      ))
    )
    ;; Only arbitrator can resolve disputes
    (asserts! (is-eq tx-sender (var-get arbitrator)) (err ERR-NOT-AUTHORIZED))
    ;; Dispute must be open
    (asserts! (is-eq (get status dispute-data) "open") (err ERR-ALREADY-RESOLVED))
    ;; Validate resolution inputs
    (asserts! (> (len resolution) u0) (err ERR-INVALID-INPUT))
    (asserts! (or (is-eq winner "complainant") (is-eq winner "respondent")) (err ERR-INVALID-RESOLUTION))

    ;; Update dispute with resolution
    (map-set disputes
      { dispute-id: dispute-id }
      (merge dispute-data {
        status: "resolved",
        resolution-block: block-height,
        resolution: resolution
      })
    )

    ;; Update auction dispute status
    (map-set auction-disputes
      { auction-id: (get auction-id dispute-data) }
      { dispute-id: dispute-id, has-dispute: false }
    )

    ;; Update complainant's dispute history
    (map-set user-dispute-history
      { user: (get complainant dispute-data) }
      {
        total-disputes: (get total-disputes complainant-stats),
        resolved-disputes: (+ (get resolved-disputes complainant-stats) u1),
        last-dispute-block: (get last-dispute-block complainant-stats)
      }
    )

    (ok { winner: winner, resolution: resolution })
  )
)

(define-public (appeal-dispute (dispute-id uint) (appeal-reason (string-ascii 500)))
  (let
    (
      (dispute-data (unwrap! (map-get? disputes { dispute-id: dispute-id }) (err ERR-DISPUTE-NOT-FOUND)))
    )
    ;; Only parties involved can appeal
    (asserts! (or
      (is-eq tx-sender (get complainant dispute-data))
      (is-eq tx-sender (get respondent dispute-data))
    ) (err ERR-NOT-AUTHORIZED))

    ;; Dispute must be resolved to appeal
    (asserts! (is-eq (get status dispute-data) "resolved") (err ERR-INVALID-INPUT))
    ;; Validate appeal reason
    (asserts! (> (len appeal-reason) u0) (err ERR-INVALID-INPUT))

    ;; Update dispute status to appealed
    (map-set disputes
      { dispute-id: dispute-id }
      (merge dispute-data { status: "appealed" })
    )

    (ok true)
  )
)

(define-public (set-arbitrator (new-arbitrator principal))
  (begin
    ;; Only current arbitrator can change
    (asserts! (is-eq tx-sender (var-get arbitrator)) (err ERR-NOT-AUTHORIZED))

    ;; Update arbitrator
    (var-set arbitrator new-arbitrator)

    (ok true)
  )
)
