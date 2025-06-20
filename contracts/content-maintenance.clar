;; Content Maintenance Contract
;; Maintains and updates knowledge base content

(define-constant ERR_UNAUTHORIZED (err u500))
(define-constant ERR_CONTENT_NOT_FOUND (err u501))
(define-constant ERR_INVALID_STATUS (err u502))

;; Data maps
(define-map maintenance-logs uint {
    content-id: uint,
    action: (string-ascii 50),
    performed-by: principal,
    timestamp: uint,
    notes: (string-ascii 200)
})

(define-map content-status uint (string-ascii 20))
(define-data-var maintenance-counter uint u0)

;; Valid statuses
(define-map valid-statuses (string-ascii 20) bool)
(map-set valid-statuses "active" true)
(map-set valid-statuses "inactive" true)
(map-set valid-statuses "archived" true)
(map-set valid-statuses "under-review" true)

;; Read-only functions
(define-read-only (get-content-status (content-id uint))
    (default-to "active" (map-get? content-status content-id))
)

(define-read-only (get-maintenance-log (log-id uint))
    (map-get? maintenance-logs log-id)
)

(define-read-only (is-valid-status (status (string-ascii 20)))
    (default-to false (map-get? valid-statuses status))
)

;; Public functions
(define-public (update-content-status (content-id uint) (new-status (string-ascii 20)) (notes (string-ascii 200)))
    (let ((log-id (+ (var-get maintenance-counter) u1)))
        (begin
            (asserts! (is-valid-status new-status) ERR_INVALID_STATUS)
            (map-set content-status content-id new-status)
            (map-set maintenance-logs log-id {
                content-id: content-id,
                action: "status-update",
                performed-by: tx-sender,
                timestamp: block-height,
                notes: notes
            })
            (var-set maintenance-counter log-id)
            (ok true)
        )
    )
)

(define-public (archive-content (content-id uint) (reason (string-ascii 200)))
    (let ((log-id (+ (var-get maintenance-counter) u1)))
        (begin
            (map-set content-status content-id "archived")
            (map-set maintenance-logs log-id {
                content-id: content-id,
                action: "archive",
                performed-by: tx-sender,
                timestamp: block-height,
                notes: reason
            })
            (var-set maintenance-counter log-id)
            (ok true)
        )
    )
)

(define-public (restore-content (content-id uint) (notes (string-ascii 200)))
    (let ((log-id (+ (var-get maintenance-counter) u1)))
        (begin
            (map-set content-status content-id "active")
            (map-set maintenance-logs log-id {
                content-id: content-id,
                action: "restore",
                performed-by: tx-sender,
                timestamp: block-height,
                notes: notes
            })
            (var-set maintenance-counter log-id)
            (ok true)
        )
    )
)
