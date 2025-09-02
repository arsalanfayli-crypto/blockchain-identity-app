import didkit
import json

def issue_and_sign_vc(user_did, degree, issuer_did, issuer_key):
    vc = {
        "@context": ["https://www.w3.org/2018/credentials/v1"],
        "type": ["VerifiableCredential", "DegreeCredential"],
        "issuer": issuer_did,
        "credentialSubject": {
            "id": user_did,
            "degree": degree
        }
    }
    proof_options = {
        "proofPurpose": "assertionMethod",
        "verificationMethod": issuer_did + "#key-1"
    }
    vc_signed = didkit.issue_credential(
        json.dumps(vc),
        json.dumps(proof_options),
        issuer_key
    )
    return json.loads(vc_signed)
