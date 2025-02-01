// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

contract EVMBridge is AutomationCompatibleInterface {
    address public aleo_relayer;
    mapping(address => uint256) public workerBalances;
    mapping(address => bool) public useRollup;
    
    event PayrollReceived(address indexed worker, uint256 amount, bool useRollup);
    event RollupProcessed(address indexed worker, uint256 amount);

    address[] public rollupQueue;
    uint256 public lastRollupTime;
    uint256 public constant ROLLUP_INTERVAL = 30 minutes;

    constructor(address _aleo_relayer) {
        aleo_relayer = _aleo_relayer;
        lastRollupTime = block.timestamp;
    }

    function receivePayroll(address worker, uint256 amount, bool useRollupOption) external {
        require(msg.sender == aleo_relayer, "Unauthorized sender");
        workerBalances[worker] += amount;
        useRollup[worker] = useRollupOption;

        if (useRollupOption) {
            rollupQueue.push(worker);
        }

        emit PayrollReceived(worker, amount, useRollupOption);
    }

    function withdrawUSDC(address usdcContract) external {
        uint256 balance = workerBalances[msg.sender];
        require(balance > 0, "No funds available");

        if (useRollup[msg.sender]) {
            revert("Use rollup processing");
        } else {
            IERC20(usdcContract).transfer(msg.sender, balance);
            workerBalances[msg.sender] = 0;
        }
    }

    function processRollupWithdrawals(address usdcContract) internal {
        for (uint256 i = 0; i < rollupQueue.length; i++) {
            address worker = rollupQueue[i];
            uint256 amount = workerBalances[worker];

            if (amount > 0) {
                IERC20(usdcContract).transfer(worker, amount);
                workerBalances[worker] = 0;
                emit RollupProcessed(worker, amount);
            }
        }

        delete rollupQueue;
        lastRollupTime = block.timestamp;
    }

    /*** Chainlink Automation Functions ***/

    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory) {
        upkeepNeeded = (block.timestamp >= lastRollupTime + ROLLUP_INTERVAL) && (rollupQueue.length > 0);
    }

    function performUpkeep(bytes calldata) external override {
        require(block.timestamp >= lastRollupTime + ROLLUP_INTERVAL, "Rollup interval not reached");
        require(rollupQueue.length > 0, "No rollups to process");

        processRollupWithdrawals("USDC_CONTRACT_ADDRESS");
    }
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}
