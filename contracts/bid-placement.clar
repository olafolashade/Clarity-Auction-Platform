;; Bid Placement Contract
;; Manages competitive bidding process

;; Error constants
(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-INVALID-INPUT u101)
(define-constant ERR-AUCTION-NOT-FOUND u102)
(define-constant ERR-AUCTION-ENDED u103)
(define-constant ERR-INSUFFICIENT-BID u104)
(define-constant ERR-SELF-BID u105)

;; Data variables
(define-data-var next-bid-id uint u1)

;; Data maps
(define-map bids
  { bid-id: uint }
  {
    auction-id: uint,
    bidder: principal,
    amount: uint,
    block-height: uint,
    timestamp: uint
  }
)

(define-map auction-bids
  { auction-id: uint }
  {
    highest-bid: uint,
    highest-bidder: principal,
    total-bids: uint,
    last-bid-block: uint
  }
)

(define-map bidder-history
  { bidder: principal, auction-id: uint }
  {
    highest-bid: uint,
    total-bids: uint,
    last-bid-block: uint
  }
)

;; Read-only functions
(define-read-only (get-bid (bid-id uint))
  (map-get? bids { bid-id: bid-id })
)

(define-read-only (get-auction-bid-info (auction-id uint))
  (map-get? auction-bids { auction-id: auction-id })
)

(define-read-only (get-highest-bid (auction-id uint))
  (match (map-get? auction-bids { auction-id: auction-id })
    bid-info (get highest-bid bid-info)
    u0
  )
)

(define-read-only (get-highest-bidder (auction-id uint))
  (match (map-get? auction-bids { auction-id: auction-id })
    bid-info (some (get highest-bidder bid-info))
    none
  )
)

(define-read-only (get-bidder-history-info (bidder principal) (auction-id uint))
  (map-get? bidder-history { bidder: bidder, auction-id: auction-id })
)

;; Public functions
(define-public (place-bid (auction-id uint) (bid-amount uint))
  (let
    (
      (bid-id (var-get next-bid-id))
      (current-highest (get-highest-bid auction-id))
      (current-bidder-history (default-to
        { highest-bid: u0, total-bids: u0, last-bid-block: u0 }
        (map-get? bidder-history { bidder: tx-sender, auction-id: auction-id })
      ))
      (current-auction-bids (default-to
        { highest-bid: u0, highest-bidder: tx-sender, total-bids: u0, last-bid-block: u0 }
        (map-get? auction-bids { auction-id: auction-id })
      ))
    )
    ;; Input validation
    (asserts! (> bid-amount u0) (err ERR-INVALID-INPUT))
    (asserts! (> bid-amount current-highest) (err ERR-INSUFFICIENT-BID))

    ;; Create bid record
    (map-set bids
      { bid-id: bid-id }
      {
        auction-id: auction-id,
        bidder: tx-sender,
        amount: bid-amount,
        block-height: block-height,
        timestamp: (unwrap-panic (get-block-info? time block-height))
      }
    )

    ;; Update auction bid tracking
    (map-set auction-bids
      { auction-id: auction-id }
      {
        highest-bid: bid-amount,
        highest-bidder: tx-sender,
        total-bids: (+ (get total-bids current-auction-bids) u1),
        last-bid-block: block-height
      }
    )

    ;; Update bidder history
    (map-set bidder-history
      { bidder: tx-sender, auction-id: auction-id }
      {
        highest-bid: (if (> bid-amount (get highest-bid current-bidder-history))
          bid-amount
          (get highest-bid current-bidder-history)
        ),
        total-bids: (+ (get total-bids current-bidder-history) u1),
        last-bid-block: block-height
      }
    )

    ;; Increment bid ID counter
    (var-set next-bid-id (+ bid-id u1))

    (ok bid-id)
  )
)

(define-public (withdraw-bid (auction-id uint))
  (let
    (
      (bidder-info (unwrap! (map-get? bidder-history { bidder: tx-sender, auction-id: auction-id }) (err ERR-NOT-AUTHORIZED)))
      (auction-info (unwrap! (map-get? auction-bids { auction-id: auction-id }) (err ERR-AUCTION-NOT-FOUND)))
    )
    ;; Can only withdraw if not the highest bidder
    (asserts! (not (is-eq tx-sender (get highest-bidder auction-info))) (err ERR-NOT-AUTHORIZED))

    ;; Mark bidder as withdrawn
    (map-set bidder-history
      { bidder: tx-sender, auction-id: auction-id }
      (merge bidder-info { highest-bid: u0 })
    )

    (ok true)
  )
)

(define-public (get-bid-count (auction-id uint))
  (ok (match (map-get? auction-bids { auction-id: auction-id })
    bid-info (get total-bids bid-info)
    u0
  ))
)
