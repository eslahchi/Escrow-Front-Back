pragma solidity ^0.8.0;

import "truffle/Assert.sol";
import "../contracts/EscrowContract-V0.1.sol";

contract TestEscrowContract {
    EscrowContract private escrowContract;
    address private owner;
    address private buyer;
    address private seller;

    function beforeEach() public {
        escrowContract = new EscrowContract();
        owner = address(this);
        buyer = address(0x1);
        seller = address(0x2);
    }

    function testAddEscrow() public {
        uint256 amount = 100;
        uint256 deadline = block.timestamp + 3600;
        bool result = escrowContract.addEscrow{value: amount}(buyer, seller, deadline);
        Assert.isTrue(result, "Failed to add escrow");
    }

    function testAddEscrowShouldFailWithInvalidDeadline() public {
        uint256 amount = 100;
        uint256 deadline = block.timestamp - 3600;
        bool result = escrowContract.addEscrow{value: amount}(buyer, seller, deadline);
        Assert.isFalse(result, "Escrow added with invalid deadline");
    }

    function testConfirmEscrow() public {
        uint256 amount = 100;
        uint256 deadline = block.timestamp + 3600;
        escrowContract.addEscrow{value: amount}(buyer, seller, deadline);
        bool result = escrowContract.confirmEscrow({from: buyer});
        Assert.isTrue(result, "Failed to confirm escrow");
    }

    function testConfirmEscrowShouldFailWithInvalidCaller() public {
        uint256 amount = 100;
        uint256 deadline = block.timestamp + 3600;
        escrowContract.addEscrow{value: amount}(buyer, seller, deadline);
        bool result = escrowContract.confirmEscrow({from: seller});
        Assert.isFalse(result, "Escrow confirmed by invalid caller");
    }

    function testWithdrawFunds() public {
        uint256 amount = 100;
        uint256 deadline = block.timestamp - 3600;
        escrowContract.addEscrow{value: amount}(buyer, seller, deadline);
        escrowContract.confirmEscrow({from: buyer});
        bool result = escrowContract.withdrawFunds({from: seller});
        Assert.isTrue(result, "Failed to withdraw funds");
    }

    function testWithdrawFundsShouldFailWithValidDeadline() public {
        uint256 amount = 100;
        uint256 deadline = block.timestamp + 3600;
        escrowContract.addEscrow{value: amount}(buyer, seller, deadline);
        escrowContract.confirmEscrow({from: buyer});
        bool result = escrowContract.withdrawFunds({from: seller});
        Assert.isFalse(result, "Funds withdrawn with valid deadline");
    }
}

/*
In this example, we have a Solidity unit test contract for the EscrowContract. The test suite has five test cases:

The first test case checks that an escrow can be added with the correct parameters.
The second test case checks that an escrow cannot be added with an invalid deadline.
The third test case checks that the buyer can confirm the escrow.
The fourth test case checks that a non-buyer cannot confirm the escrow.
The fifth test case checks that the seller can withdraw the funds after the deadline has passed, but cannot withdraw the funds before the deadline has passed.
To run this test suite, you'll need to have Truffle installed and configured with your blockchain provider. You can then run the tests using the truffle test command in your terminal.
*/