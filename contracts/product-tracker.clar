
;; title: product-tracker
;; version:
;; summary:
;; description:


(define-non-fungible-token warranty uint)

(define-data-var warranty-id-nonce uint u0)

(define-map warranty-details
  uint
  {
    product-id: (string-ascii 64),
    manufacturer: principal,
    issue-date: uint,
    expiry-date: uint,
    product-name: (string-ascii 64),
    product-serial: (string-ascii 64),
    warranty-terms: (string-utf8 256),
    transferable: bool,
    active: bool
  }
)

(define-map product-warranties
  (string-ascii 64)
  (list 10 uint)
)

(define-map manufacturer-products
  principal
  (list 100 (string-ascii 64))
)

(define-map warranty-history
  uint
  (list 20 {owner: principal, timestamp: uint})
)

(define-read-only (get-last-warranty-id)
  (var-get warranty-id-nonce)
)

(define-read-only (get-warranty-details (warranty-id uint))
  (map-get? warranty-details warranty-id)
)

(define-read-only (get-product-warranties (product-id (string-ascii 64)))
  (map-get? product-warranties product-id)
)

(define-read-only (get-manufacturer-products (manufacturer principal))
  (map-get? manufacturer-products manufacturer)
)

(define-read-only (get-warranty-history (warranty-id uint))
  (map-get? warranty-history warranty-id)
)

(define-read-only (is-warranty-active (warranty-id uint))
  (match (map-get? warranty-details warranty-id)
    warranty-info (and (get active warranty-info) 
                       (<= stacks-block-height (get expiry-date warranty-info)))
    false
  )
)

(define-read-only (get-warranty-owner (warranty-id uint))
  (nft-get-owner? warranty warranty-id)
)

(define-public (register-product 
                (product-id (string-ascii 64))
                (product-name (string-ascii 64))
                (product-serial (string-ascii 64))
                (warranty-duration uint)
                (warranty-terms (string-utf8 256))
                (transferable bool))
  (let
    (
      (manufacturer tx-sender)
      (warranty-id (+ (var-get warranty-id-nonce) u1))
      (issue-date stacks-block-height)
      (expiry-date (+ stacks-block-height warranty-duration))
      (manufacturer-product-list (default-to (list) (map-get? manufacturer-products manufacturer)))
      (product-warranty-list (default-to (list) (map-get? product-warranties product-id)))
    )
    (asserts! (is-none (map-get? warranty-details warranty-id)) (err u1))
    
    (try! (nft-mint? warranty warranty-id tx-sender))
    
    (map-set warranty-details warranty-id
      {
        product-id: product-id,
        manufacturer: manufacturer,
        issue-date: issue-date,
        expiry-date: expiry-date,
        product-name: product-name,
        product-serial: product-serial,
        warranty-terms: warranty-terms,
        transferable: transferable,
        active: true
      }
    )
    
    (map-set warranty-history warranty-id 
      (list {owner: tx-sender, timestamp: stacks-block-height})
    )
    
    (asserts! (< (len product-warranty-list) u10) (err u10))
    (map-set product-warranties product-id
      (unwrap! (as-max-len? (append product-warranty-list warranty-id) u10) (err u11))
    )
    
    (asserts! (< (len manufacturer-product-list) u100) (err u12))
    (map-set manufacturer-products manufacturer
      (if (is-some (index-of? manufacturer-product-list product-id))
        manufacturer-product-list
        (unwrap! (as-max-len? (append manufacturer-product-list product-id) u100) (err u13))
      )
    )
    
    (var-set warranty-id-nonce warranty-id)
    (ok warranty-id)
  )
)

(define-public (transfer-warranty (warranty-id uint) (recipient principal))
  (let
    (
      (warranty-info (unwrap! (map-get? warranty-details warranty-id) (err u2)))
      (current-owner (unwrap! (nft-get-owner? warranty warranty-id) (err u3)))
      (history (default-to (list) (map-get? warranty-history warranty-id)))
    )
    (asserts! (is-eq tx-sender current-owner) (err u4))
    (asserts! (get transferable warranty-info) (err u5))
    (asserts! (get active warranty-info) (err u6))
    (asserts! (<= stacks-block-height (get expiry-date warranty-info)) (err u7))
    
    (try! (nft-transfer? warranty warranty-id tx-sender recipient))
    
    (map-set warranty-history warranty-id
      (unwrap! (as-max-len? (append history {owner: recipient, timestamp: stacks-block-height}) u20) (err u14))
    )
    
    (ok true)
  )
)

(define-public (void-warranty (warranty-id uint))
  (let
    (
      (warranty-info (unwrap! (map-get? warranty-details warranty-id) (err u2)))
    )
    (asserts! (is-eq tx-sender (get manufacturer warranty-info)) (err u8))
    
    (map-set warranty-details warranty-id
      (merge warranty-info {active: false})
    )
    
    (ok true)
  )
)

(define-public (extend-warranty (warranty-id uint) (additional-duration uint))
  (let
    (
      (warranty-info (unwrap! (map-get? warranty-details warranty-id) (err u2)))
      (current-expiry (get expiry-date warranty-info))
      (new-expiry (+ current-expiry additional-duration))
    )
    (asserts! (is-eq tx-sender (get manufacturer warranty-info)) (err u8))
    
    (map-set warranty-details warranty-id
      (merge warranty-info {expiry-date: new-expiry})
    )
    
    (ok true)
  )
)

(define-public (update-warranty-terms (warranty-id uint) (new-terms (string-utf8 256)))
  (let
    (
      (warranty-info (unwrap! (map-get? warranty-details warranty-id) (err u2)))
    )
    (asserts! (is-eq tx-sender (get manufacturer warranty-info)) (err u8))
    
    (map-set warranty-details warranty-id
      (merge warranty-info {warranty-terms: new-terms})
    )
    
    (ok true)
  )
)

(define-public (make-warranty-transferable (warranty-id uint))
  (let
    (
      (warranty-info (unwrap! (map-get? warranty-details warranty-id) (err u2)))
    )
    (asserts! (is-eq tx-sender (get manufacturer warranty-info)) (err u8))
    (asserts! (not (get transferable warranty-info)) (err u9))
    
    (map-set warranty-details warranty-id
      (merge warranty-info {transferable: true})
    )
    
    (ok true)
  )
)


(define-map serial-to-warranty
    (string-ascii 64)
    uint)

(define-read-only (get-warranty-by-serial 
    (product-serial (string-ascii 64)))
    (match (map-get? serial-to-warranty product-serial)
        warranty-id (get-warranty-details warranty-id)
        none))

(define-public (update-register-product 
    (product-id (string-ascii 64))
    (product-name (string-ascii 64))
    (product-serial (string-ascii 64))
    (warranty-duration uint)
    (warranty-terms (string-utf8 256))
    (transferable bool))
    (let
        ((warranty-id (try! (register-product 
            product-id
            product-name
            product-serial
            warranty-duration
            warranty-terms
            transferable))))
        (map-set serial-to-warranty product-serial warranty-id)
        (ok warranty-id)))


  

(define-constant WARRANTY_EXTENSION_COST u1000000)

(define-map warranty-renewals
    uint
    (list 5 {
        extension-duration: uint,
        payment-amount: uint,
        renewal-date: uint
    }))

(define-read-only (get-warranty-renewals (warranty-id uint))
    (map-get? warranty-renewals warranty-id))

(define-public (renew-warranty-with-payment 
    (warranty-id uint) 
    (extension-duration uint))
    (let
        ((warranty-info (unwrap! (map-get? warranty-details warranty-id) (err u2)))
         (current-owner (unwrap! (nft-get-owner? warranty warranty-id) (err u3)))
         (renewal-history (default-to (list) (map-get? warranty-renewals warranty-id)))
         (payment-amount WARRANTY_EXTENSION_COST))
        
        (asserts! (is-eq tx-sender current-owner) (err u4))
        (asserts! (get active warranty-info) (err u6))
        (asserts! (<= (len renewal-history) u5) (err u15))
        
        (try! (stx-transfer? payment-amount tx-sender (get manufacturer warranty-info)))
        (try! (extend-warranty warranty-id extension-duration))
        
        (map-set warranty-renewals warranty-id
            (unwrap! (as-max-len? 
                (append renewal-history {
                    extension-duration: extension-duration,
                    payment-amount: payment-amount,
                    renewal-date: stacks-block-height
                }) 
                u5) 
                (err u16)))
        
        (ok true)))