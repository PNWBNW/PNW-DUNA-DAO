program pnw_employer_contract.aleo;

use std::crypto::pedersen_commit;
use std::collections::map;

struct EmployerContract {
    employer: address,
    subdao_id: u32,
    worker: address,
    gross_salary: u64,  // Includes payroll tax
    net_salary: u64,    // What the worker actually receives
    tax_amount: u64,    // 2% payroll tax
    is_active: bool,
}

mapping employer_contracts: map<address, EmployerContract>;

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

// **🔹 Verify Employer Contract Before Payroll Processing**
function verify_employer_contract(worker: address) -> EmployerContract {
    let contract = employer_contracts[worker];
    assert(contract.is_active, "Contract is not active");
    return contract;
}
