```mermaid
flowchart TD
    User["User (Wallet, UI)"]
    Org["Organization (University, Embassy, Employer)"]
    Verifier["Verifier (Government, School, Hospital, etc.)"]
    Contract["VerifiableRecords Smart Contract"]
    IPFS["IPFS/Filecoin Storage"]
    Encryption["Off-chain Encryption/Decryption"]

    User -- uploads/updates --> Encryption
    Encryption -- encrypted files --> IPFS
    User -- submits record URIs & metadata --> Contract
    Verifier -- verifies records --> Contract
    Org -- requests access --> Contract
    User -- grants access --> Contract
    Org -- reads allowed record indexes --> Contract
    Org -- fetches URIs --> IPFS
    Org -- receives key from User (off-chain) --> Encryption
```
- User interacts with UI, uploads files; files are encrypted and stored in IPFS/Filecoin.
- User submits only URIs/hashes and metadata to the smart contract.
- Verifiers (government, schools, etc.) verify relevant records on-chain.
- Organizations request access; user grants access to specific records.
- Organizations fetch record data from IPFS and request decryption keys off-chain.
