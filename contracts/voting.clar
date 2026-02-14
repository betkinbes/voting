;; Simple Voting Contract

(define-data-var votes-a uint u0)
(define-data-var votes-b uint u0)
(define-data-var voting-start uint u0)
(define-data-var voting-end uint u0)
(define-data-var total-voters uint u0)

(define-map voted { user: principal } { has-voted: bool, choice: (string-ascii 1) })

;; Error constants
(define-constant ERR-ALREADY-VOTED (err u100))
(define-constant ERR-VOTING-NOT-STARTED (err u101))
(define-constant ERR-VOTING-ENDED (err u102))
(define-constant ERR-NOT-AUTHORIZED (err u103))
(define-constant ERR-INVALID-DURATION (err u104))

;; Initialize voting (admin only - can be called by contract owner)
(define-public (initialize-voting (duration uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> duration u0) ERR-INVALID-DURATION)
    
    (var-set voting-start stacks-block-height)
    (var-set voting-end (+ stacks-block-height duration))
    (var-set votes-a u0)
    (var-set votes-b u0)
    (var-set total-voters u0)
    
    (print {
      event: "voting-initialized",
      start-block: stacks-block-height,
      end-block: (+ stacks-block-height duration),
      duration: duration,
      initialized-by: tx-sender,
      timestamp: stacks-block-height
    })
    
    (ok true)
  )
)

;; Vote for A
(define-public (vote-a)
  (begin
    (asserts! (>= stacks-block-height (var-get voting-start)) ERR-VOTING-NOT-STARTED)
    (asserts! (< stacks-block-height (var-get voting-end)) ERR-VOTING-ENDED)
    (asserts! (is-none (map-get? voted { user: tx-sender })) ERR-ALREADY-VOTED)
    
    (let ((previous-a (var-get votes-a))
          (new-total (+ (var-get total-voters) u1)))
      
      (map-set voted { user: tx-sender } { has-voted: true, choice: "A" })
      (var-set votes-a (+ previous-a u1))
      (var-set total-voters new-total)
      
      (print {
        event: "vote-cast",
        voter: tx-sender,
        choice: "A",
        previous-votes-a: previous-a,
        new-votes-a: (+ previous-a u1),
        previous-votes-b: (var-get votes-b),
        new-votes-b: (var-get votes-b),
        total-votes: new-total,
        block-height: stacks-block-height
      })
      
      (ok "Voted A")
    )
  )
)

;; Vote for B
(define-public (vote-b)
  (begin
    (asserts! (>= stacks-block-height (var-get voting-start)) ERR-VOTING-NOT-STARTED)
    (asserts! (< stacks-block-height (var-get voting-end)) ERR-VOTING-ENDED)
    (asserts! (is-none (map-get? voted { user: tx-sender })) ERR-ALREADY-VOTED)
    
    (let ((previous-b (var-get votes-b))
          (new-total (+ (var-get total-voters) u1)))
      
      (map-set voted { user: tx-sender } { has-voted: true, choice: "B" })
      (var-set votes-b (+ previous-b u1))
      (var-set total-voters new-total)
      
      (print {
        event: "vote-cast",
        voter: tx-sender,
        choice: "B",
        previous-votes-a: (var-get votes-a),
        new-votes-a: (var-get votes-a),
        previous-votes-b: previous-b,
        new-votes-b: (+ previous-b u1),
        total-votes: new-total,
        block-height: stacks-block-height
      })
      
      (ok "Voted B")
    )
  )
)

;; Close voting early (admin only)
(define-public (close-voting-early)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (< stacks-block-height (var-get voting-end)) ERR-VOTING-ENDED)
    
    (let ((old-end (var-get voting-end)))
      (var-set voting-end stacks-block-height)
      
      (print {
        event: "voting-closed-early",
        closed-by: tx-sender,
        original-end-block: old-end,
        new-end-block: stacks-block-height,
        final-votes-a: (var-get votes-a),
        final-votes-b: (var-get votes-b),
        total-votes: (var-get total-voters),
        timestamp: stacks-block-height
      })
      
      (ok true)
    )
  )
)

;; Read-only results
(define-read-only (get-results)
  { 
    a: (var-get votes-a), 
    b: (var-get votes-b),
    total: (var-get total-voters),
    start: (var-get voting-start),
    end: (var-get voting-end),
    is-active: (and (>= stacks-block-height (var-get voting-start))
                   (< stacks-block-height (var-get voting-end)))
  }
)

;; Check if a user has voted
(define-read-only (has-voted (user principal))
  (match (map-get? voted { user: user })
    data (ok true)
    (err false)
  )
)

;; Get voting status
(define-read-only (get-voting-status)
  {
    is-active: (and (>= stacks-block-height (var-get voting-start))
                   (< stacks-block-height (var-get voting-end))),
    time-remaining: (if (< stacks-block-height (var-get voting-end))
                       (- (var-get voting-end) stacks-block-height)
                       u0),
    has-started: (>= stacks-block-height (var-get voting-start)),
    has-ended: (>= stacks-block-height (var-get voting-end))
  }
)

;; Contract owner constant
(define-constant CONTRACT-OWNER tx-sender)
