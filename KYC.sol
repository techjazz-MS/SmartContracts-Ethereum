pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract KYC {
   
    /* ALL STRUCTS GO HERE */
   
    // Customer struct
    struct Customer {
        string username;    // unique
        string custData;
        bool kycStatus;
        uint downVotes;
        uint upVotes;
        address bankAddress;
    }
   
    // Bank struct
    struct Bank {
        string bankName;
        address ethAddress; // unique
        uint reports;
        uint kycCount;
        bool kycPermission;
        string regNumber;
    }
   
    // KYC Request struct
    struct KYCrequest {
        string username;    // unique
        address bankAddress;
        string custData;
    }
   
   
    /* ALL VARIABLES */
    // Number of banks in the network. Useful for calculating % Votes.
    uint8 public totalBanks = 0;
   
    // Owner of the contract
    address _admin;
   
    /* CONSTRUCTOR: The creator of the contract is the Admin */
    constructor() public {
        _admin = msg.sender;
    }
   
    /* ALL MAPPINGS GO HERE */
    // List of all cusotmers
    mapping(string => Customer) customers;
   
    // list of all bankAddress
    mapping(address => Bank) banks;
   
    // list of all KYC requests
    mapping(string => KYCrequest) kycRequests;
   
   
    /* ALL MODIFIERS GO HERE */
    // Validation to check if customer is a new one
    modifier isNewCustomer(string memory _username) {
        require(customers[_username].bankAddress == address(0), "Customer already exists!");
        _;
    }
   
    // Validation to check if customer is an existing one
    modifier isExistingCustomer(string memory _username) {
        require(customers[_username].bankAddress != address(0), "Customer does NOT exist!");
        _;
    }
   
    // Validation to check if bank has kycPermission
    modifier bankHasPermission() {
        require(banks[msg.sender].kycPermission == true, "Bank does not have permission to perform this action.");
        _;
    }
   
    // Validation to check if the request is new
    modifier isNewRequest(string memory _custName) {
        require(kycRequests[_custName].bankAddress == address(0),"KYC Request for this customer already exists.");
        _;
    }
   
    // Validation to check if the request is already exisitng for this customer
    modifier isExistingRequest(string memory _custName) {
        require(kycRequests[_custName].bankAddress != address(0),"KYC Request for this customer doesn't exists.");
        _;
    }
   
    // Validation to check if caller is Admin
    modifier isAdmin() {
        require(msg.sender == _admin, "Only Admin can perform these functions.");
        _;
    }
   
    // Validation to check if a bank already exists
    modifier bankExists(address _ethAddress) {
        require(banks[_ethAddress].ethAddress != address(0), "Bank does not exist!");
        _;
    }
   
    // Validation to check if a bank is new
    modifier bankAddressIsNew(address _ethAddress) {
        require(banks[_ethAddress].ethAddress == address(0), "Bank already exists!");
        _;
    }
   
   
    /* *****************************
    /* ALL BANK FUNCTIONS GO HERE **
    *******************************/
   
    // ALL Bank-Customer Functions
    // Add Customer
    function addCustomer(string calldata _username, string calldata _custData) external bankHasPermission isNewCustomer(_username) {
        customers[_username].username = _username;
        customers[_username].custData = _custData;
        customers[_username].bankAddress = msg.sender;
    }
   
    // Remove Customer
    function removeCustomer(string calldata _username) external bankHasPermission isExistingCustomer(_username) {
        require(customers[_username].bankAddress == msg.sender);
        delete customers[_username];
        delete kycRequests[_username];
    }
   
    // Modify Customer
    function modifyCustomer(string calldata _username, string calldata _custData) external bankHasPermission isExistingCustomer(_username) {
        customers[_username].custData = _custData;
        customers[_username].upVotes = 0;
        customers[_username].downVotes = 0;
        delete kycRequests[_username];
    }
   
    // View Customer
    function viewCustomer(string calldata _username) external view isExistingCustomer(_username) returns (string memory) {
        return customers[_username].custData;
    }
   
    // Get Customer kycStatus
    function getCustomerStatus(string calldata _username) external view isExistingCustomer(_username) returns (bool) {
        return customers[_username].kycStatus;
    }
   
   
    // ALL Bank-Votes Functions
    // Up Vote a Customer
    function upVoteCustomer(string calldata _username) external bankHasPermission isExistingCustomer(_username) {
        customers[_username].upVotes++;
        customers[_username].kycStatus = isKYCcompliant(customers[_username].upVotes, customers[_username].downVotes, totalBanks);
       
    }
   
    // Up Vote a Customer
    function downVoteCustomer(string calldata _username) external bankHasPermission isExistingCustomer(_username) {
        customers[_username].downVotes++;
        customers[_username].kycStatus = isKYCcompliant(customers[_username].upVotes, customers[_username].downVotes, totalBanks);
    }
   
    // ALL Bank-Bank Functions
    // Get reports against a bank
    function getBankReports(address _ethAddress) external view bankHasPermission bankExists(_ethAddress) returns (uint) {
        return banks[_ethAddress].reports;
    }
   
    // View Bank Details
    function viewBankDetails(address _ethAddress) external view bankHasPermission bankExists(_ethAddress) returns (Bank memory) {
        return banks[_ethAddress];
    }
   
   
    // ALL Bank-KYCRequests Functions
    // Add New KYC Request
    function addRequest(string calldata _custName, string calldata _custData) external bankHasPermission isNewRequest(_custName) {
        kycRequests[_custName].username = _custName;
        kycRequests[_custName].bankAddress = msg.sender;
        kycRequests[_custName].custData = _custData;
    }
   
    // Remove KYC Request
    function removeRequest(string calldata _custName) external bankHasPermission isExistingRequest(_custName) {
        delete kycRequests[_custName];
    }
   
    /* ****************************************
    /* ALL BANK AUXILLIARY FUNCTIONS GO HERE **
    *******************************************/
    // Is Customer KYC Compliant? We check this by measuring the upVotes, downVotes percentages
    function isKYCcompliant(uint _upVotes, uint _downVotes, uint _totalBanks) internal pure returns (bool) {
        if (_upVotes > _downVotes && _downVotes <= _totalBanks/3) {
            return true;
        } else {
            return false;
        }
    }
   
    /* ******************************
    /* ALL ADMIN FUNCTIONS GO HERE **
    ********************************/
   
    // Add a bank
    function addBank(string calldata _bankName, address _ethAddress, string calldata _regNumber) external isAdmin bankAddressIsNew(_ethAddress) {
        banks[_ethAddress].ethAddress = _ethAddress;
        banks[_ethAddress].bankName = _bankName;
        banks[_ethAddress].reports = 0;
        banks[_ethAddress].kycCount = 0;
        banks[_ethAddress].kycPermission = true;
        banks[_ethAddress].regNumber = _regNumber;
        totalBanks++;
    }
   
    // Modify Bank Permission
    function modifyBankPermission(address _ethAddress, bool _kycPermission) external isAdmin {
        banks[_ethAddress].kycPermission = _kycPermission;
    }
   
    // Remove a bank
    function removeBank(address _ethAddress) external isAdmin bankExists(_ethAddress) {
        delete banks[_ethAddress];
        totalBanks--;
    }
}
