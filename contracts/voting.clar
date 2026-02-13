;; Simple Voting Contract

(define-data-var votes-a uint u0)
(define-data-var votes-b uint u0)

(define-map voted { user: principal } { has-voted: bool })

;; Vote for A
(define-public (vote-a)
  (begin
    (asserts! (is-none (map-get? voted { user: tx-sender })) (err u100))
    (map-set voted { user: tx-sender } { has-voted: true })
    (var-set votes-a (+ (var-get votes-a) u1))
    (ok "Voted A")
  )
)

;; Vote for B
(define-public (vote-b)
  (begin
    (asserts! (is-none (map-get? voted { user: tx-sender })) (err u100))
    (map-set voted { user: tx-sender } { has-voted: true })
    (var-set votes-b (+ (var-get votes-b) u1))
    (ok "Voted B")
  )
)

;; Read-only results
(define-read-only (get-results)
  { a: (var-get votes-a), b: (var-get votes-b) }
)
