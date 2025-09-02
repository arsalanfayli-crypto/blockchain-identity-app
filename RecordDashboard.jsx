import React, { useState, useEffect } from "react";
import { ethers } from "ethers";
import VerifiableRecordsAbi from "./VerifiableRecords.json";
const CONTRACT_ADDRESS = "0xYourContractAddress";

export default function RecordDashboard({ userWallet }) {
  const [contract, setContract] = useState(null);
  const [records, setRecords] = useState({ id: [], health: [], education: [], career: [], embassy: [] });
  const [accessRequests, setAccessRequests] = useState([]);
  const [selectedIndexes, setSelectedIndexes] = useState([]);
  const [orgAddress, setOrgAddress] = useState("");

  useEffect(() => {
    async function initContract() {
      if (window.ethereum) {
        const provider = new ethers.providers.Web3Provider(window.ethereum);
        const signer = provider.getSigner();
        const c = new ethers.Contract(CONTRACT_ADDRESS, VerifiableRecordsAbi, signer);
        setContract(c);
      }
    }
    initContract();
  }, []);

  // Fetch user's records
  async function fetchRecords() {
    if (!contract) return;
    const id = await contract.getIDRecords(userWallet);
    const health = await contract.getHealthRecords(userWallet);
    const education = await contract.getEducationRecords(userWallet);
    const career = await contract.getCareerRecords(userWallet);
    const embassy = await contract.getEmbassyRecords(userWallet);
    setRecords({ id, health, education, career, embassy });
  }

  // Grant access to selected records
  async function grantAccess(recordType, indexes) {
    if (!contract || !orgAddress) return;
    await contract.grantAccess(orgAddress, recordType, indexes);
  }

  // UI for record display & selection omitted for brevity
  // Add forms for uploading records, updating, revoking, approving access, etc.

  return (
    <div>
      <h1>Your Records</h1>
      <button onClick={fetchRecords}>Refresh</button>
      {/* Render record tables for each type */}
      {/* Render access request/approval UI */}
      {/* Render sharing UI */}
    </div>
  );
}
