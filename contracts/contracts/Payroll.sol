//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import "./models/Company.sol";
import "./models/Worker.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Payroll {
    address owner;
    mapping(uint256 => Company) companies;
    uint256 totalCompanies = 0;
    AggregatorV3Interface internal usdPriceFeed;
    event Paid(
        uint256 id,
        uint256 company,
        uint256 totalSalary,
        uint256 timestamp
    );

    modifier ownerOnly(uint256 company) {
        require(msg.sender == companies[company].owner, "Owner reserved only");
        _;
    }
    /**
     * Network: Goerli
     * Aggregator: ETH/USD
     * Address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
     */
    constructor() {
        owner = msg.sender;
        usdPriceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    }

    function addWorker(uint256 company, address worker, uint256 salary, string memory name, string memory dni)
        external
        ownerOnly(company)
        returns (bool)
    {
        require(salary > 0 ether, "Salary cannot be zero!");
        for (uint256 i = 0; i < companies[company].totalWorkers; i++) {
            require(!(companies[company].workers[i].id == worker), "Record already existing!");
        }
        companies[company].totalWorkers++;
        companies[company].totalSalary += salary;
        companies[company].workers.push(Worker(worker, name, dni, salary));
        return true;
    }

    function addCompany(string memory name)
        external
        returns (uint256)
    {
        totalCompanies++;
        Company storage newcompany = companies[totalCompanies];
        newcompany.id = totalCompanies;
        newcompany.owner = msg.sender;
        newcompany.name = name;
        newcompany.balance = 0;
        newcompany.totalWorkers = 0;
        newcompany.totalSalary = 0;
        return totalCompanies;
    }

    function payWorkers(uint256 company) external payable ownerOnly(company) returns (bool) {
        require(msg.value >= companies[company].totalSalary, "Ethers too small");
        require(companies[company].totalSalary <= companies[company].balance, "Insufficient balance");

        for (uint256 i = 0; i < companies[company].totalWorkers; i++) {
            payTo(companies[company].workers[i].id, companies[company].workers[i].salary);
        }

        companies[company].balance -= companies[company].totalSalary;

        emit Paid(companies[company].totalSalary, companies[company].id, companies[company].totalSalary, block.timestamp);

        return true;
    }

    function fundCompanyAdress(uint256 company) external payable ownerOnly(company) returns (bool) {
        companies[company].balance += msg.value;
        return true;
    }

    function getWorkers(uint256 company) external view returns (Worker[] memory) {
        return companies[company].workers;
    }

    function payTo(address to, uint256 amount) internal returns (bool) {
        // ETH price
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = usdPriceFeed.latestRoundData();
        // Decimals
        int decimals = int(uint(usdPriceFeed.decimals()));
        uint amountWithDecimals = amount;
        for (uint8 i = 0; i < 18; i++) {
            amountWithDecimals = amountWithDecimals * 10;
        }
        uint priceWithDecimals = uint(price);
        int leftFor = 4 - decimals;
        uint left = uint((leftFor)*(-1));
        for (uint8 i = 0; i < left; i++) {
            priceWithDecimals = priceWithDecimals / 10;
        }
        uint decimalsAmount = amountWithDecimals / priceWithDecimals;
        uint weiAmount = decimalsAmount * 100;

        (bool success, ) = payable(to).call{value: weiAmount }("");
        require(success, "Payment failed");
        return true;
    }
}