program pnw_smart_contract {

    // Mappings for worker & employer accounts
    mapping employer_prepaid_funds: mapping<address, u64>; // Employer -> Prepaid Payroll
    mapping employer_tax_funds: mapping<address, u64>; // Employer -> Prepaid Tax Funds
    mapping worker_balances: mapping<address, u64>; // Worker -> Account Balance
    mapping subdao_balances: mapping<u32, u64>; // SubDAO -> Available Funds
    mapping payroll_records: mapping<address, u64>; // Worker -> Last Payroll Amount
    const SUBDAO_TAX_PERCENT: u64 = 2; // 2% tax to SubDAO

    // Employers must prepay payroll & taxes separately
    function prepay_subdao(employer: address, subdao_id: u32, payroll_amount: u64, tax_amount: u64) -> bool {
        let current_funds = employer_prepaid_funds.get(employer).unwrap_or(0);
        employer_prepaid_funds.set(employer, current_funds + payroll_amount);

        let current_tax_funds = employer_tax_funds.get(employer).unwrap_or(0);
        employer_tax_funds.set(employer, current_tax_funds + tax_amount);

        // Add employer tax prepayment to SubDAO's balance for tax payments
        let subdao_funds = subdao_balances.get(subdao_id).unwrap_or(0);
        subdao_balances.set(subdao_id, subdao_funds + tax_amount);

        return true;
    }

    // Process payroll and ensure SubDAO pays employer taxes
    function process_payroll(employer: address, subdao_id: u32, worker: address, gross_salary: u64) -> u64 {
        let employer_tax = employer_tax_funds.get(employer).unwrap_or(0);
        let subdao_tax = (gross_salary * SUBDAO_TAX_PERCENT) / 100;
        let total_cost = gross_salary + employer_tax;

        let available_funds = employer_prepaid_funds.get(employer).unwrap_or(0);
        if available_funds < total_cost {
            return 0; // Insufficient funds
        }

        employer_prepaid_funds.set(employer, available_funds - gross_salary);
        employer_tax_funds.set(employer, employer_tax - employer_tax); // Deduct employer tax

        let net_salary = gross_salary - subdao_tax;
        worker_balances.set(worker, worker_balances.get(worker).unwrap_or(0) + net_salary);

        // SubDAO pays State/Country employer taxes from its allocated tax funds
        let subdao_funds = subdao_balances.get(subdao_id).unwrap_or(0);
        if subdao_funds >= employer_tax {
            subdao_balances.set(subdao_id, subdao_funds - employer_tax);
        }

        return net_salary;
    }

    // Get employer's prepaid payroll balance
    function get_employer_payroll_balance(employer: address) -> u64 {
        return employer_prepaid_funds.get(employer).unwrap_or(0);
    }

    // Get employer's tax fund balance
    function get_employer_tax_balance(employer: address) -> u64 {
        return employer_tax_funds.get(employer).unwrap_or(0);
    }

    // Get SubDAO's available balance for tax payments
    function get_subdao_balance(subdao_id: u32) -> u64 {
        return subdao_balances.get(subdao_id).unwrap_or(0);
    }
}
