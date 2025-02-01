program employer_subdao_agreement {

    mapping employer_prepaid_wages: mapping<address, u64>; // Employer -> Prepaid Wages
    mapping employer_prepaid_taxes: mapping<address, u64>; // Employer -> Prepaid Taxes
    mapping blacklisted_employers: mapping<address, bool>; // Employer -> Blacklist Status

    const SUBDAO_TAX_PERCENT: u64 = 2; // 2% tax

    // Employers must prepay wages & taxes before hiring
    function prepay_funds(employer: address, wage_amount: u64, tax_amount: u64) -> bool {
        if blacklisted_employers.get(employer).unwrap_or(false) {
            return false; // Blacklisted employers cannot top up
        }
        if wage_amount == 0 || tax_amount == 0 {
            return false; // Invalid amounts
        }

        employer_prepaid_wages.set(employer, employer_prepaid_wages.get(employer).unwrap_or(0) + wage_amount);
        employer_prepaid_taxes.set(employer, employer_prepaid_taxes.get(employer).unwrap_or(0) + tax_amount);

        return true;
    }

    // Check if employer can hire workers
    function can_hire_worker(employer: address, required_wages: u64) -> bool {
        let available_wages = employer_prepaid_wages.get(employer).unwrap_or(0);
        let available_taxes = employer_prepaid_taxes.get(employer).unwrap_or(0);

        return available_wages >= required_wages && available_taxes > 0;
    }

    // Restrict hiring if funds are insufficient
    function enforce_top_up(employer: address, required_wages: u64) -> bool {
        if !can_hire_worker(employer, required_wages) {
            return false; // Employer must top up before hiring
        }
        return true;
    }

    // Blacklist employers who repeatedly fail to top up
    function blacklist_employer(employer: address) -> bool {
        blacklisted_employers.set(employer, true);
        return true;
    }

    // Remove employer from blacklist after penalty payment
    function reinstate_employer(employer: address, penalty_amount: u64) -> bool {
        if blacklisted_employers.get(employer).unwrap_or(false) && penalty_amount > 0 {
            employer_prepaid_taxes.set(employer, employer_prepaid_taxes.get(employer).unwrap_or(0) + penalty_amount);
            blacklisted_employers.set(employer, false);
            return true;
        }
        return false;
    }
}
