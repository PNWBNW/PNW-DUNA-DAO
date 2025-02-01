program aleo_bridge.aleo;

mapping pending_transfers: mapping(address, u64); // Stores pending transfers

// Function to send funds to an EVM chain
function send_to_evm(worker: address, amount: u64) -> bool {
    ensure pending_transfers.get(worker) == 0, "Pending transfer exists";
    
    // Lock funds in Aleo bridge
    pending_transfers.set(worker, amount);

    // Emit event for off-chain relayer to detect
    emit TransferInitiated(worker, amount);

    return true;
}

// Function to confirm transfer completion (relayer triggers this)
function confirm_transfer(worker: address) -> bool {
    ensure pending_transfers.get(worker) > 0, "No pending transfer";
    
    // Release locked funds (acknowledging EVM received them)
    pending_transfers.set(worker, 0);

    return true;
}
