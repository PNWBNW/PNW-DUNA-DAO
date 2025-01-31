// SPDX-License-Identifier: Proprietary
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PNWPayroll {
    address public oversightDAO;
    IERC20 public aleoUSDC; // Native Aleo USDC
    IERC20 public bridgedUSDC; // Bridged USDC

    struct Worker {
        address workerAddress;
        address employer;
        uint256 salary;
        uint256 lastPaid;
        uint256 subdaoId;
        bytes32 zpassHash;  // Optional ZPass proof (0x0 if not using ZPass)
        uint256 unpaidWages;
        bool isActive;
        bool prefersAleoUSDC; // True = Aleo USDC, False = Bridged USDC
    }

    mapping(address => Worker) public workers;
    mapping(uint256 => uint256) public subdaoTreasury; // Tracks SubDAO tax allocation

    event SalaryPaid(address indexed worker, uint256 amount, uint256 tax, uint256 timestamp);
    event PayrollPreferenceUpdated(address indexed worker, bool prefersAleoUSDC);

    constructor(address _aleoUSDC, address _bridgedUSDC, address _oversightDAO) {
        aleoUSDC = IERC20(_aleoUSDC);
        bridgedUSDC = IERC20(_bridgedUSDC);
        oversightDAO = _oversightDAO;
    }

    // **🔹 Register Worker with Payroll Preference**
    function registerWorker(
        address workerAddress,
        uint256 salary,
        uint256 subdaoId,
        bytes32 zpassHash,
        bool prefersAleoUSDC
    ) external {
        require(workers[workerAddress].workerAddress == address(0), "Worker already registered");

        workers[workerAddress] = Worker({
            workerAddress: workerAddress,
            employer: msg.sender,
            salary: salary,
            lastPaid: block.timestamp,
            subdaoId: subdaoId,
            zpassHash: zpassHash,
            unpaidWages: 0,
            isActive: true,
            prefersAleoUSDC: prefersAleoUSDC
        });
    }

    // **🔹 Process Payroll (All Workers Pay 2% Tax)**
    function processPayroll(address workerAddress, bytes32 providedZPass) external {
        Worker storage worker = workers[workerAddress];
        require(worker.isActive, "Worker not active");
        require(worker.employer == msg.sender, "Unauthorized employer");

        if (worker.zpassHash != 0x0) {
            require(providedZPass != 0x0, "ZPass required for this worker");
            require(worker.zpassHash == providedZPass, "Invalid ZPass Proof");
        }

        uint256 tax = (worker.salary * 2) / 100; // 2% tax for all workers
        uint256 netSalary = worker.salary - tax;

        if (worker.prefersAleoUSDC) {
            require(aleoUSDC.transfer(worker.workerAddress, netSalary), "Aleo USDC transfer failed");
        } else {
            require(bridgedUSDC.transfer(worker.workerAddress, netSalary), "Bridged USDC transfer failed");
        }

        require(aleoUSDC.transfer(oversightDAO, tax), "Tax transfer failed");
        subdaoTreasury[worker.subdaoId] += tax;
        worker.lastPaid = block.timestamp;

        if (worker.zpassHash != 0x0) {
            worker.unpaidWages += netSalary;
        }

        emit SalaryPaid(worker.workerAddress, netSalary, tax, block.timestamp);
    }
}
