// SPDX-License-Identifier: Proprietary
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PNWPayroll {
    address public oversightDAO;
    IERC20 public usdcToken;

    struct Worker {
        address workerAddress;
        address employer;
        uint256 salary;
        uint256 lastPaid;
        uint256 subdaoId;
        bool isActive;
    }

    mapping(address => Worker) public workers;
    mapping(uint256 => uint256) public subdaoTreasury; // Tracks SubDAO tax allocation

    event SalaryPaid(address indexed worker, uint256 amount, uint256 tax, uint256 timestamp);
    event EmployerFunded(address indexed employer, uint256 amount);
    
    modifier onlyActiveWorker() {
        require(workers[msg.sender].isActive, "Not an active worker");
        _;
    }

    constructor(address _usdcToken, address _oversightDAO) {
        usdcToken = IERC20(_usdcToken);
        oversightDAO = _oversightDAO;
    }

    // **🔹 Employer Funds Payroll (Pre-Funding System)**
    function fundPayroll(uint256 amount) external {
        require(usdcToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        emit EmployerFunded(msg.sender, amount);
    }

    // **🔹 Employer & SubDAO Agree on Worker Salary**
    function registerWorker(
        address workerAddress,
        uint256 salary,
        uint256 subdaoId
    ) external {
        require(workers[workerAddress].workerAddress == address(0), "Worker already registered");

        workers[workerAddress] = Worker({
            workerAddress: workerAddress,
            employer: msg.sender,
            salary: salary,
            lastPaid: block.timestamp,
            subdaoId: subdaoId,
            isActive: true
        });
    }

    // **🔹 Payroll Processing (Pays Worker & Allocates SubDAO Tax)**
    function processPayroll(address workerAddress) external {
        Worker storage worker = workers[workerAddress];
        require(worker.isActive, "Worker not active");
        require(worker.employer == msg.sender, "Unauthorized employer");

        uint256 salary = worker.salary;
        uint256 tax = (salary * 2) / 100; // 2% goes to SubDAO
        uint256 netSalary = salary - tax;

        require(usdcToken.transfer(worker.workerAddress, netSalary), "Salary transfer failed");
        require(usdcToken.transfer(oversightDAO, tax), "Tax transfer failed");

        subdaoTreasury[worker.subdaoId] += tax;
        worker.lastPaid = block.timestamp;

        emit SalaryPaid(worker.workerAddress, netSalary, tax, block.timestamp);
    }

    // **🔹 Workers Withdraw SubDAO Treasury Funds (After Voting)**
    function withdrawSubdaoFunds(uint256 subdaoId, address recipient, uint256 amount) external {
        require(subdaoTreasury[subdaoId] >= amount, "Insufficient funds");
        require(msg.sender == oversightDAO, "Only OversightDAO can withdraw");

        subdaoTreasury[subdaoId] -= amount;
        require(usdcToken.transfer(recipient, amount), "Transfer failed");
    }
}
