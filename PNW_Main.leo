program pnw_smart_contract {

    mapping account_balances: mapping<address, u64>;
    mapping worker_visas: mapping<address, bool>; // Tracks active Worker Visas
    mapping subdao_membership: mapping<u32, u64>; // SubDAO ID -> Member Count
    const MAX_SUBDAOS: u32 = 50;
    const MIN_MEMBERS_FOR_NEW_SUBDAO: u64 = 100000;

    // Check if a worker has a valid visa
    function has_valid_visa(worker: address) -> bool {
        return worker_visas.get(worker).unwrap_or(false);
    }

    // Issue a new worker visa (No limit on total visas)
    function issue_worker_visa(worker: address) -> bool {
        if has_valid_visa(worker) {
            return false; // Worker already has a visa
        }
        worker_visas.set(worker, true);
        return true;
    }

    // Revoke an existing worker visa
    function revoke_worker_visa(worker: address) -> bool {
        if !has_valid_visa(worker) {
            return false; // No visa to revoke
        }
        worker_visas.remove(worker);
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
}
