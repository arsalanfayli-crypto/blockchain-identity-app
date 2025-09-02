// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @title VerifiableRecords - Extensible Blockchain Credential System
/// @author Copilot
/// @notice Supports selective sharing, revocation, audit trail, meta-data, expiry, multi-admin, and off-chain privacy hooks.

contract VerifiableRecords {
    // Multi-admin (simple demo, can expand for real multi-sig)
    address[] public admins;
    mapping(address => bool) public isAdmin;

    // Record types and statuses
    enum Status { Pending, Verified, Rejected, Revoked }
    enum RecordType { ID, Health, Education, Career, Embassy }

    // Expiry struct
    struct Validity {
        uint256 issuedAt;
        uint256 expiresAt; // 0 if never expires
    }

    // Meta-data struct
    struct MetaData {
        string notes;
        string language;
    }

    // ID Record
    struct IDRecord {
        string fullName;
        string dateOfBirth;
        string nationality;
        string address_;
        string placeOfBirth;
        string drivingLicenseURI;
        Status status;
        address verifier;
        Validity validity;
        MetaData meta;
    }

    // Health Record
    struct HealthRecord {
        string medicalRecordsURI;
        string allergies;
        string diseases;
        string previousSurgeries;
        string disabilities;
        Status status;
        address verifier;
        Validity validity;
        MetaData meta;
    }

    // Education Record
    struct EducationRecord {
        string[] previousSchools;
        string[] degrees;
        string[] marks;
        string[] universitiesApplied;
        Status status;
        address verifier;
        Validity validity;
        MetaData meta;
    }

    // Career Record
    struct CareerRecord {
        string[] previousJobs;
        string cvURI;
        string[] skills;
        string[] experiences;
        Status status;
        address verifier;
        Validity validity;
        MetaData meta;
    }

    // Embassy Record
    struct EmbassyRecord {
        string[] passportURIs;
        string bankStatementURI;
        string[] visasApplied;
        string proofOfAge;
        Status status;
        address verifier;
        Validity validity;
        MetaData meta;
    }

    // User mappings
    mapping(address => IDRecord[]) public idRecords;
    mapping(address => HealthRecord[]) public healthRecords;
    mapping(address => EducationRecord[]) public educationRecords;
    mapping(address => CareerRecord[]) public careerRecords;
    mapping(address => EmbassyRecord[]) public embassyRecords;

    // Verifiers
    mapping(address => bool) public govVerifiers;
    mapping(address => bool) public healthVerifiers;
    mapping(address => bool) public schoolVerifiers;
    mapping(address => bool) public companyVerifiers;
    mapping(address => bool) public embassyVerifiers;

    // Selective sharing: user => org => record type => array of indexes
    mapping(address => mapping(address => mapping(RecordType => uint[]))) public sharedRecords;

    // Audit trail
    event RecordAdded(address indexed user, RecordType recordType, uint index);
    event RecordUpdated(address indexed user, RecordType recordType, uint index);
    event RecordRevoked(address indexed user, RecordType recordType, uint index);
    event RecordVerified(address indexed verifier, address indexed user, RecordType recordType, uint index, Status status);
    event RecordAccessRequested(address org, address indexed user, RecordType recordType);
    event RecordAccessGranted(address indexed user, address indexed org, RecordType recordType, uint[] indexes);
    event RecordAccessed(address indexed org, address indexed user, RecordType recordType, uint index, uint timestamp);

    // Modifiers
    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Not an admin");
        _;
    }

    modifier onlyRecordOwner(address user) {
        require(msg.sender == user, "Not record owner");
        _;
    }

    constructor(address[] memory initialAdmins) {
        for (uint256 i = 0; i < initialAdmins.length; i++) {
            admins.push(initialAdmins[i]);
            isAdmin[initialAdmins[i]] = true;
        }
    }

    // Admin functions to add verifiers
    function addGovVerifier(address verifier) public onlyAdmin { govVerifiers[verifier] = true; }
    function addHealthVerifier(address verifier) public onlyAdmin { healthVerifiers[verifier] = true; }
    function addSchoolVerifier(address verifier) public onlyAdmin { schoolVerifiers[verifier] = true; }
    function addCompanyVerifier(address verifier) public onlyAdmin { companyVerifiers[verifier] = true; }
    function addEmbassyVerifier(address verifier) public onlyAdmin { embassyVerifiers[verifier] = true; }

    // Admin management (add/remove admins)
    function addAdmin(address newAdmin) public onlyAdmin {
        admins.push(newAdmin);
        isAdmin[newAdmin] = true;
    }
    function removeAdmin(address adminToRemove) public onlyAdmin {
        isAdmin[adminToRemove] = false;
        // Optional: remove from admins array
    }

    // Add records (with meta, validity)
    function addIDRecord(
        string memory fullName,
        string memory dateOfBirth,
        string memory nationality,
        string memory address_,
        string memory placeOfBirth,
        string memory drivingLicenseURI,
        address verifier,
        uint256 expiresAt,
        string memory notes,
        string memory language
    ) public {
        idRecords[msg.sender].push(IDRecord({
            fullName: fullName,
            dateOfBirth: dateOfBirth,
            nationality: nationality,
            address_: address_,
            placeOfBirth: placeOfBirth,
            drivingLicenseURI: drivingLicenseURI,
            status: Status.Pending,
            verifier: verifier,
            validity: Validity(block.timestamp, expiresAt),
            meta: MetaData(notes, language)
        }));
        emit RecordAdded(msg.sender, RecordType.ID, idRecords[msg.sender].length - 1);
    }

    function addHealthRecord(
        string memory medicalRecordsURI,
        string memory allergies,
        string memory diseases,
        string memory previousSurgeries,
        string memory disabilities,
        address verifier,
        uint256 expiresAt,
        string memory notes,
        string memory language
    ) public {
        healthRecords[msg.sender].push(HealthRecord({
            medicalRecordsURI: medicalRecordsURI,
            allergies: allergies,
            diseases: diseases,
            previousSurgeries: previousSurgeries,
            disabilities: disabilities,
            status: Status.Pending,
            verifier: verifier,
            validity: Validity(block.timestamp, expiresAt),
            meta: MetaData(notes, language)
        }));
        emit RecordAdded(msg.sender, RecordType.Health, healthRecords[msg.sender].length - 1);
    }

    function addEducationRecord(
        string[] memory previousSchools,
        string[] memory degrees,
        string[] memory marks,
        string[] memory universitiesApplied,
        address verifier,
        uint256 expiresAt,
        string memory notes,
        string memory language
    ) public {
        educationRecords[msg.sender].push(EducationRecord({
            previousSchools: previousSchools,
            degrees: degrees,
            marks: marks,
            universitiesApplied: universitiesApplied,
            status: Status.Pending,
            verifier: verifier,
            validity: Validity(block.timestamp, expiresAt),
            meta: MetaData(notes, language)
        }));
        emit RecordAdded(msg.sender, RecordType.Education, educationRecords[msg.sender].length - 1);
    }

    function addCareerRecord(
        string[] memory previousJobs,
        string memory cvURI,
        string[] memory skills,
        string[] memory experiences,
        address verifier,
        uint256 expiresAt,
        string memory notes,
        string memory language
    ) public {
        careerRecords[msg.sender].push(CareerRecord({
            previousJobs: previousJobs,
            cvURI: cvURI,
            skills: skills,
            experiences: experiences,
            status: Status.Pending,
            verifier: verifier,
            validity: Validity(block.timestamp, expiresAt),
            meta: MetaData(notes, language)
        }));
        emit RecordAdded(msg.sender, RecordType.Career, careerRecords[msg.sender].length - 1);
    }

    function addEmbassyRecord(
        string[] memory passportURIs,
        string memory bankStatementURI,
        string[] memory visasApplied,
        string memory proofOfAge,
        address verifier,
        uint256 expiresAt,
        string memory notes,
        string memory language
    ) public {
        embassyRecords[msg.sender].push(EmbassyRecord({
            passportURIs: passportURIs,
            bankStatementURI: bankStatementURI,
            visasApplied: visasApplied,
            proofOfAge: proofOfAge,
            status: Status.Pending,
            verifier: verifier,
            validity: Validity(block.timestamp, expiresAt),
            meta: MetaData(notes, language)
        }));
        emit RecordAdded(msg.sender, RecordType.Embassy, embassyRecords[msg.sender].length - 1);
    }

    // Update record (only owner, if not revoked)
    function updateIDRecord(uint index, string memory fullName, string memory address_) public onlyRecordOwner(msg.sender) {
        IDRecord storage rec = idRecords[msg.sender][index];
        require(rec.status != Status.Revoked, "Record is revoked");
        rec.fullName = fullName;
        rec.address_ = address_;
        emit RecordUpdated(msg.sender, RecordType.ID, index);
    }
    // Add similar update functions for other record types as needed...

    // Revoke record (only owner)
    function revokeIDRecord(uint index) public onlyRecordOwner(msg.sender) {
        IDRecord storage rec = idRecords[msg.sender][index];
        rec.status = Status.Revoked;
        emit RecordRevoked(msg.sender, RecordType.ID, index);
    }
    // Add similar revoke functions for other record types...

    // Verification functions
    function verifyIDRecord(address user, uint index, bool isVerified) public {
        IDRecord storage rec = idRecords[user][index];
        require(rec.status == Status.Pending, "Already processed");
        require(govVerifiers[msg.sender], "Not authorized gov verifier");
        require(rec.verifier == msg.sender, "Not assigned verifier");
        rec.status = isVerified ? Status.Verified : Status.Rejected;
        emit RecordVerified(msg.sender, user, RecordType.ID, index, rec.status);
    }
    function verifyHealthRecord(address user, uint index, bool isVerified) public {
        HealthRecord storage rec = healthRecords[user][index];
        require(rec.status == Status.Pending, "Already processed");
        require(healthVerifiers[msg.sender], "Not authorized health verifier");
        require(rec.verifier == msg.sender, "Not assigned verifier");
        rec.status = isVerified ? Status.Verified : Status.Rejected;
        emit RecordVerified(msg.sender, user, RecordType.Health, index, rec.status);
    }
    function verifyEducationRecord(address user, uint index, bool isVerified) public {
        EducationRecord storage rec = educationRecords[user][index];
        require(rec.status == Status.Pending, "Already processed");
        require(schoolVerifiers[msg.sender], "Not authorized school verifier");
        require(rec.verifier == msg.sender, "Not assigned verifier");
        rec.status = isVerified ? Status.Verified : Status.Rejected;
        emit RecordVerified(msg.sender, user, RecordType.Education, index, rec.status);
    }
    function verifyCareerRecord(address user, uint index, bool isVerified) public {
        CareerRecord storage rec = careerRecords[user][index];
        require(rec.status == Status.Pending, "Already processed");
        require(companyVerifiers[msg.sender], "Not authorized company verifier");
        require(rec.verifier == msg.sender, "Not assigned verifier");
        rec.status = isVerified ? Status.Verified : Status.Rejected;
        emit RecordVerified(msg.sender, user, RecordType.Career, index, rec.status);
    }
    function verifyEmbassyRecord(address user, uint index, bool isVerified) public {
        EmbassyRecord storage rec = embassyRecords[user][index];
        require(rec.status == Status.Pending, "Already processed");
        require(embassyVerifiers[msg.sender], "Not authorized embassy verifier");
        require(rec.verifier == msg.sender, "Not assigned verifier");
        rec.status = isVerified ? Status.Verified : Status.Rejected;
        emit RecordVerified(msg.sender, user, RecordType.Embassy, index, rec.status);
    }

    // Selective sharing
    function requestAccess(address user, RecordType rtype) public {
        emit RecordAccessRequested(msg.sender, user, rtype);
    }

    function grantAccess(address org, RecordType rtype, uint[] memory indexes) public {
        sharedRecords[msg.sender][org][rtype] = indexes;
        emit RecordAccessGranted(msg.sender, org, rtype, indexes);
    }

    // Audit trail: log each access
    function accessRecord(address user, RecordType rtype, uint index) public {
        // Check permission
        bool allowed = false;
        uint[] memory allowedIndexes = sharedRecords[user][msg.sender][rtype];
        for (uint i = 0; i < allowedIndexes.length; i++) {
            if (allowedIndexes[i] == index) {
                allowed = true;
                break;
            }
        }
        require(allowed, "Not allowed to access this record");
        emit RecordAccessed(msg.sender, user, rtype, index, block.timestamp);
        // Actual data retrieval is off-chain, using provided index
    }

    // View functions
    function getIDRecords(address user) public view returns (IDRecord[] memory) {
        return idRecords[user];
    }
    function getHealthRecords(address user) public view returns (HealthRecord[] memory) {
        return healthRecords[user];
    }
    function getEducationRecords(address user) public view returns (EducationRecord[] memory) {
        return educationRecords[user];
    }
    function getCareerRecords(address user) public view returns (CareerRecord[] memory) {
        return careerRecords[user];
    }
    function getEmbassyRecords(address user) public view returns (EmbassyRecord[] memory) {
        return embassyRecords[user];
    }
}
