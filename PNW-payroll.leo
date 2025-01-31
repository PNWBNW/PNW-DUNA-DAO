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
    unpaid_wages: u64,
    zpass_proof: option<field>, // Optional ZPass verification
}

// **🔹 Employer-SubDAO Salary Agreement**
struct EmployerContract {
    employer: address,
    subdao_id: u32,
    worker: address,
    gross_salary: u64,  // Includes payroll tax
    net_salary: u64,    // What the worker actually receives
    tax_amount: u64,    // 2% payroll tax
    is_active: bool,
}

// **🔹 Treasury Structure**
struct Treasury {
    subdao_funds: map<u32, u64>,
}

// **🔹 Declare Mappings**
mapping workers: map<address, Worker>;
mapping employer_contracts: map<address, EmployerContract>;
mapping treasury: Treasury;

// **🔹 Create Salary Agreement (Employer Must Cover Payroll Tax)**
transition create_salary_agreement(employer: address, worker: address, subdao_id: u32, gross_salary: u64) -> bool {
    let tax_amount = gross_salary * 2 / 100;
    let net_salary = gross_salary - tax_amount;

    let contract = EmployerContract {
        employer,
        subdao_id,
        worker,
        gross_salary,
        net_salary,
        tax_amount,
        is_active: true,
    };

    employer_contracts[worker] = contract;
    return true;
}

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
        unpaid_wages: 0,
        zpass_proof,
    };

    workers[worker_address] = worker;
    return true;
}

// **🔹 Verify Employer Contract Before Payroll Processing**
function verify_employer_contract(worker: address) -> EmployerContract {
    let contract = employer_contracts[worker];
    assert(contract.is_active, "Contract is not active");
    return contract;
}

// **🔹 Process Payroll (Employer Pays Salary + Tax)**
transition process_payroll(worker_address: address, employer: address, provided_zpass: option<field>) -> bool {
    let contract = verify_employer_contract(worker_address);
    assert(contract.employer == employer, "Unauthorized employer");

    let tax = contract.tax_amount;
    let net_salary = contract.net_salary;

    // **🔹 Gas Fee Handling**
    let gas_fee = calculate_gas_fee();
    if workers[worker_address].preferred_currency == "aleo_usdc" {
        treasury.subdao_funds[contract.subdao_id] -= gas_fee;  // SubDAO covers Aleo gas fees
    } else {
        assert(net_salary > gas_fee, "Worker must cover gas fees");
        net_salary -= gas_fee;  // Worker covers gas fees on sidechain
    }

    // **🔹 Payroll Transfer**
    if workers[worker_address].preferred_currency == "aleo_usdc" {
        transfer_aleo_usdc(worker_address, net_salary);
    } else {
        transfer_bridged_usdc(worker_address, net_salary);
    }

    treasury.subdao_funds[contract.subdao_id] += tax;
    workers[worker_address].last_paid = get_current_time();

    if workers[worker_address].zpass_proof.is_some() {
        workers[worker_address].unpaid_wages += net_salary;
    }

    return true;
}

// **🔹 Allow Workers to Switch Payroll Preference Anytime**
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

// **🔹 Calculate Gas Fee (Mock Function)**
function calculate_gas_fee() -> u64 {
    return 100;  // Placeholder gas fee amount
}
