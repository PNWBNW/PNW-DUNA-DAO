program pnw_smart_contract {

    // Mappings for financial tracking
    mapping employer_prepaid_funds: mapping<address, u64>; // Employer -> Prepaid Payroll
    mapping employer_tax_funds: mapping<address, u64>; // Employer -> Prepaid Tax Funds
    mapping worker_balances: mapping<address, u64>; // Worker -> Account Balance
    mapping subdao_balances: mapping<u32, u64>; // SubDAO -> Available Funds
    mapping tax_compliance_records: mapping<address, bool>; // Employer -> Tax Paid Status
    mapping employer_penalties: mapping<address, u64>; // Employer -> Total Penalties
    mapping employer_blacklist: mapping<address, bool>; // Employer -> Blacklisted Status
    mapping employer_tax_history: mapping<address, Vec<(u64, bool)>>; // Employer -> [(Timestamp, Paid?)]
    mapping subdao_alerts: mapping<u32, Vec<address>>; // SubDAO -> List of Employers with Missed Payments
    mapping subdao_proposals: mapping<u32, Vec<(String, u64, bool)>>; // SubDAO -> [(Proposal Description, Requested Funds, Approved?)]
    
    const SUBDAO_TAX_PERCENT: u64 = 2; // 2% tax to SubDAO
    const BLACKLIST_THRESHOLD: u64 = 3; // Blacklist after 3 missed tax payments

    // Employers must prepay payroll & taxes separately
    function prepay_subdao(employer: address, subdao_id: u32, payroll_amount: u64, tax_amount: u64) -> bool {
        if employer_blacklist.get(employer).unwrap_or(false) {
            return false; // Blacklisted employers cannot prepay wages
        }

        employer_prepaid_funds.set(employer, employer_prepaid_funds.get(employer).unwrap_or(0) + payroll_amount);
        employer_tax_funds.set(employer, employer_tax_funds.get(employer).unwrap_or(0) + tax_amount);
        subdao_balances.set(subdao_id, subdao_balances.get(subdao_id).unwrap_or(0) + tax_amount);

        return true;
    }

    // Ensure employer has enough prepaid funds before hiring workers
    function can_hire_worker(employer: address, required_funds: u64) -> bool {
        let available_funds = employer_prepaid_funds.get(employer).unwrap_or(0);
        let available_taxes = employer_tax_funds.get(employer).unwrap_or(0);

        return available_funds >= required_funds && available_taxes > 0;
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
            return 0; // Insufficient funds, employer must top up before hiring
        }

        employer_prepaid_funds.set(employer, available_funds - gross_salary);
        employer_tax_funds.set(employer, 0); // Deduct employer tax

        let net_salary = gross_salary - subdao_tax;
        worker_balances.set(worker, worker_balances.get(worker).unwrap_or(0) + net_salary);

        // SubDAO automatically pays employer taxes to the State/Country
        let subdao_funds = subdao_balances.get(subdao_id).unwrap_or(0);
        if subdao_funds >= employer_tax {
            subdao_balances.set(subdao_id, subdao_funds - employer_tax);
            tax_compliance_records.set(employer, true);
        } else {
            tax_compliance_records.set(employer, false);
            add_subdao_alert(subdao_id, employer);
        }

        // Store employer tax payment history
        let mut history = employer_tax_history.get(employer).unwrap_or(Vec::new());
        history.push((get_current_timestamp(), tax_compliance_records.get(employer).unwrap_or(false)));
        employer_tax_history.set(employer, history);

        return net_salary;
    }

    // Alert SubDAO if employer misses tax payment
    function add_subdao_alert(subdao_id: u32, employer: address) {
        let mut alerts = subdao_alerts.get(subdao_id).unwrap_or(Vec::new());
        if !alerts.contains(&employer) {
            alerts.push(employer);
            subdao_alerts.set(subdao_id, alerts);
        }
    }

    // Retrieve list of employers with missed tax payments
    function get_subdao_alerts(subdao_id: u32) -> Vec<address> {
        return subdao_alerts.get(subdao_id).unwrap_or(Vec::new());
    }

    // Workers propose and vote on SubDAO fund usage
    function propose_subdao_fund_usage(subdao_id: u32, description: String, requested_funds: u64) -> bool {
        let mut proposals = subdao_proposals.get(subdao_id).unwrap_or(Vec::new());
        proposals.push((description, requested_funds, false)); // Proposal starts as unapproved
        subdao_proposals.set(subdao_id, proposals);
        return true;
    }

    function vote_on_proposal(subdao_id: u32, proposal_index: u64, approve: bool) -> bool {
        let mut proposals = subdao_proposals.get(subdao_id).unwrap_or(Vec::new());
        if proposal_index >= proposals.len() as u64 {
            return false; // Invalid proposal index
        }

        let (description, requested_funds, _) = proposals[proposal_index as usize];
        if approve {
            let subdao_funds = subdao_balances.get(subdao_id).unwrap_or(0);
            if subdao_funds >= requested_funds {
                subdao_balances.set(subdao_id, subdao_funds - requested_funds);
                proposals[proposal_index as usize] = (description, requested_funds, true);
                subdao_proposals.set(subdao_id, proposals);
                return true;
            }
        }
        return false;
    }

    // Retrieve active proposals
    function get_subdao_proposals(subdao_id: u32) -> Vec<(String, u64, bool)> {
        return subdao_proposals.get(subdao_id).unwrap_or(Vec::new());
    }
}
