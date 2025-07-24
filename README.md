# Health Pass Smart Contract

A self-sovereign identity and medical verification system built on the Stacks blockchain using Clarity smart contracts. This contract enables secure, decentralized management of medical records and vaccination certificates with cryptographic verification.

## Overview

The Health Pass contract provides a comprehensive solution for digital health identity management, allowing users to:
- Create and manage their own digital identities
- Store verified medical records and vaccination certificates
- Enable third-party verification of health credentials
- Maintain privacy while ensuring authenticity

## Features

### 🆔 Self-Sovereign Identity
- **Decentralized Identity Creation**: Users control their own digital identity (DID)
- **Public Key Management**: Cryptographic key storage for identity verification
- **Identity Lifecycle**: Create, update, and deactivate identities as needed
- **Privacy-First**: Users maintain control over their personal data

### 🏥 Medical Record Management
- **Secure Storage**: Medical records stored as cryptographic hashes
- **Authorized Issuers**: Only licensed medical professionals can issue records
- **Expiration Handling**: Time-based validity for sensitive medical data
- **Data Integrity**: Immutable records with verification capabilities

### 💉 Vaccination Tracking
- **Comprehensive Records**: Complete vaccination history with batch numbers
- **Multi-Dose Support**: Track multiple doses for complex vaccination schedules
- **Manufacturer Tracking**: Record vaccine manufacturer and batch information
- **Expiration Management**: Automatic handling of vaccine validity periods

### 🔐 Security & Authorization
- **Role-Based Access**: Differentiated permissions for users, issuers, and administrators
- **License Verification**: Medical professional licensing validation
- **Cryptographic Integrity**: Hash-based data verification
- **Revocation System**: Ability to revoke compromised or invalid credentials

## Contract Architecture

### Data Structures

#### Identities Map
```clarity
{ user: principal } -> {
  did: string-ascii,
  public-key: buff,
  created-at: uint,
  is-active: bool
}
```

#### Medical Records Map
```clarity
{ user: principal, record-id: string-ascii } -> {
  record-type: string-ascii,
  issuer: principal,
  data-hash: buff,
  issued-at: uint,
  expires-at: optional uint,
  is-verified: bool
}
```

#### Vaccinations Map
```clarity
{ user: principal, vaccine-id: string-ascii } -> {
  vaccine-name: string-ascii,
  batch-number: string-ascii,
  manufacturer: string-ascii,
  administered-by: principal,
  administered-at: uint,
  expires-at: optional uint,
  dose-number: uint,
  is-verified: bool
}
```

### Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 100 | ERR-NOT-AUTHORIZED | Caller lacks required permissions |
| 101 | ERR-NOT-FOUND | Requested resource doesn't exist |
| 102 | ERR-ALREADY-EXISTS | Resource already exists |
| 103 | ERR-INVALID-DATA | Provided data is invalid |
| 104 | ERR-EXPIRED | Credential has expired |

## Usage Guide

### For Users

#### 1. Create Digital Identity
```clarity
(contract-call? .health-pass create-identity "did:stx:example123" 0x02a1b2c3d4...)
```

#### 2. Update Identity
```clarity
(contract-call? .health-pass update-identity "did:stx:newexample456" 0x02e5f6g7h8...)
```

#### 3. Verify Your Records
```clarity
(contract-call? .health-pass verify-vaccination tx-sender "vaccine-001")
```

### For Medical Professionals

#### 1. Issue Medical Record
```clarity
(contract-call? .health-pass add-medical-record 
  'SP1ABC...  ; patient address
  "record-001"  ; unique record ID
  "lab-result"  ; record type
  0x12345...    ; data hash
  (some u1000000))  ; expiration block
```

#### 2. Add Vaccination Record
```clarity
(contract-call? .health-pass add-vaccination
  'SP1ABC...      ; patient address
  "vaccine-001"   ; unique vaccine ID
  "COVID-19"      ; vaccine name
  "LOT123"        ; batch number
  "Pfizer"        ; manufacturer
  u1              ; dose number
  (some u2000000)) ; expiration block
```

### For Contract Administrator

#### 1. Authorize Medical Issuer
```clarity
(contract-call? .health-pass authorize-issuer
  'SP1DEF...           ; issuer address
  "Dr. Jane Smith"     ; issuer name
  "MD-12345")          ; license number
```

#### 2. Revoke Issuer Authorization
```clarity
(contract-call? .health-pass revoke-issuer-authorization 'SP1DEF...)
```

## Read-Only Functions

### Query Functions
- `get-identity(user)` - Retrieve user's identity information
- `get-medical-record(user, record-id)` - Get specific medical record
- `get-vaccination(user, vaccine-id)` - Get vaccination details
- `is-authorized-issuer(issuer)` - Check if issuer is authorized
- `get-issuer-info(issuer)` - Get issuer details
- `is-identity-active(user)` - Check if identity is active

## Deployment

### Prerequisites
- Stacks blockchain node access
- Clarity CLI or Clarinet development environment
- STX tokens for contract deployment

### Deployment Steps

1. **Install Clarinet**
```bash
npm install -g @hirosystems/clarinet-cli
```

2. **Initialize Project**
```bash
clarinet new health-pass-project
cd health-pass-project
```

3. **Add Contract**
Place the contract code in `contracts/health-pass.clar`

4. **Deploy to Testnet**
```bash
clarinet deploy --testnet
```

5. **Deploy to Mainnet**
```bash
clarinet deploy --mainnet
```

## Security Considerations

### Best Practices
- **Private Key Security**: Users must securely manage their private keys
- **Issuer Verification**: Always verify issuer authorization before trusting records
- **Expiration Checking**: Regularly check credential expiration dates
- **Hash Verification**: Verify data hashes match off-chain medical records

### Potential Risks
- **Key Compromise**: Lost private keys cannot be recovered
- **Issuer Trust**: System relies on proper vetting of medical professionals
- **Data Privacy**: Medical hashes should not be easily reversible
- **Regulatory Compliance**: Ensure compliance with local healthcare regulations

## Integration Examples

### Web Application Integration
```javascript
// Using Stacks.js
import { callReadOnlyFunction } from '@stacks/transactions';

async function verifyVaccination(userAddress, vaccineId) {
  const result = await callReadOnlyFunction({
    contractAddress: 'SP1234....',
    contractName: 'health-pass',
    functionName: 'verify-vaccination',
    functionArgs: [userAddress, vaccineId],
    network: new StacksMainnet()
  });
  return result;
}
```

### Mobile App Integration
```javascript
// React Native with Stacks
import { StacksMobileSDK } from '@stacks/mobile-sdk';

const addVaccination = async (patientAddress, vaccineData) => {
  const tx = await StacksMobileSDK.makeContractCall({
    contractAddress: CONTRACT_ADDRESS,
    contractName: 'health-pass',
    functionName: 'add-vaccination',
    functionArgs: [
      patientAddress,
      vaccineData.id,
      vaccineData.name,
      vaccineData.batch,
      vaccineData.manufacturer,
      vaccineData.dose,
      vaccineData.expiration
    ]
  });
  return tx;
};
```

## Testing

### Unit Tests
```bash
clarinet test
```

### Integration Tests
Create test scenarios in `tests/health-pass_test.ts`:
- Identity creation and management
- Medical record issuance and verification
- Authorization workflows
- Error handling

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add comprehensive tests
5. Submit a pull request

### Development Guidelines
- Follow Clarity best practices
- Maintain comprehensive documentation
- Ensure backward compatibility
- Add appropriate error handling

**Note**: This smart contract handles sensitive medical information. Always ensure compliance with applicable healthcare regulations (HIPAA, GDPR, etc.) and conduct thorough security audits before production deployment.