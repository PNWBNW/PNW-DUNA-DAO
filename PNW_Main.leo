program pnw_smart_contract {

    // Mappings for financial tracking
    mapping employer_prepaid_funds: mapping<address, u64>; // Employer -> Prepaid Payroll
    mapping employer_tax_funds: mapping<address, u64>; // Employer -> Prepaid Tax Funds
    mapping worker_balances: mapping<address, u64>; // Worker -> Account Balance
    mapping subdao_balances: mapping<u32, u64>; // SubDAO -> Available Funds
    mapping tax_compliance_records: mapping<address, bool>; // Employer -> Tax Paid Status
    mapping employer_penalties: mapping<address, u64>; // Employer -> Total Penalties
    mapping employer_blacklist: mapping<address, bool>; // Employer -> Blacklisted Status
    mapping payroll_records: mapping<address, u64>; // Worker -> Last Payroll Amount
    const SUBDAO_TAX_PERCENT: u64 = 2; // 2% tax to SubDAO
    const PENALTY_TIER_1: u64 = 5; // 5% penalty for 1 missed tax payment
    const PENALTY_TIER_2: u64 = 10; // 10% penalty for 2 missed tax payments
    const PENALTY_TIER_3: u64 = 20; // 20% penalty for 3+ missed tax payments
    const BLACKLIST_THRESHOLD: u64 = 3; // Blacklist employers with 3+ missed payments

    // Employers must prepay payroll & taxes separately
    function prepay_subdao(employer: address, subdao_id: u32, payroll_amount: u64, tax_amount: u64) -> bool {
        if employer_blacklist.get(employer).unwrap_or(false) {
            return false; // Blacklisted employers cannot prepay wages
        }

        let current_funds = employer_prepaid_funds.get(employer).unwrap_or(0);
        employer_prepaid_funds.set(employer, current_funds + payroll_amount);

        let current_tax_funds = employer_tax_funds.get(employer).unwrap_or(0);
        employer_tax_funds.set(employer, current_tax_funds + tax_amount);

        // Add employer tax prepayment to SubDAO's balance for tax payments
        let subdao_funds = subdao_balances.get(subdao_id).unwrap_or(0);
        subdao_balances.set(subdao_id, subdao_funds + tax_amount);

        return true;
    }

    // Process payroll and automatically pay taxes
    function process_payroll(employer: address, subdao_id: u32, worker: address, gross_salary: u64) -> u64 {
        if employer_blacklist.get(employer).unwrap_or(false) {
            return 0; // Blacklisted employers cannot process payroll
        }

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

        // SubDAO automatically pays employer taxes to the State/Country
        let subdao_funds = subdao_balances.get(subdao_id).unwrap_or(0);
        if subdao_funds >= employer_tax {
            subdao_balances.set(subdao_id, subdao_funds - employer_tax);
            tax_compliance_records.set(employer, true); // Mark employer as tax compliant
        } else {
            tax_compliance_records.set(employer, false); // Mark employer as non-compliant
        }

        return net_salary;
    }

    // Verify if an employer has met tax compliance
    function check_tax_compliance(employer: address) -> bool {
        return tax_compliance_records.get(employer).unwrap_or(false);
    }

    // Apply penalty tiers and blacklist chronic offenders
    function apply_employer_penalty(employer: address, subdao_id: u32, missed_payments: u64) -> bool {
        if !check_tax_compliance(employer) {
            let penalty_percent = if missed_payments == 1 {
                PENALTY_TIER_1
            } else if missed_payments == 2 {
                PENALTY_TIER_2
            } else {
                PENALTY_TIER_3
            };

            let penalty_amount = (employer_prepaid_funds.get(employer).unwrap_or(0) * penalty_percent) / 100;
            let employer_funds = employer_prepaid_funds.get(employer).unwrap_or(0);
            
            if employer_funds >= penalty_amount {
                employer_prepaid_funds.set(employer, employer_funds - penalty_amount);
                let subdao_funds = subdao_balances.get(subdao_id).unwrap_or(0);
                subdao_balances.set(subdao_id, subdao_funds + penalty_amount); // Penalty goes to SubDAO
                
                let total_penalties = employer_penalties.get(employer).unwrap_or(0) + penalty_amount;
                employer_penalties.set(employer, total_penalties);

                // Blacklist employer if they have 3+ missed payments
                if missed_payments >= BLACKLIST_THRESHOLD {
                    employer_blacklist.set(employer, true);
                }

                return true;
            }
        }
        return false;
    }

    // Allow employers to request refund of overpaid taxes
    function request_tax_refund(employer: address, subdao_id: u32, refund_amount: u64) -> bool {
        if employer_blacklist.get(employer).unwrap_or(false) {
            return false; // Blacklisted employers cannot request refunds
        }

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

    // Get an employer's total penalties
    function get_employer_penalties(employer: address) -> u64 {
        return employer_penalties.get(employer).unwrap_or(0);
    }

    // Check if an employer is blacklisted
    function is_employer_blacklisted(employer: address) -> bool {
        return employer_blacklist.get(employer).unwrap_or(false);
    }
}
