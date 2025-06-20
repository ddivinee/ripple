;; Ripple Liquid Mining Protocol
;; A liquid mining contract for the Stacks ecosystem

;; Contract constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-NOT-AUTHORIZED (err u101))
(define-constant ERR-INSUFFICIENT-BALANCE (err u102))
(define-constant ERR-INVALID-AMOUNT (err u103))
(define-constant ERR-POOL-NOT-FOUND (err u104))
(define-constant ERR-ALREADY-STAKED (err u105))
(define-constant ERR-NOT-STAKED (err u106))
(define-constant ERR-MINIMUM-STAKE (err u107))

;; Contract variables
(define-data-var total-staked uint u0)
(define-data-var reward-rate uint u100) ;; 1% per 1000 blocks
(define-data-var minimum-stake uint u1000000) ;; 1 STX minimum
(define-data-var contract-paused bool false)
(define-data-var last-reward-block uint u0)

;; Data maps
(define-map user-stakes
  { user: principal }
  {
    amount: uint,
    stake-block: uint,
    last-claim-block: uint,
    liquid-tokens: uint
  }
)

(define-map pool-info
  { pool-id: uint }
  {
    total-staked: uint,
    reward-multiplier: uint,
    active: bool
  }
)

(define-map user-pool-stakes
  { user: principal, pool-id: uint }
  {
    amount: uint,
    stake-block: uint,
    last-claim-block: uint
  }
)

;; Liquid token supply (represents staked STX)
(define-fungible-token ripple-liquid-token)

;; Read-only functions
(define-read-only (get-user-stake (user principal))
  (map-get? user-stakes { user: user })
)

(define-read-only (get-total-staked)
  (var-get total-staked)
)

(define-read-only (get-reward-rate)
  (var-get reward-rate)
)

(define-read-only (get-contract-info)
  {
    total-staked: (var-get total-staked),
    reward-rate: (var-get reward-rate),
    minimum-stake: (var-get minimum-stake),
    paused: (var-get contract-paused),
    last-reward-block: (var-get last-reward-block)
  }
)

(define-read-only (calculate-pending-rewards (user principal))
  (let (
    (user-info (unwrap! (get-user-stake user) u0))
    (blocks-elapsed (- block-height (get last-claim-block user-info)))
    (stake-amount (get amount user-info))
  )
    (/ (* stake-amount (var-get reward-rate) blocks-elapsed) u100000)
  )
)

(define-read-only (get-liquid-token-balance (user principal))
  (ft-get-balance ripple-liquid-token user)
)

(define-read-only (get-pool-info (pool-id uint))
  (map-get? pool-info { pool-id: pool-id })
)

;; Private functions
(define-private (is-contract-owner)
  (is-eq tx-sender CONTRACT-OWNER)
)

(define-private (update-last-reward-block)
  (var-set last-reward-block block-height)
)

;; Public functions

;; Stake STX and receive liquid tokens
(define-public (stake (amount uint))
  (let (
    (user tx-sender)
    (current-stake (get-user-stake user))
  )
    (asserts! (not (var-get contract-paused)) ERR-NOT-AUTHORIZED)
    (asserts! (>= amount (var-get minimum-stake)) ERR-MINIMUM-STAKE)
    (asserts! (is-none current-stake) ERR-ALREADY-STAKED)
    
    ;; Transfer STX to contract
    (try! (stx-transfer? amount user (as-contract tx-sender)))
    
    ;; Mint liquid tokens (1:1 ratio)
    (try! (ft-mint? ripple-liquid-token amount user))
    
    ;; Update user stake info
    (map-set user-stakes
      { user: user }
      {
        amount: amount,
        stake-block: block-height,
        last-claim-block: block-height,
        liquid-tokens: amount
      }
    )
    
    ;; Update total staked
    (var-set total-staked (+ (var-get total-staked) amount))
    
    (ok amount)
  )
)

;; Add more stake to existing position
(define-public (add-stake (additional-amount uint))
  (let (
    (user tx-sender)
    (current-stake (unwrap! (get-user-stake user) ERR-NOT-STAKED))
    (new-total (+ (get amount current-stake) additional-amount))
  )
    (asserts! (not (var-get contract-paused)) ERR-NOT-AUTHORIZED)
    (asserts! (> additional-amount u0) ERR-INVALID-AMOUNT)
    
    ;; Claim pending rewards first
    (try! (claim-rewards))
    
    ;; Transfer additional STX
    (try! (stx-transfer? additional-amount user (as-contract tx-sender)))
    
    ;; Mint additional liquid tokens
    (try! (ft-mint? ripple-liquid-token additional-amount user))
    
    ;; Update stake info
    (map-set user-stakes
      { user: user }
      {
        amount: new-total,
        stake-block: (get stake-block current-stake),
        last-claim-block: block-height,
        liquid-tokens: (+ (get liquid-tokens current-stake) additional-amount)
      }
    )
    
    ;; Update total staked
    (var-set total-staked (+ (var-get total-staked) additional-amount))
    
    (ok new-total)
  )
)

;; Claim pending rewards
(define-public (claim-rewards)
  (let (
    (user tx-sender)
    (user-info (unwrap! (get-user-stake user) ERR-NOT-STAKED))
    (pending-rewards (calculate-pending-rewards user))
  )
    (asserts! (not (var-get contract-paused)) ERR-NOT-AUTHORIZED)
    (asserts! (> pending-rewards u0) ERR-INVALID-AMOUNT)
    
    ;; Transfer rewards as STX
    (try! (as-contract (stx-transfer? pending-rewards tx-sender user)))
    
    ;; Update last claim block
    (map-set user-stakes
      { user: user }
      (merge user-info { last-claim-block: block-height })
    )
    
    (update-last-reward-block)
    (ok pending-rewards)
  )
)

;; Unstake with liquid tokens (partial or full)
(define-public (unstake (liquid-token-amount uint))
  (let (
    (user tx-sender)
    (user-info (unwrap! (get-user-stake user) ERR-NOT-STAKED))
    (user-liquid-balance (ft-get-balance ripple-liquid-token user))
  )
    (asserts! (not (var-get contract-paused)) ERR-NOT-AUTHORIZED)
    (asserts! (<= liquid-token-amount user-liquid-balance) ERR-INSUFFICIENT-BALANCE)
    (asserts! (> liquid-token-amount u0) ERR-INVALID-AMOUNT)
    
    ;; Claim pending rewards first
    (try! (claim-rewards))
    
    ;; Burn liquid tokens
    (try! (ft-burn? ripple-liquid-token liquid-token-amount user))
    
    ;; Transfer STX back to user
    (try! (as-contract (stx-transfer? liquid-token-amount tx-sender user)))
    
    ;; Update or remove stake info
    (let ((remaining-stake (- (get amount user-info) liquid-token-amount)))
      (if (is-eq remaining-stake u0)
        ;; Remove stake completely
        (map-delete user-stakes { user: user })
        ;; Update with remaining stake
        (map-set user-stakes
          { user: user }
          (merge user-info {
            amount: remaining-stake,
            liquid-tokens: (- (get liquid-tokens user-info) liquid-token-amount)
          })
        )
      )
    )
    
    ;; Update total staked
    (var-set total-staked (- (var-get total-staked) liquid-token-amount))
    
    (ok liquid-token-amount)
  )
)

;; Emergency unstake (forfeit rewards)
(define-public (emergency-unstake)
  (let (
    (user tx-sender)
    (user-info (unwrap! (get-user-stake user) ERR-NOT-STAKED))
    (stake-amount (get amount user-info))
    (liquid-tokens (get liquid-tokens user-info))
  )
    ;; Burn all liquid tokens
    (try! (ft-burn? ripple-liquid-token liquid-tokens user))
    
    ;; Return original stake
    (try! (as-contract (stx-transfer? stake-amount tx-sender user)))
    
    ;; Remove stake info
    (map-delete user-stakes { user: user })
    
    ;; Update total staked
    (var-set total-staked (- (var-get total-staked) stake-amount))
    
    (ok stake-amount)
  )
)

;; Admin functions
(define-public (set-reward-rate (new-rate uint))
  (begin
    (asserts! (is-contract-owner) ERR-OWNER-ONLY)
    (var-set reward-rate new-rate)
    (ok true)
  )
)

(define-public (set-minimum-stake (new-minimum uint))
  (begin
    (asserts! (is-contract-owner) ERR-OWNER-ONLY)
    (var-set minimum-stake new-minimum)
    (ok true)
  )
)

(define-public (pause-contract)
  (begin
    (asserts! (is-contract-owner) ERR-OWNER-ONLY)
    (var-set contract-paused true)
    (ok true)
  )
)

(define-public (unpause-contract)
  (begin
    (asserts! (is-contract-owner) ERR-OWNER-ONLY)
    (var-set contract-paused false)
    (ok true)
  )
)

;; Create a new mining pool
(define-public (create-pool (pool-id uint) (reward-multiplier uint))
  (begin
    (asserts! (is-contract-owner) ERR-OWNER-ONLY)
    (asserts! (is-none (get-pool-info pool-id)) ERR-ALREADY-STAKED)
    
    (map-set pool-info
      { pool-id: pool-id }
      {
        total-staked: u0,
        reward-multiplier: reward-multiplier,
        active: true
      }
    )
    (ok true)
  )
)

;; Initialize contract
(define-public (initialize)
  (begin
    (asserts! (is-contract-owner) ERR-OWNER-ONLY)
    (var-set last-reward-block block-height)
    (ok true)
  )
)