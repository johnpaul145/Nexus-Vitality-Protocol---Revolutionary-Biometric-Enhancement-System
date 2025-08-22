;; Nexus Vitality Protocol Smart Contract
;; Orchestrates biometric enhancement quests, metamorphic achievements, and quantum reward distribution

;; Error codes
(define-constant ERR-FORBIDDEN-PROTOCOL-ACCESS (err u100))
(define-constant ERR-SENTINEL-ALREADY-REGISTERED (err u101))
(define-constant ERR-SENTINEL-CODEX-NOT-FOUND (err u102))
(define-constant ERR-INVALID-ENHANCEMENT-PARAMETERS (err u103))
(define-constant ERR-INSUFFICIENT-QUANTUM-RESERVES (err u104))
(define-constant ERR-INVALID-QUANTUM-ALLOCATION (err u105))
(define-constant ERR-INVALID-BIOMETRIC-UNITS (err u106))
(define-constant ERR-INVALID-METAMORPHOSIS-ID (err u107))

;; Data variables
(define-data-var protocol-sovereign principal tx-sender)
(define-data-var quantum-reserve-pool uint u0)
(define-data-var sentinel-registry-count uint u0)

;; Data maps
(define-map sentinel-codex
    principal
    {
        vitality-index: uint,
        enhancement-sequences: uint,
        transcendence-tier: uint,
        last-biometric-sync: uint,
        harvested-quanta: uint,
        active-metamorphosis-count: uint,
    }
)

(define-map metamorphosis-protocols
    {
        sentinel-address: principal,
        metamorphosis-id: uint,
    }
    {
        enhancement-threshold: uint,
        biometric-progression: uint,
        convergence-deadline: uint,
        metamorphosis-achieved: bool,
        quantum-yield: uint,
        enhancement-archetype: (string-ascii 20),
    }
)

(define-map sentinel-insignia
    principal
    (list 10 (string-ascii 30))
)

;; Public functions

;; Initialize new sentinel
(define-public (register-sentinel)
    (let ((sentinel-address tx-sender))
        (asserts! (is-none (map-get? sentinel-codex sentinel-address))
            (err ERR-SENTINEL-ALREADY-REGISTERED)
        )
        (map-set sentinel-codex sentinel-address {
            vitality-index: u0,
            enhancement-sequences: u0,
            transcendence-tier: u1,
            last-biometric-sync: (unwrap-panic (get-block-info? time u0)),
            harvested-quanta: u0,
            active-metamorphosis-count: u0,
        })
        (var-set sentinel-registry-count (+ (var-get sentinel-registry-count) u1))
        (ok true)
    )
)

;; Initialize enhancement metamorphosis
(define-public (initiate-metamorphosis-protocol
        (enhancement-threshold uint)
        (convergence-deadline uint)
        (enhancement-archetype (string-ascii 20))
    )
    (let (
            (sentinel-address tx-sender)
            (sentinel-data (unwrap! (map-get? sentinel-codex sentinel-address)
                ERR-SENTINEL-CODEX-NOT-FOUND
            ))
            (metamorphosis-id (+ (get active-metamorphosis-count sentinel-data) u1))
        )
        (asserts! (> enhancement-threshold u0) ERR-INVALID-ENHANCEMENT-PARAMETERS)
        (asserts!
            (> convergence-deadline (unwrap-panic (get-block-info? time u0)))
            ERR-INVALID-ENHANCEMENT-PARAMETERS
        )
        (asserts! (<= (len enhancement-archetype) u20)
            ERR-INVALID-ENHANCEMENT-PARAMETERS
        )

        (map-set metamorphosis-protocols {
            sentinel-address: sentinel-address,
            metamorphosis-id: metamorphosis-id,
        } {
            enhancement-threshold: enhancement-threshold,
            biometric-progression: u0,
            convergence-deadline: convergence-deadline,
            metamorphosis-achieved: false,
            quantum-yield: (calculate-quantum-reward enhancement-threshold),
            enhancement-archetype: enhancement-archetype,
        })

        (map-set sentinel-codex sentinel-address
            (merge sentinel-data { active-metamorphosis-count: metamorphosis-id })
        )
        (ok metamorphosis-id)
    )
)

;; Record biometric enhancement and update progression
(define-public (synchronize-biometric-data
        (metamorphosis-id uint)
        (biometric-units uint)
    )
    (let (
            (sentinel-address tx-sender)
            (sentinel-data (unwrap! (map-get? sentinel-codex sentinel-address)
                ERR-SENTINEL-CODEX-NOT-FOUND
            ))
        )
        (asserts! (> biometric-units u0) ERR-INVALID-BIOMETRIC-UNITS)
        (asserts!
            (<= metamorphosis-id (get active-metamorphosis-count sentinel-data))
            ERR-INVALID-METAMORPHOSIS-ID
        )

        (let (
                (protocol-data (unwrap!
                    (map-get? metamorphosis-protocols {
                        sentinel-address: sentinel-address,
                        metamorphosis-id: metamorphosis-id,
                    })
                    ERR-INVALID-METAMORPHOSIS-ID
                ))
                (sync-timestamp (unwrap-panic (get-block-info? time u0)))
            )
            (asserts! (not (get metamorphosis-achieved protocol-data))
                ERR-INVALID-ENHANCEMENT-PARAMETERS
            )
            (asserts!
                (<= sync-timestamp (get convergence-deadline protocol-data))
                ERR-INVALID-ENHANCEMENT-PARAMETERS
            )

            (let (
                    (updated-progression (+ (get biometric-progression protocol-data) biometric-units))
                    (transcendence-reached (>= updated-progression
                        (get enhancement-threshold protocol-data)
                    ))
                    (vitality-amplification (calculate-vitality-amplification biometric-units))
                    (enhanced-vitality-index (+ (get vitality-index sentinel-data) vitality-amplification))
                )
                ;; Update metamorphosis progression
                (map-set metamorphosis-protocols {
                    sentinel-address: sentinel-address,
                    metamorphosis-id: metamorphosis-id,
                }
                    (merge protocol-data {
                        biometric-progression: updated-progression,
                        metamorphosis-achieved: transcendence-reached,
                    })
                )

                ;; Update sentinel codex
                (map-set sentinel-codex sentinel-address
                    (merge sentinel-data {
                        vitality-index: enhanced-vitality-index,
                        enhancement-sequences: (+ (get enhancement-sequences sentinel-data) u1),
                        last-biometric-sync: sync-timestamp,
                        transcendence-tier: (calculate-transcendence-tier enhanced-vitality-index),
                    })
                )

                ;; Grant insignia if metamorphosis achieved
                (if transcendence-reached
                    (bestow-insignia sentinel-address
                        (concat "Nexus "
                            (get enhancement-archetype protocol-data)
                        ))
                    true
                )

                (ok {
                    updated-progression: updated-progression,
                    transcendence-reached: transcendence-reached,
                    enhanced-vitality-index: enhanced-vitality-index,
                })
            )
        )
    )
)

;; Harvest quantum rewards for completed metamorphosis
(define-public (harvest-quantum-yield (metamorphosis-id uint))
    (let (
            (sentinel-address tx-sender)
            (sentinel-data (unwrap! (map-get? sentinel-codex sentinel-address)
                ERR-SENTINEL-CODEX-NOT-FOUND
            ))
        )
        (asserts!
            (<= metamorphosis-id (get active-metamorphosis-count sentinel-data))
            ERR-INVALID-METAMORPHOSIS-ID
        )

        (let ((protocol-data (unwrap!
                (map-get? metamorphosis-protocols {
                    sentinel-address: sentinel-address,
                    metamorphosis-id: metamorphosis-id,
                })
                ERR-INVALID-METAMORPHOSIS-ID
            )))
            (asserts! (get metamorphosis-achieved protocol-data)
                ERR-INVALID-ENHANCEMENT-PARAMETERS
            )
            (asserts!
                (>= (var-get quantum-reserve-pool)
                    (get quantum-yield protocol-data)
                )
                ERR-INSUFFICIENT-QUANTUM-RESERVES
            )

            ;; Distribute quantum rewards
            (var-set quantum-reserve-pool
                (- (var-get quantum-reserve-pool)
                    (get quantum-yield protocol-data)
                ))
            (map-set sentinel-codex sentinel-address
                (merge sentinel-data { harvested-quanta: (+ (get harvested-quanta sentinel-data)
                    (get quantum-yield protocol-data)
                ) }
                ))

            (ok (get quantum-yield protocol-data))
        )
    )
)

;; Private functions

;; Calculate quantum reward based on enhancement threshold
(define-private (calculate-quantum-reward (enhancement-threshold uint))
    (let ((quantum-multiplier u150))
        (* quantum-multiplier (/ enhancement-threshold u100))
    )
)

;; Calculate vitality amplification for biometric data
(define-private (calculate-vitality-amplification (biometric-units uint))
    (* biometric-units u15)
)

;; Calculate transcendence tier based on vitality index
(define-private (calculate-transcendence-tier (total-vitality uint))
    (+ u1 (/ total-vitality u1200))
)

;; Bestow achievement insignia
(define-private (bestow-insignia
        (sentinel-address principal)
        (insignia-name (string-ascii 30))
    )
    (let ((existing-insignia (default-to (list) (map-get? sentinel-insignia sentinel-address))))
        (map-set sentinel-insignia sentinel-address
            (unwrap-panic (as-max-len? (append existing-insignia insignia-name) u10))
        )
    )
)

;; Read-only functions

;; Get sentinel profile
(define-read-only (get-sentinel-codex (sentinel-address principal))
    (map-get? sentinel-codex sentinel-address)
)

;; Get metamorphosis protocol details
(define-read-only (get-metamorphosis-protocol
        (sentinel-address principal)
        (metamorphosis-id uint)
    )
    (map-get? metamorphosis-protocols {
        sentinel-address: sentinel-address,
        metamorphosis-id: metamorphosis-id,
    })
)

;; Get sentinel achievements
(define-read-only (get-sentinel-insignia (sentinel-address principal))
    (map-get? sentinel-insignia sentinel-address)
)

;; Get protocol statistics
(define-read-only (get-nexus-metrics)
    {
        total-sentinels: (var-get sentinel-registry-count),
        available-quantum-reserves: (var-get quantum-reserve-pool),
    }
)

;; Administrative functions

;; Infuse quantum reserves (only protocol sovereign)
(define-public (infuse-quantum-reserves (quantum-amount uint))
    (begin
        (asserts! (is-eq tx-sender (var-get protocol-sovereign))
            ERR-FORBIDDEN-PROTOCOL-ACCESS
        )
        (asserts! (> quantum-amount u0) ERR-INVALID-QUANTUM-ALLOCATION)
        (var-set quantum-reserve-pool
            (+ (var-get quantum-reserve-pool) quantum-amount)
        )
        (ok true)
    )
)

;; Transfer protocol sovereignty
(define-public (transfer-protocol-sovereignty (new-sovereign principal))
    (begin
        (asserts! (is-eq tx-sender (var-get protocol-sovereign))
            ERR-FORBIDDEN-PROTOCOL-ACCESS
        )
        (asserts! (not (is-eq new-sovereign (var-get protocol-sovereign)))
            ERR-FORBIDDEN-PROTOCOL-ACCESS
        )
        (var-set protocol-sovereign new-sovereign)
        (ok true)
    )
)
