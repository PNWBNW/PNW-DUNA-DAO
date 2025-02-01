program aleo_bridge.aleo;

mapping pending_transfers: mapping(address, (u64, bool)); // Stores amount and settlement type

// Function to send funds with worker’s choice
function send_to_evm(worker: address, amount: u64, use_rollup: bool) -> bool {
    ensure pending_transfers.get(worker) == (0, false), "Pending transfer exists";
    
    // Lock funds with worker's choice
    pending_transfers.set(worker, (amount, use_rollup));

    // Emit event for off-chain relayer
    emit TransferInitiated(worker, amount, use_rollup);

    return true;
}

// Function to confirm transfer completion
function confirm_transfer(worker: address) -> bool {
    ensure pending_transfers.get(worker).0 > 0, "No pending transfer";
    
    // Release locked funds
    pending_transfers.set(worker, (0, false));

    return true;
}
