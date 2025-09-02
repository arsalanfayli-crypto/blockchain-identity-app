import { create as createIPFS } from "ipfs-http-client";
import CryptoJS from "crypto-js";

const ipfs = createIPFS({ url: "https://ipfs.infura.io:5001/api/v0" });

export async function uploadEncryptedFile(fileBuffer, secretKey) {
  // Encrypt file buffer
  const encrypted = CryptoJS.AES.encrypt(
    fileBuffer.toString("base64"),
    secretKey
  ).toString();
  // Save encrypted string as buffer to IPFS
  const { path } = await ipfs.add(Buffer.from(encrypted));
  return path; // Store this as URI in the contract
}

export async function fetchAndDecryptFile(ipfsHash, secretKey) {
  const chunks = [];
  for await (const chunk of ipfs.cat(ipfsHash)) {
    chunks.push(chunk);
  }
  const encryptedStr = Buffer.concat(chunks).toString();
  const bytes = CryptoJS.AES.decrypt(encryptedStr, secretKey);
  return Buffer.from(bytes.toString(CryptoJS.enc.Utf8), "base64");
}
