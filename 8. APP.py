import os
import json
import ipfshttpclient
from flask import Flask, request, jsonify
from web3 import Web3
from Crypto.Cipher import AES
from Crypto.Random import get_random_bytes
from base64 import b64encode, b64decode

app = Flask(__name__)

# --- Config ---
ETH_NODE_URL = "https://sepolia.infura.io/v3/YOUR_INFURA_PROJECT_ID"
CONTRACT_ADDRESS = "0xYourContractAddress"
CONTRACT_ABI_PATH = "./VerifiableRecords.json"
IPFS_URL = "/dns/localhost/tcp/5001/http"
VC_ISSUER_DID = "did:example:issuer"
VC_ISSUER_KEY = "YOUR_PRIVATE_KEY"

# --- Setup ---
w3 = Web3(Web3.HTTPProvider(ETH_NODE_URL))
with open(CONTRACT_ABI_PATH, "r") as f:
    contract_abi = json.load(f)
contract = w3.eth.contract(address=CONTRACT_ADDRESS, abi=contract_abi)
ipfs = ipfshttpclient.connect(IPFS_URL)

# --- Encryption ---
def encrypt_file(data: bytes, secret: bytes):
    iv = get_random_bytes(16)
    cipher = AES.new(secret, AES.MODE_CFB, iv)
    ct_bytes = cipher.encrypt(data)
    return b64encode(iv + ct_bytes).decode("utf-8")

def decrypt_file(enc_data: str, secret: bytes):
    enc = b64decode(enc_data)
    iv = enc[:16]
    ct = enc[16:]
    cipher = AES.new(secret, AES.MODE_CFB, iv)
    return cipher.decrypt(ct)

# --- IPFS ---
def upload_to_ipfs(data: bytes):
    res = ipfs.add_bytes(data)
    return res  # This is the IPFS hash

def download_from_ipfs(hash: str):
    return ipfs.cat(hash)

# --- Verifiable Credential (VC) ---
def issue_vc(user_did, degree):
    # Minimal VC JSON, sign with Ed25519 (use DIDKit or similar in production)
    vc = {
        "@context": ["https://www.w3.org/2018/credentials/v1"],
        "type": ["VerifiableCredential", "DegreeCredential"],
        "issuer": VC_ISSUER_DID,
        "credentialSubject": {
            "id": user_did,
            "degree": degree
        }
    }
    # Normally, sign this using your issuer's key (use didkit for prod)
    vc["proof"] = {
        "type": "Ed25519Signature2018",
        "created": "2025-09-02T00:00:00Z",
        "jws": "FAKE_SIGNATURE"
    }
    return vc

# --- ZKP Stub ---
def verify_zkp(proof_params):
    # Integrate with snarkjs/zokrates verifier contract here
    # This is a stub: always returns True
    return True

# --- Flask API Routes ---
@app.route("/upload_record", methods=["POST"])
def upload_record():
    file = request.files["file"]
    secret = request.form["secret"].encode()
    record_type = request.form["type"]
    verifier = request.form["verifier"]
    expires_at = int(request.form.get("expires_at", 0))
    notes = request.form.get("notes", "")
    language = request.form.get("language", "en")

    encrypted = encrypt_file(file.read(), secret)
    ipfs_hash = upload_to_ipfs(encrypted.encode())
    # Call contract to add record
    # Example: addIDRecord(fullName, dob, nationality, address, pob, ipfs_hash, verifier, expires_at, notes, language)
    # You need to prepare all fields and sign/send the tx using user's wallet (metamask, custodial, etc.)

    return jsonify({"ipfs_hash": ipfs_hash})

@app.route("/fetch_record", methods=["GET"])
def fetch_record():
    ipfs_hash = request.args["ipfs_hash"]
    secret = request.args["secret"].encode()
    encrypted = download_from_ipfs(ipfs_hash)
    decrypted = decrypt_file(encrypted.decode(), secret)
    return decrypted

@app.route("/issue_vc", methods=["POST"])
def issue_vc_route():
    user_did = request.json["user_did"]
    degree = request.json["degree"]
    vc = issue_vc(user_did, degree)
    vc_bytes = json.dumps(vc).encode()
    ipfs_hash = upload_to_ipfs(vc_bytes)
    return jsonify({"vc_ipfs_hash": ipfs_hash, "vc": vc})

@app.route("/verify_zkp", methods=["POST"])
def verify_zkp_route():
    proof_params = request.json["proof_params"]
    result = verify_zkp(proof_params)
    return jsonify({"valid": result})

# Add more endpoints as needed for full CRUD and smart contract interaction

if __name__ == "__main__":
    app.run(debug=True)
