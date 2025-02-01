// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IAleoVerifier {
    function verifyAleoTransaction(bytes calldata proof, address worker, uint256 amount) external returns (bool);
}

interface IGovTaxAPI {
    function verifyTaxCompliance(address employer) external view returns (bool);
    function calculateWithholdingTax(address worker, uint256 amount) external view returns (uint256);
}

contract PNWBridgePayroll {
    IERC20 public usdcToken;
    IAleoVerifier public aleoVerifier;
    IGovTaxAPI public govTaxAPI;
    
    address public owner;
    uint256 public rollupInterval = 30 minutes;
    uint256 public lastRollupTime;
    uint256 public bridgingFee = 0.001 ether;

    struct PayrollBatch {
        address employer;
        address[] workers;
        uint256[] wages;
        bool processed;
    }

    mapping(uint256 => PayrollBatch) public payrollBatches;
    uint256 public nextBatchId;

    event PayrollReceived(uint256 indexed batchId, address indexed employer, uint256 totalAmount);
    event PayrollProcessed(uint256 indexed batchId);
    event WorkerBridged(address indexed worker, uint256 amount, bytes aleoProof);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor(address _usdcToken, address _aleoVerifier, address _govTaxAPI) {
        require(_usdcToken != address(0), "Invalid token address");
        require(_aleoVerifier != address(0), "Invalid Aleo verifier");
        require(_govTaxAPI != address(0), "Invalid tax API address");

        usdcToken = IERC20(_usdcToken);
        aleoVerifier = IAleoVerifier(_aleoVerifier);
        govTaxAPI = IGovTaxAPI(_govTaxAPI);
        owner = msg.sender;
        lastRollupTime = block.timestamp;
    }

    function depositPayroll(address[] calldata workers, uint256[] calldata wages) external {
        require(workers.length == wages.length, "Mismatched array lengths");
        require(workers.length > 0, "Empty batch");
        require(govTaxAPI.verifyTaxCompliance(msg.sender), "Employer tax non-compliant");

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < wages.length; i++) {
            totalAmount += wages[i];
        }

        require(usdcToken.transferFrom(msg.sender, address(this), totalAmount), "Transfer failed");

        payrollBatches[nextBatchId] = PayrollBatch({
            employer: msg.sender,
            workers: workers,
            wages: wages,
            processed: false
        });

        emit PayrollReceived(nextBatchId, msg.sender, totalAmount);
        nextBatchId++;
    }

    function processPayroll(uint256 batchId) public {
        require(batchId < nextBatchId, "Invalid batch ID");
        require(!payrollBatches[batchId].processed, "Batch already processed");

        PayrollBatch storage batch = payrollBatches[batchId];
        require(govTaxAPI.verifyTaxCompliance(batch.employer), "Employer tax non-compliant");

        for (uint256 i = 0; i < batch.workers.length; i++) {
            uint256 taxAmount = govTaxAPI.calculateWithholdingTax(batch.workers[i], batch.wages[i]);
            uint256 netPay = batch.wages[i] - taxAmount;
            
            require(usdcToken.transfer(batch.workers[i], netPay), "Net payment failed");
            require(usdcToken.transfer(address(govTaxAPI), taxAmount), "Tax payment failed");
        }

        batch.processed = true;
        emit PayrollProcessed(batchId);
    }

    function enableRollups() external onlyOwner {
        require(block.timestamp >= lastRollupTime + rollupInterval, "Rollup cooldown active");

        for (uint256 i = 0; i < nextBatchId; i++) {
            if (!payrollBatches[i].processed) {
                processPayroll(i);
            }
        }

        lastRollupTime = block.timestamp;
    }

    function setRollupInterval(uint256 interval) external onlyOwner {
        require(interval >= 10 minutes, "Interval too short");
        rollupInterval = interval;
    }

    function setBridgingFee(uint256 fee) external onlyOwner {
        bridgingFee = fee;
    }

    function bridgeToEVM(address worker, uint256 amount, bytes calldata aleoProof) external payable {
        require(msg.value >= bridgingFee, "Insufficient bridging fee");
        require(aleoVerifier.verifyAleoTransaction(aleoProof, worker, amount), "Aleo verification failed");
        
        uint256 taxAmount = govTaxAPI.calculateWithholdingTax(worker, amount);
        uint256 netAmount = amount - taxAmount;
        
        require(usdcToken.transfer(worker, netAmount), "Net transfer failed");
        require(usdcToken.transfer(address(govTaxAPI), taxAmount), "Tax transfer failed");

        emit WorkerBridged(worker, netAmount, aleoProof);
    }
}
