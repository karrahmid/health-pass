;; Health Pass - Medical Record/Vaccination Verification Contract
;; Self-Sovereign Identity on Stacks Blockchain

;; Contract constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-EXISTS (err u102))
(define-constant ERR-INVALID-DATA (err u103))
(define-constant ERR-EXPIRED (err u104))

;; Data structures
(define-map identities
  { user: principal }
  {
    did: (string-ascii 64),
    public-key: (buff 33),
    created-at: uint,
    is-active: bool
  }
)

(define-map medical-records
  { user: principal, record-id: (string-ascii 32) }
  {
    record-type: (string-ascii 20),
    issuer: principal,
    data-hash: (buff 32),
    issued-at: uint,
    expires-at: (optional uint),
    is-verified: bool
  }
)

(define-map vaccinations
  { user: principal, vaccine-id: (string-ascii 32) }
  {
    vaccine-name: (string-ascii 50),
    batch-number: (string-ascii 20),
    manufacturer: (string-ascii 50),
    administered-by: principal,
    administered-at: uint,
    expires-at: (optional uint),
    dose-number: uint,
    is-verified: bool
  }
)

(define-map authorized-issuers
  { issuer: principal }
  {
    name: (string-ascii 50),
    license-number: (string-ascii 30),
    authorized-at: uint,
    is-active: bool
  }
)

;; Identity management functions
(define-public (create-identity (did (string-ascii 64)) (public-key (buff 33)))
  (let ((user tx-sender))
    (if (is-some (map-get? identities { user: user }))
      ERR-ALREADY-EXISTS
      (begin
        (map-set identities
          { user: user }
          {
            did: did,
            public-key: public-key,
            created-at: block-height,
            is-active: true
          }
        )
        (ok true)
      )
    )
  )
)

(define-public (update-identity (did (string-ascii 64)) (public-key (buff 33)))
  (let ((user tx-sender))
    (match (map-get? identities { user: user })
      identity-data
      (begin
        (map-set identities
          { user: user }
          (merge identity-data {
            did: did,
            public-key: public-key
          })
        )
        (ok true)
      )
      ERR-NOT-FOUND
    )
  )
)

(define-public (deactivate-identity)
  (let ((user tx-sender))
    (match (map-get? identities { user: user })
      identity-data
      (begin
        (map-set identities
          { user: user }
          (merge identity-data { is-active: false })
        )
        (ok true)
      )
      ERR-NOT-FOUND
    )
  )
)

;; Medical record functions
(define-public (add-medical-record 
  (user principal)
  (record-id (string-ascii 32))
  (record-type (string-ascii 20))
  (data-hash (buff 32))
  (expires-at (optional uint))
)
  (let ((issuer tx-sender))
    (if (and 
          (is-authorized-issuer issuer)
          (is-none (map-get? medical-records { user: user, record-id: record-id }))
        )
      (begin
        (map-set medical-records
          { user: user, record-id: record-id }
          {
            record-type: record-type,
            issuer: issuer,
            data-hash: data-hash,
            issued-at: block-height,
            expires-at: expires-at,
            is-verified: true
          }
        )
        (ok true)
      )
      (if (not (is-authorized-issuer issuer))
        ERR-NOT-AUTHORIZED
        ERR-ALREADY-EXISTS
      )
    )
  )
)

(define-public (add-vaccination
  (user principal)
  (vaccine-id (string-ascii 32))
  (vaccine-name (string-ascii 50))
  (batch-number (string-ascii 20))
  (manufacturer (string-ascii 50))
  (dose-number uint)
  (expires-at (optional uint))
)
  (let ((administered-by tx-sender))
    (if (and 
          (is-authorized-issuer administered-by)
          (is-none (map-get? vaccinations { user: user, vaccine-id: vaccine-id }))
        )
      (begin
        (map-set vaccinations
          { user: user, vaccine-id: vaccine-id }
          {
            vaccine-name: vaccine-name,
            batch-number: batch-number,
            manufacturer: manufacturer,
            administered-by: administered-by,
            administered-at: block-height,
            expires-at: expires-at,
            dose-number: dose-number,
            is-verified: true
          }
        )
        (ok true)
      )
      (if (not (is-authorized-issuer administered-by))
        ERR-NOT-AUTHORIZED
        ERR-ALREADY-EXISTS
      )
    )
  )
)

;; Authorization functions
(define-public (authorize-issuer 
  (issuer principal)
  (name (string-ascii 50))
  (license-number (string-ascii 30))
)
  (if (is-eq tx-sender CONTRACT-OWNER)
    (begin
      (map-set authorized-issuers
        { issuer: issuer }
        {
          name: name,
          license-number: license-number,
          authorized-at: block-height,
          is-active: true
        }
      )
      (ok true)
    )
    ERR-NOT-AUTHORIZED
  )
)

(define-public (revoke-issuer-authorization (issuer principal))
  (if (is-eq tx-sender CONTRACT-OWNER)
    (match (map-get? authorized-issuers { issuer: issuer })
      issuer-data
      (begin
        (map-set authorized-issuers
          { issuer: issuer }
          (merge issuer-data { is-active: false })
        )
        (ok true)
      )
      ERR-NOT-FOUND
    )
    ERR-NOT-AUTHORIZED
  )
)

;; Verification functions
(define-public (verify-vaccination 
  (user principal)
  (vaccine-id (string-ascii 32))
)
  (match (map-get? vaccinations { user: user, vaccine-id: vaccine-id })
    vaccination-data
    (let (
      (is-expired (match (get expires-at vaccination-data)
        exp-time (> block-height exp-time)
        false
      ))
    )
      (if (and 
            (get is-verified vaccination-data)
            (not is-expired)
            (is-authorized-issuer (get administered-by vaccination-data))
          )
        (ok vaccination-data)
        (if is-expired
          ERR-EXPIRED
          ERR-NOT-AUTHORIZED
        )
      )
    )
    ERR-NOT-FOUND
  )
)

(define-public (verify-medical-record
  (user principal)
  (record-id (string-ascii 32))
)
  (match (map-get? medical-records { user: user, record-id: record-id })
    record-data
    (let (
      (is-expired (match (get expires-at record-data)
        exp-time (> block-height exp-time)
        false
      ))
    )
      (if (and 
            (get is-verified record-data)
            (not is-expired)
            (is-authorized-issuer (get issuer record-data))
          )
        (ok record-data)
        (if is-expired
          ERR-EXPIRED
          ERR-NOT-AUTHORIZED
        )
      )
    )
    ERR-NOT-FOUND
  )
)

;; Read-only functions
(define-read-only (get-identity (user principal))
  (map-get? identities { user: user })
)

(define-read-only (get-medical-record (user principal) (record-id (string-ascii 32)))
  (map-get? medical-records { user: user, record-id: record-id })
)

(define-read-only (get-vaccination (user principal) (vaccine-id (string-ascii 32)))
  (map-get? vaccinations { user: user, vaccine-id: vaccine-id })
)

(define-read-only (is-authorized-issuer (issuer principal))
  (match (map-get? authorized-issuers { issuer: issuer })
    issuer-data (get is-active issuer-data)
    false
  )
)

(define-read-only (get-issuer-info (issuer principal))
  (map-get? authorized-issuers { issuer: issuer })
)

;; Utility functions
(define-read-only (is-identity-active (user principal))
  (match (get-identity user)
    identity-data (get is-active identity-data)
    false
  )
)

(define-read-only (get-contract-owner)
  CONTRACT-OWNER
)