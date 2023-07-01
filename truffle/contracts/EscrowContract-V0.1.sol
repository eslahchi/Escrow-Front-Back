// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract EscrowContract is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant BUYER_ROLE = keccak256("BUYER_ROLE");
    bytes32 public constant SELLER_ROLE = keccak256("SELLER_ROLE");

    enum State {
        Unclaimed,
        Claimed,
        Approved,
        Disputed
    }

    IERC20 public token;
    address payable public buyer;
    address payable public seller;
    uint256 public claimPeriod;
    uint256 public approvalPeriod;
    uint256 public postTime;
    State public state;
    uint256 public balance;

    constructor(
        IERC20 _token,
        address payable _buyer,
        address payable _seller,
        address _admin,
        uint256 _claimPeriod,
        uint256 _approvalPeriod
    ) {
        require(_buyer != address(0) && _seller != address(0), "Buyer and seller addresses must be valid");
        require(_admin != address(0), "Admin address must be valid");

        token = _token;
        buyer = _buyer;
        seller = _seller;
        claimPeriod = _claimPeriod;
        approvalPeriod = _approvalPeriod;
        postTime = block.timestamp;
        state = State.Unclaimed;

        _setupRole(ADMIN_ROLE, _admin);
        _setupRole(BUYER_ROLE, _buyer);
        _setupRole(SELLER_ROLE, _seller);
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller must have admin role");
        _;
    }

    modifier onlyBuyer() {
        require(hasRole(BUYER_ROLE, msg.sender), "Caller must have buyer role");
        _;
    }

    modifier onlySeller() {
        require(hasRole(SELLER_ROLE, msg.sender), "Caller must have seller role");
        _;
    }

    modifier onlySellerOrBuyer() {
        require(hasRole(SELLER_ROLE, msg.sender) || hasRole(BUYER_ROLE, msg.sender), "Caller must have seller role");
        _;
    }

    modifier onlySellerOrBuyerOrAdmin() {
        require(hasRole(SELLER_ROLE, msg.sender) || hasRole(BUYER_ROLE, msg.sender) || hasRole(ADMIN_ROLE, msg.sender), "Caller must have user role");
        _;
    }

    function claim() public onlySeller {
        require(state == State.Unclaimed, "Goods have already been claimed");
        require(block.timestamp <= postTime + claimPeriod, "Claim period has ended");

        state = State.Claimed;
    }

    function approve() public onlyBuyer {
        require(state == State.Claimed, "Goods have not been claimed yet");
        require(block.timestamp <= postTime + claimPeriod + approvalPeriod, "Approval period has ended");

        state = State.Approved;
    }

    function dispute() public onlySellerOrBuyer {
        require(state == State.Claimed || state == State.Approved, "Transaction cannot be disputed");
        require(block.timestamp <= postTime + claimPeriod + approvalPeriod, "Dispute period has ended");

        state = State.Disputed;
    }

    function withdraw() public nonReentrant onlySellerOrBuyerOrAdmin {
        require(block.timestamp > postTime + claimPeriod + approvalPeriod, "Withdrawal not yet allowed");

        uint256 amount = token.balanceOf(address(this));
        require(amount > 0, "No tokens to withdraw");

        if (state == State.Approved) {
            token.safeTransfer(seller, amount);
        } else if (state == State.Disputed) {
            require(hasRole(ADMIN_ROLE, msg.sender), "Caller must have admin role");
            token.safeTransfer(buyer, amount);
        } else {
            token.safeTransfer(buyer, amount);
        }

        state = State.Unclaimed;
        balance = 0;
    }
}



------------------------------- Factory Contract -------------------------------

pragma solidity ^0.8.4;

import "./EscrowContract.sol";

contract EscrowContractFactory is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant BUYER_ROLE = keccak256("BUYER_ROLE");
    bytes32 public constant SELLER_ROLE = keccak256("SELLER_ROLE");

    event EscrowContractCreated(address indexed contractAddress);

    function createEscrowContract(
        IERC20 _token,
        address payable _buyer,
        address payable _seller,
        address _admin,
        uint256 _claimPeriod,
        uint256 _approvalPeriod
    ) public {
        EscrowContract escrowContract = new EscrowContract(
            _token,
            _buyer,
            _seller,
            _admin,
            _claimPeriod,
            _approvalPeriod
        );

        escrowContract.grantRole(ADMIN_ROLE, _admin);
        escrowContract.grantRole(BUYER_ROLE, _buyer);
        escrowContract.grantRole(SELLER_ROLE, _seller);

        emit EscrowContractCreated(address(escrowContract));
    }
}
