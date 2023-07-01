// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract MultiEscrow {
    uint256 public constant dTime = 604800; // 1 week in seconds
    address public buyer;
    address public seller;
    uint256 public totalAmount;
    uint256 public numberOfPayments;
    uint256 public currentPayment;
    uint256 public fineAmount;
    uint256 public fineDeadline;
    uint256 public deadline;
    IERC20 public usdt;
    mapping(uint256 => bool) public paymentApproved;
    mapping(uint256 => bool) public paymentClaimed;
    mapping(uint256 => uint256) public paymentAmount;

    event PaymentClaimed(uint256 paymentIndex);
    event PaymentApproved(uint256 paymentIndex);

    constructor(
        address _buyer,
        address _seller,
        uint256 _totalAmount,
        uint256 _numberOfPayments,
        uint256 _fineAmount,
        uint256 _fineDeadline,
        uint256 _deadline,
        address _usdt
    ) {
        buyer = _buyer;
        seller = _seller;
        totalAmount = _totalAmount;
        numberOfPayments = _numberOfPayments;
        fineAmount = _fineAmount;
        fineDeadline = _fineDeadline;
        deadline = _deadline;
        usdt = IERC20(_usdt);
    }

    modifier onlyBuyer() {
        require(msg.sender == buyer, "MultiEscrow: caller is not the buyer");
        _;
    }

    modifier onlySeller() {
        require(msg.sender == seller, "MultiEscrow: caller is not the seller");
        _;
    }

    function claimPayment(uint256 paymentIndex) external onlySeller {
        require(paymentIndex == currentPayment, "MultiEscrow: invalid payment index");
        require(!paymentClaimed[paymentIndex], "MultiEscrow: payment already claimed");
        require(paymentApproved[paymentIndex], "MultiEscrow: payment not approved");
        require(usdt.balanceOf(address(this)) >= paymentAmount[paymentIndex], "MultiEscrow: insufficient balance");

        paymentClaimed[paymentIndex] = true;
        currentPayment++;

        emit PaymentClaimed(paymentIndex);

        require(usdt.transfer(seller, paymentAmount[paymentIndex]), "MultiEscrow: failed to transfer USDT tokens to seller");
    }

    function approvePayment(uint256 paymentIndex) external onlyBuyer {
        require(paymentIndex < numberOfPayments, "MultiEscrow: invalid payment index");
        require(!paymentApproved[paymentIndex], "MultiEscrow: payment already approved");

        if (paymentIndex > 0) {
            require(paymentApproved[paymentIndex - 1], "MultiEscrow: previous payment not approved");
        }

        if (paymentIndex > currentPayment) {
            currentPayment = paymentIndex;
        }

        paymentApproved[paymentIndex] = true;
        paymentAmount[paymentIndex] = totalAmount / numberOfPayments;

        emit PaymentApproved(paymentIndex);

        require(usdt.transferFrom(buyer, address(this), paymentAmount[paymentIndex]), "MultiEscrow: failed to receive USDT tokens from buyer");

        if (paymentIndex < numberOfPayments - 1) {
            deadline = block.timestamp + fineDeadline;
        } else {
            deadline = block.timestamp + dTime;
        }
    }

    function disapprovePayment(uint256 paymentIndex) external onlyBuyer {
        require(paymentIndex < numberOfPayments, "MultiEscrow: invalid payment index");
        require(!paymentClaimed[paymentIndex], "MultiEscrow: payment already claimed");

        paymentApproved[paymentIndex] = false;
        deadline = block.timestamp + fineDeadline;

        if (paymentIndex == currentPayment) {
            currentPayment--;
        }
    }

    function claimFine() external onlySeller {
        require(block.timestamp <= deadline, "MultiEscrow: fine deadline passed");

        require(usdt.transfer(seller, fineAmount), "MultiEscrow: failed to transfer fine to seller");
    }

    function approveJob() external onlyBuyer {
        require(block.timestamp <= deadline, "MultiEscrow: deadline passed");
        require(currentPayment < numberOfPayments, "MultiEscrow: all payments claimed");

        deadline = block.timestamp + fineDeadline;
    }

    function revokeJob() external onlyBuyer {
        require(block.timestamp > deadline, "MultiEscrow: job not finished");
        require(currentPayment < numberOfPayments, "MultiEscrow: all payments claimed");

        paymentApproved[currentPayment] = false;
        deadline = block.timestamp+ dTime;
        currentPayment--;
    }
}

contract MultiEscrowFactory {
    event MultiEscrowCreated(address multiEscrow, address buyer, address seller, uint256 totalAmount);

    function createMultiEscrow(
        address _buyer,
        address _seller,
        uint256 _totalAmount,
        uint256 _numberOfPayments,
        uint256 _fineAmount,
        uint256 _fineDeadline,
        uint256 _deadline,
        address _usdt
    ) external returns (address) {
        MultiEscrow multiEscrow = new MultiEscrow(
            _buyer,
            _seller,
            _totalAmount,
            _numberOfPayments,
            _fineAmount,
            _fineDeadline,
            _deadline,
            _usdt
        );

        emit MultiEscrowCreated(address(multiEscrow), _buyer, _seller, _totalAmount);

        return address(multiEscrow);
    }
} 

