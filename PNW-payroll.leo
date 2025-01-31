program pnw_payroll.aleo;

use std::crypto::pedersen_commit;
use std::collections::map;

// **🔹 Worker Payroll Structure**
struct Worker {
    worker_id: u32,
    employer: address,
    salary: u64,
    preferred_currency: field,  // "aleo_usdc" or "bridged_usdc"
    last_paid: u64,
    subdao_id: u32,
    is_active: bool,
    zpass_proof: option<field>, // Optional ZPass verification
    unpaid_wages: u64,
}

// **🔹 Treasury Structure**
struct Treasury {
    subdao_funds: map<u32, u64>,
}

// **🔹 Declare Mappings**
mapping workers: map<address, Worker>;
mapping treasury: Treasury;

// **🔹 Register Worker with Payroll Preference**
transition register_worker(worker_address: address, employer: address, salary: u64, preferred_currency: field, subdao_id: u32, zpass_proof: option<field>) -> bool {
    let worker_id = pedersen_commit(worker_address, salary);

    let worker = Worker {
        worker_id,
        employer,
        salary,
        preferred_currency,
        last_paid: 0,
        subdao_id,
        is_active: true,
        zpass_proof,
        unpaid_wages: 0,
    };

    workers[worker_address] = worker;
    return true;
}

// **🔹 Process Payroll (Supports Aleo USDC & Bridged USDC)**
transition process_payroll(worker_address: address, employer: address, provided_zpass: option<field>) -> bool {
    let worker = workers[worker_address];
    assert(worker.is_active, "Worker is not active");
    assert(worker.employer == employer, "Unauthorized employer");

    if worker.zpass_proof.is_some() {
        assert(provided_zpass.is_some(), "ZPass required for this worker");
        assert(verify_zpass(provided_zpass.unwrap()), "Invalid ZPass Proof");
    }

    let tax = if worker.zpass_proof.is_some() { worker.salary * 1 / 100 } else { worker.salary * 2 / 100 }; // 1% tax for ZPass, 2% otherwise
    let net_salary = worker.salary - tax;

    if worker.preferred_currency == "aleo_usdc" {
        transfer_aleo_usdc(worker_address, net_salary);
    } else {
        transfer_bridged_usdc(worker_address, net_salary);
    }

    treasury.subdao_funds[worker.subdao_id] += tax;
    workers[worker_address].last_paid = get_current_time();

    if worker.zpass_proof.is_some() {
        workers[worker_address].unpaid_wages += net_salary;
    }

    return true;
}

// **🔹 Switch Payroll Currency Anytime**
transition switch_payroll_currency(worker_address: address, new_currency: field) -> bool {
    let worker = workers[worker_address];
    assert(worker.is_active, "Worker is not active");
    assert(new_currency == "aleo_usdc" || new_currency == "bridged_usdc", "Invalid currency choice");

    worker.preferred_currency = new_currency;
    workers[worker_address] = worker;
    return true;
}

// **🔹 Apply Trust Fund APY (ZPass Users Get +0.5%)**
transition apply_trust_fund_apy(worker_address: address) -> bool {
    let worker = workers[worker_address];
    assert(worker.is_active, "Worker is not active");

    let apy_boost = if worker.zpass_proof.is_some() { worker.unpaid_wages * 5 / 1000 } else { 0 }; // +0.5% APY boost for ZPass
    treasury.subdao_funds[worker.subdao_id] += apy_boost;

    return true;
}

// **🔹 Function to Transfer Aleo USDC (Placeholder)**
function transfer_aleo_usdc(worker_address: address, amount: u64) -> bool {
    // Implementation for Aleo USDC transfer
    return true;
}

// **🔹 Function to Transfer Bridged USDC (Placeholder)**
function transfer_bridged_usdc(worker_address: address, amount: u64) -> bool {
    // Implementation for Bridged USDC transfer
    return true;
}

// **🔹 Verify ZPass Proof (Mock Function)**
function verify_zpass(zpass_proof: field) -> bool {
    return pedersen_commit(zpass_proof, 12345) == pedersen_commit(12345, zpass_proof); // Placeholder for real ZPass validation
}
