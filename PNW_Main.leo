program pnw_main.aleo;

// Import cryptographic tools
use std::crypto::pedersen_commit;
use std::collections::map;

// **🔹 Worker Identity & NFT Storage**
struct WorkerNFT {
    worker_id: u32,
    owner: address,
    visa_status: field,  // Temporary, Permanent, etc.
    visa_expiry: u64,  // Expiration timestamp
    trust_fund_balance: u64,
    total_earnings: u64,
    subdao_id: u32,
}

// **🔹 Treasury Structure for SubDAOs**
struct Treasury {
    subdao_funds: map<u32, u64>, // Maps SubDAO ID to available funds
}

// **🔹 Employer Contract (Wage Agreements)**
struct EmployerContract {
    employer: address,
    worker: address,
    agreed_salary: u64,
    is_active: bool,
}

// **🔹 Government API Request Structure**
struct GovernmentAPIRequest {
    government_id: field,
    worker_id: u32,
    request_type: field,  // "VisaCheck" or "WorkVerification"
}

// **🔹 Declare Mappings**
mapping treasury: Treasury;
mapping worker_nfts: map<address, WorkerNFT>;
mapping employer_contracts: map<address, EmployerContract>;
mapping government_requests: map<u32, GovernmentAPIRequest>;

// **🔹 Issue Worker NFT (Identity & Visa Tracking)**
transition issue_worker_nft(worker_address: address, visa_status: field, visa_expiry: u64, subdao_id: u32) -> bool {
    let worker_id = pedersen_commit(worker_address, visa_status);
    let nft = WorkerNFT { worker_id, owner: worker_address, visa_status, visa_expiry, trust_fund_balance: 0, total_earnings: 0, subdao_id };

    worker_nfts[worker_address] = nft;
    return true;
}

// **🔹 Employer & SubDAO Wage Agreement**
transition set_worker_salary(worker: address, employer: address, salary: u64) -> bool {
    let contract = EmployerContract { employer, worker, agreed_salary: salary, is_active: true };
    employer_contracts[worker] = contract;
    return true;
}

// **🔹 Process Payroll & SubDAO Fund Allocation**
transition process_payroll(worker: address, employer: address) -> bool {
    let contract = employer_contracts[worker];
    assert(contract.is_active, "Contract is not active");

    let nft = worker_nfts[worker];
    assert(nft.visa_expiry > get_current_time(), "Visa expired, payroll suspended");

    let salary = contract.agreed_salary;
    let tax = salary * 2 / 100;
    let net_salary = salary - tax;

    nft.total_earnings += net_salary;
    nft.trust_fund_balance += tax;

    worker_nfts[worker] = nft;
    treasury.subdao_funds[nft.subdao_id] += tax;

    return true;
}

// **🔹 SubDAO Voting on Treasury Fund Allocation**
transition vote_treasury_funds(subdao_id: u32, amount: u64) -> bool {
    assert(treasury.subdao_funds[subdao_id] >= amount, "Insufficient funds");

    treasury.subdao_funds[subdao_id] -= amount;
    return true;
}

// **🔹 Report Employer Violation (Worker Protections)**
transition report_employer_violation(worker: address, employer: address) -> bool {
    let contract = employer_contracts[worker];
    assert(contract.is_active, "Contract is not active");

    contract.is_active = false;
    employer_contracts[worker] = contract;
    return true;
}

// **🔹 Government API: Request Worker Verification**
transition request_worker_verification(government_id: field, worker_id: u32, request_type: field) -> bool {
    let request = GovernmentAPIRequest { government_id, worker_id, request_type };
    government_requests[worker_id] = request;
    return true;
}

// **🔹 Verify Worker NFT (For Governments & Employers)**
function verify_worker_nft(worker_id: u32) -> WorkerNFT {
    let nft = worker_nfts.iter().find(|(_, n)| n.worker_id == worker_id);
    assert(nft.is_some(), "Worker NFT not found");

    return nft.unwrap().1;
}
