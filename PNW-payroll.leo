program pnw_smart_contract {

    mapping account_balances: mapping<address, u64>; // Worker -> Account Balance
    mapping worker_visas: mapping<address, bool>; // Worker -> Visa Status
    mapping subdao_membership: mapping<u32, u64>; // SubDAO ID -> Member Count
    mapping payroll_taxes: mapping<address, u64>; // Worker -> State/Country Tax Amount
    const MAX_SUBDAOS: u32 = 50;
    const MIN_MEMBERS_FOR_NEW_SUBDAO: u64 = 100000;
    const SUBDAO_TAX_PERCENT: u64 = 2; // 2% tax to SubDAO

    // Check if a worker has a valid visa
    function has_valid_visa(worker: address) -> bool {
        return worker_visas.get(worker).unwrap_or(false);
    }

    // Issue a new worker visa (Unlimited Worker Visas)
    function issue_worker_visa(worker: address) -> bool {
        if has_valid_visa(worker) {
            return false; // Worker already has a visa
        }
        worker_visas.set(worker, true);
        return true;
    }

    // Get total number of members across all SubDAOs
    function get_total_members() -> u64 {
        let mut total: u64 = 0;
        for i in 0..MAX_SUBDAOS {
            total += subdao_membership.get(i).unwrap_or(0);
        }
        return total;
    }

    // Check if a new SubDAO can be created
    function can_create_subdao() -> bool {
        return get_total_members() >= MIN_MEMBERS_FOR_NEW_SUBDAO;
    }

    // Add a worker to a SubDAO
    function add_worker_to_subdao(subdao_id: u32, worker: address) -> bool {
        if subdao_id >= MAX_SUBDAOS {
            return false; // Invalid SubDAO ID
        }
        if !has_valid_visa(worker) {
            return false; // Worker must have a valid visa
        }
        let current_count = subdao_membership.get(subdao_id).unwrap_or(0);
        subdao_membership.set(subdao_id, current_count + 1);
        return true;
    }

    // Remove a worker from a SubDAO
    function remove_worker_from_subdao(subdao_id: u32, worker: address) -> bool {
        if subdao_id >= MAX_SUBDAOS {
            return false; // Invalid SubDAO ID
        }
        if !has_valid_visa(worker) {
            return false; // Worker must have a valid visa
        }
        let current_count = subdao_membership.get(subdao_id).unwrap_or(0);
        if current_count == 0 {
            return false; // No members to remove
        }
        subdao_membership.set(subdao_id, current_count - 1);
        return true;
    }

    // Set state/country tax for a worker
    function set_state_tax(worker: address, tax_amount: u64) -> bool {
        payroll_taxes.set(worker, tax_amount);
        return true;
    }

    // Process payroll with tax deductions
    function process_payroll(worker: address, gross_salary: u64) -> u64 {
        if !has_valid_visa(worker) {
            return 0; // Worker must have a valid visa
        }

        let subdao_tax = (gross_salary * SUBDAO_TAX_PERCENT) / 100; // Calculate 2% SubDAO tax
        let state_tax = payroll_taxes.get(worker).unwrap_or(0); // Get worker's state/country tax

        let total_deductions = subdao_tax + state_tax;
        let net_salary = if gross_salary > total_deductions { gross_salary - total_deductions } else { 0 };

        account_balances.set(worker, account_balances.get(worker).unwrap_or(0) + net_salary);

        return net_salary;
    }

    // Get worker’s account balance
    function get_balance(worker: address) -> u64 {
        return account_balances.get(worker).unwrap_or(0);
    }
}
