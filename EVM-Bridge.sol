// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract EVMBridge {
    address public aleo_relayer;
    mapping(address => uint256) public workerBalances;
    mapping(address => bool) public useRollup;

    event PayrollReceived(address indexed worker, uint256 amount, bool useRollup);

    constructor(address _aleo_relayer) {
        aleo_relayer = _aleo_relayer;
    }

    // Function to receive payroll with worker’s choice
    function receivePayroll(address worker, uint256 amount, bool useRollupOption) external {
        require(msg.sender == aleo_relayer, "Unauthorized sender");
        workerBalances[worker] += amount;
        useRollup[worker] = useRollupOption;

        emit PayrollReceived(worker, amount, useRollupOption);
    }

    // Worker withdraws USDC with their selected method
    function withdrawUSDC(address usdcContract) external {
        uint256 balance = workerBalances[msg.sender];
        require(balance > 0, "No funds available");

        if (useRollup[msg.sender]) {
            // Rollup processing (e.g., batch with other withdrawals)
            processRollupWithdrawal(msg.sender, balance, usdcContract);
        } else {
            // Direct transfer (higher fees, faster)
            IERC20(usdcContract).transfer(msg.sender, balance);
        }

        workerBalances[msg.sender] = 0;
    }

    function processRollupWithdrawal(address worker, uint256 amount, address usdcContract) internal {
        // Batch this worker’s request for later processing
        // Actual rollup logic is handled off-chain before finalizing on-chain
    }
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}
