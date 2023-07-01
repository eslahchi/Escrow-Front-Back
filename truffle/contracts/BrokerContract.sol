// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

//import "hardhat/console.sol";


contract BrokerageContract {
    address public owner;
    address public seller;
    address public admin;

    address public sellerAddress;
    address public customerAddress;

    uint256 public totalAmount;
    string public title;

    IERC20 public token;

    constructor(uint _amount, string memory _title, address _token , address _admin, address _seller){
        owner = msg.sender;
        admin = _admin;
        //--- TODO : add my address
        seller = _seller;
        setToken(_token);
        totalAmount = _amount;
        title = _title;
        // setToken(0x573E48319C117712A4c60A94bfdAA9244b8a2384);
    }

    /* --- if later wanted to change --- */
    function adminSetTotalAmount(uint _amount) public onlyAdmin notLocked {
        totalAmount = _amount;
    }

    function setSeller(address _seller) public onlyOwner notLocked {
        sellerAddress = _seller;

    }
    /* --- if later wanted to change --- */
    function setAdmin(address _admin ) external notLocked onlyAdmin {
        // require(adminAddress == address(0), "admin already defined");
        admin = _admin;
    }

    /* --- when seller first runs --- */
    function setSellerAndAmount(uint _amount) external notLocked {
        require(sellerAddress == address(0), "seller already defined");
        sellerAddress = msg.sender;
        totalAmount = _amount;
    }

    /* --- when customer first signs --- */
    function setCustomerAndFreeze() public notLocked {
        // customerAddress = _customer;
        require(token.balanceOf(customerAddress) >= totalAmount, "not enough Token");
        customerAddress = msg.sender;
        freezeToken();
    }

    function setCustomer() external notLocked {
        require(msg.sender != sellerAddress, "you are seller");
        customerAddress = msg.sender;
    }
    function setCustomer2(address _customer) external notLocked {
        require(_customer != sellerAddress, "you are seller");
        customerAddress = _customer;
    }

    function adminSetCustomerAddress(address _customer) external onlyOwner notLocked {
        customerAddress = _customer;
    }

    /*--------< INIT >--------*/
    // TODO: Remove this part later
    // function init(address _tokenAddress) public {
    //    function init() public {
    //
    //    }
    /*<>----------------<>*/

    address tokenAddress;
    function setToken(address _tokenAddress) public onlyOwner notLocked {
        //--- USDT contract address on BSC = 0x69bab60997a2f5cbee668e5087dd9f91437206bb
        //--- USDT contract address on BSC = 0x55d398326f99059fF775485246999027B3197955
        token = IERC20(_tokenAddress);
        tokenAddress = _tokenAddress;
    }

    // function freezeToken() public onlycustomer {
    function freezeToken() public {
        require(token.balanceOf(customerAddress) >= totalAmount, "not enough Token");
        token.transferFrom(msg.sender, address(this), totalAmount);
        emit tokenFrozen(customerAddress, totalAmount, block.timestamp);
    }

    event tokenFrozen(address indexed _customer, uint _amount, uint indexed _date);

    /* --- when customer Approves --- */
    function customerApproves() onlyCustomer external {
        require(token.balanceOf(address(this)) >= 0, "No Token in Contract");
        unfreezeToken(true);
        emit customerApproved(msg.sender, block.timestamp);
    }

    event customerApproved(address indexed approver, uint indexed time);

    /* --- when customer Approves NOT --- */
    function customerApprovesNot() onlyCustomer external {
        require(token.balanceOf(address(this)) >= 0, "No Token in Contract");
        setEndDuration();
        emit customerDontApprove(msg.sender, block.timestamp);
        // unfreezeToken(false);
    }
    event customerDontApprove(address indexed approver, uint indexed time);

    /* --- After customer Approves Not, if want to withdraw --- */
    function customerWithdraw() external notLocked {
        unfreezeToken(false);
    }

    uint public adminShare;

    function setAdminShare(uint _share) external onlyAdmin{
        adminShare = _share;
    }

    function unfreezeToken(bool _isApproved) internal notLocked userNotLocked {
        require(token.balanceOf(address(this)) >= totalAmount, "not enough Token in contract");
        // require(); //--- check if customer has enough BNB (gas fee)

        //--- seller (Deal is done)
        if (_isApproved){

            // uint _adminShare = totalAmount / 20;
            uint _adminShare = totalAmount / (100 / adminShare);

            emit dd("admin share", _adminShare, msg.sender);

            token.transfer(payable(admin), _adminShare);
            emit unfrozen("admin", _adminShare, block.timestamp);

            uint _sellerShare = totalAmount - _adminShare ;

            emit dd("_seller share", _sellerShare, msg.sender);

            // token.transfer(payable(sellerAddress), token.balanceOf(address(this)));
            token.transfer(payable(sellerAddress), _sellerShare);
            emit unfrozen("seller", _sellerShare, block.timestamp);
        }
        //--- customer (Deal is off)
        else {
            emit dd("block.timestamp", block.timestamp, msg.sender);
            emit dd("endDuration", endDuration, msg.sender);
            require(block.timestamp >= endDuration, "Time Locked. Have to wait");
            token.transfer(payable(customerAddress), totalAmount);
            emit unfrozen("customer", totalAmount, block.timestamp);
        }

    }

    function checkDuration() public view returns(uint) {
        // console.log(endDuration);
        return endDuration;
    }

    function timeNow() public view returns(uint) {
        return block.timestamp;
    }

    event dd(string str, uint num, address adr );

    event unfrozen(string indexed toWho, uint amount, uint time);

    event error(string indexed error, uint time);




    /*--------< Time Lock Part >--------*/
    uint public endDuration;
    uint public duration = 45 minutes;
    uint public duration2 = 90 days;

    function setDuration(uint _duration) public {
        duration = _duration;
    }

    function setDuration2(uint _duration) public {
        duration2 = _duration;
    }

    // function setEndDuration() internal {
    function setEndDuration() public {
        endDuration = duration + block.timestamp;
        // emit dd("end Duration", endDuration, msg.sender);
    }


    function test() public notTimeLocked view returns(uint) {
        // console.log(endDuration);
        // return block.timestamp - endDuration;
        return endDuration;
    }

    modifier notTimeLocked {
        require(block.timestamp >= endDuration, "Time Locked. Have to wait");
        // emit dd("notTimeLocked", block.timestamp, msg.sender);
        _;
    }
    /*<>----------------<>*/


    /*--------< This part is for panic times which we want to lock every important functionality >--------*/
    bool public locked = false;

    function lockContract() public onlyUsers {
        locked = true;
        emit contractLocked(msg.sender, block.timestamp);
    }
    event contractLocked(address indexed _byWho, uint indexed time);

    function unlockContract() public onlyOwner {
        locked = false;
        emit contractLocked(msg.sender, block.timestamp);
    }
    event contractUnLocked(address indexed _byWho, uint indexed time);

    modifier notLocked(){
        require(!locked, "contract is locked");
        _;
    }
    /*----------------<>*/

    /*--------< This part is for times that they have disagreements and need to go to Judge >--------*/
    bool public userLocked = false;

    function userLockContract() public onlyUsers {
        userLocked = true;
        emit userContractLocked(msg.sender, block.timestamp);
    }
    event userContractLocked(address indexed _byWho, uint indexed time);

    function userUnlockContract() public onlyOwner {
        userLocked = false;
        emit userContractUnLocked(msg.sender, block.timestamp);
    }
    event userContractUnLocked(address indexed _byWho, uint indexed time);

    modifier userNotLocked(){
        require(!userLocked, "contract is userLocked");
        _;
    }
    /*----------------<>*/


    receive() external payable {}


    modifier onlySeller(){
        require(msg.sender == sellerAddress || msg.sender == admin, "only seller");
        _;
    }

    modifier onlyCustomer(){
        require(msg.sender == customerAddress || msg.sender == admin, "only Seller");
        _;
    }

    modifier onlyAdmin(){
        require(msg.sender == admin, "only admin");
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == admin || msg.sender == owner, "only admins");
        _;
    }

    modifier onlyUsers(){
        require(msg.sender == sellerAddress || msg.sender == admin || msg.sender == customerAddress || msg.sender == owner, "only users");
        _;
    }


    /*--------< Extra maintenance functionalities >--------*/

    // function withrawOtherTokens(address _tokenAddress, address _receiver) external onlyAdmin {
    function withdrawOtherTokens(address _tokenAddress) external onlyOwner {
        IERC20 otherToken =  IERC20(_tokenAddress);
        require(otherToken.balanceOf(address(this)) > 0 , "this contract does not have this token");
        otherToken.transfer(admin, otherToken.balanceOf(address(this)));

    }


}

contract BrokerFactory {
    BrokerageContract[] public brokerContracts;
    address public admin;

    constructor(){
        admin = msg.sender;
    }

    function createContract (uint _amount, string memory _title, address _token ) external {
        BrokerageContract brokerContract = new BrokerageContract(_amount, _title, _token, admin, msg.sender);
        brokerContracts.push(brokerContract);
    }




    /* ---------------------------- */
    uint public endDuration;



    /* ---------------------------- */
}

// pragma solidity ^0.8.13;

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.0/contracts/token/ERC20/IERC20.sol
interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}
