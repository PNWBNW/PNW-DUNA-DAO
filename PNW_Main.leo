program pnw_smart_contract {

    // Mappings for financial tracking
    mapping employer_prepaid_funds: mapping<address, u64>; // Employer -> Prepaid Payroll
    mapping employer_tax_funds: mapping<address, u64>; // Employer -> Prepaid Tax Funds
    mapping worker_balances: mapping<address, u64>; // Worker -> Account Balance
    mapping subdao_balances: mapping<u32, u64>; // SubDAO -> Available Funds
    mapping tax_compliance_records: mapping<address, bool>; // Employer -> Tax Paid Status
    mapping payroll_records: mapping<address, u64>; // Worker -> Last Payroll Amount
    const SUBDAO_TAX_PERCENT: u64 = 2; // 2% tax to SubDAO
    const EMPLOYER_PENALTY_PERCENT: u64 = 5; // 5% penalty for unpaid taxes

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
        employer_tax_funds.set(employer, 0); // Deduct employer tax

        let net_salary = gross_salary - subdao_tax;
        worker_balances.set(worker, worker_balances.get(worker).unwrap_or(0) + net_salary);

        // SubDAO pays State/Country employer taxes from its allocated tax funds
        let subdao_funds = subdao_balances.get(subdao_id).unwrap_or(0);
        if subdao_funds >= employer_tax {
            subdao_balances.set(subdao_id, subdao_funds - employer_tax);
            tax_compliance_records.set(employer, true); // Mark employer as tax compliant
        } else {
            tax_compliance_records.set(employer, false); // Mark employer as non-compliant
        }

        return net_salary;
    }

    // Check if an employer has unpaid tax obligations
    function check_tax_compliance(employer: address) -> bool {
        return tax_compliance_records.get(employer).unwrap_or(false);
    }

    // Apply penalties to non-compliant employers
    function apply_employer_penalty(employer: address, subdao_id: u32) -> bool {
        if !check_tax_compliance(employer) {
            let penalty_amount = (employer_prepaid_funds.get(employer).unwrap_or(0) * EMPLOYER_PENALTY_PERCENT) / 100;
            let employer_funds = employer_prepaid_funds.get(employer).unwrap_or(0);
            
            if employer_funds >= penalty_amount {
                employer_prepaid_funds.set(employer, employer_funds - penalty_amount);

                let subdao_funds = subdao_balances.get(subdao_id).unwrap_or(0);
                subdao_balances.set(subdao_id, subdao_funds + penalty_amount); // Penalty goes to SubDAO

                return true;
            }
        }
        return false;
    }

    // Refund employer tax overpayments
    function refund_employer_tax(employer: address, subdao_id: u32, refund_amount: u64) -> bool {
        let subdao_funds = subdao_balances.get(subdao_id).unwrap_or(0);
        if subdao_funds >= refund_amount {
            subdao_balances.set(subdao_id, subdao_funds - refund_amount);

            let employer_tax_balance = employer_tax_funds.get(employer).unwrap_or(0);
            employer_tax_funds.set(employer, employer_tax_balance + refund_amount);

            return true;
        }
        return false;
    }

    // Get SubDAO's available balance for tax payments
    function get_subdao_balance(subdao_id: u32) -> u64 {
        return subdao_balances.get(subdao_id).unwrap_or(0);
    }
}
