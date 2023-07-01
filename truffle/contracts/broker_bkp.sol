// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

//import "hardhat/console.sol";


contract BrokerageContract {
    address public owner;
    address public admin;
    address public superAdmin;

    address public adminAddress;
    address public payerAddress;

    uint256 public totalAmount;
    string public title;

    IERC20 public token;

    constructor(uint _amount, string memory _title, address _token , address _superAdmin, address _admin){
        owner = msg.sender;
        superAdmin = _superAdmin;
        //--- TODO : add my address
        admin = _admin;
        setToken(_token);
        totalAmount = _amount;
        title = _title;
        // setToken(0x573E48319C117712A4c60A94bfdAA9244b8a2384);
    }

    /* --- if later wanted to change --- */
    function adminSetTotalAmount(uint _amount) public onlyAdmin notLocked {
        totalAmount = _amount;
    }

    function setAdmin(address _admin) public onlyOwner notLocked {
        adminAddress = _admin;

    }
    /* --- if later wanted to change --- */
    function setSuperAdmin(address _superAdmin ) external notLocked onlySuperAdmin {
        // require(adminAddress == address(0), "admin already defined");
        superAdmin = _superAdmin;
    }

    /* --- when admin first runs --- */
    function setAdminAndAmount(uint _amount) external notLocked {
        require(adminAddress == address(0), "admin already defined");
        adminAddress = msg.sender;
        totalAmount = _amount;
    }

    /* --- when Payer first signs --- */
    function setPayerAndFreeze() public notLocked {
        // payerAddress = _payer;
        require(token.balanceOf(payerAddress) >= totalAmount, "not enough Token");
        payerAddress = msg.sender;
        freezeToken();
    }

    function setPayer() external notLocked {
        require(msg.sender != adminAddress, "you are admin");
        payerAddress = msg.sender;
    }
    function setPayer2(address _payer) external notLocked {
        require(_payer != adminAddress, "you are admin");
        payerAddress = _payer;
    }

    function superAdminSetPayerAddress(address _payer) external onlyOwner notLocked {
        payerAddress = _payer;
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

    // function freezeToken() public onlyPayer {
    function freezeToken() public {
        require(token.balanceOf(payerAddress) >= totalAmount, "not enough Token");
        token.transferFrom(msg.sender, address(this), totalAmount);
        emit tokenFrozen(payerAddress, totalAmount, block.timestamp);
    }

    event tokenFrozen(address indexed _payer, uint _amount, uint indexed _date);

    /* --- when Payer Approves --- */
    function payerApproves() onlyPayer external {
        require(token.balanceOf(address(this)) >= 0, "No Token in Contract");
        unfreezeToken(true);
        emit payerApproved(msg.sender, block.timestamp);
    }

    event payerApproved(address indexed approver, uint indexed time);

    /* --- when Payer Approves NOT --- */
    function payerApprovesNot() onlyPayer external {
        require(token.balanceOf(address(this)) >= 0, "No Token in Contract");
        setEndDuration();
        emit payerDontApprove(msg.sender, block.timestamp);
        // unfreezeToken(false);
    }
    event payerDontApprove(address indexed approver, uint indexed time);

    /* --- After Payer Approves Not, if want to withdraw --- */
    function payerWithdraw() external notLocked {
        unfreezeToken(false);
    }

    function unfreezeToken(bool _isApproved) internal notLocked userNotLocked {
        require(token.balanceOf(address(this)) >= totalAmount, "not enough Token in contract");
        // require(); //--- check if payer has enough BNB (gas fee)

        //--- admin (Deal is done)
        if (_isApproved){
            // uint _adminShare = totalAmount * 0.05;
            uint _superAdminShare = totalAmount / 20;

            emit dd("superAdmin share", _superAdminShare, msg.sender);

            token.transfer(payable(superAdmin), _superAdminShare);
            emit unfrozen("superAdmin", _superAdminShare, block.timestamp);

            uint _adminShare = totalAmount - _superAdminShare ;

            emit dd("_admin share", _adminShare, msg.sender);

            // token.transfer(payable(adminAddress), token.balanceOf(address(this)));
            token.transfer(payable(adminAddress), _adminShare);
            emit unfrozen("admin", _adminShare, block.timestamp);
        }
        //--- Payer (Deal is off)
        else {
            emit dd("block.timestamp", block.timestamp, msg.sender);
            emit dd("endDuration", endDuration, msg.sender);
            require(block.timestamp >= endDuration, "Time Locked. Have to wait");
            token.transfer(payable(payerAddress), totalAmount);
            emit unfrozen("payer", totalAmount, block.timestamp);
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
    uint public duration = 1 minutes;

    function setDuration(uint _duration) public {
        duration = _duration;
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


    modifier onlyAdmin(){
        require(msg.sender == adminAddress || msg.sender == superAdmin, "only admin");
        _;
    }

    modifier onlyPayer(){
        require(msg.sender == payerAddress || msg.sender == superAdmin, "only Seller");
        _;
    }

    modifier onlySuperAdmin(){
        require(msg.sender == superAdmin, "only superAdmin");
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == superAdmin || msg.sender == owner, "only superAdmins");
        _;
    }

    modifier onlyUsers(){
        require(msg.sender == adminAddress || msg.sender == superAdmin || msg.sender == payerAddress || msg.sender == owner, "only users");
        _;
    }


    /*--------< Extra maintenance functionalities >--------*/

    // function withrawOtherTokens(address _tokenAddress, address _receiver) external onlysuperAdmin {
    function withrawOtherTokens(address _tokenAddress) external onlyOwner {
        IERC20 otherToken =  IERC20(_tokenAddress);
        require(otherToken.balanceOf(address(this)) > 0 , "this contract does not have this token");
        otherToken.transfer(superAdmin, otherToken.balanceOf(address(this)));

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
