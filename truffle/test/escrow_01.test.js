const assert = require('chai').assert;
const Web3 = require('web3');
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545")); // Replace with your own provider URL
const EscrowContract = artifacts.require('EscrowContract');

describe('EscrowContract', function() {
    let escrowContractInstance;
    let owner;
    let buyer;
    let seller;

    before(async function() {
        escrowContractInstance = await EscrowContract.deployed();
        owner = web3.eth.accounts[0];
        buyer = web3.eth.accounts[1];
        seller = web3.eth.accounts[2];
    });

    it('should allow the owner to add a new escrow', async function() {
        const amount = web3.toWei(1, 'ether');
        const deadline = Math.floor(Date.now() / 1000) + 3600; // Set deadline to one hour from now
        const result = await escrowContractInstance.addEscrow(buyer, seller, deadline, { from: owner, value: amount });
        assert.equal(result.logs[0].event, 'EscrowAdded');
        assert.equal(result.logs[0].args.buyer, buyer);
        assert.equal(result.logs[0].args.seller, seller);
        assert.equal(result.logs[0].args.deadline.toNumber(), deadline);
        assert.equal(result.logs[0].args.amount.toNumber(), amount);
    });

    it('should not allow a non-owner to add a new escrow', async function() {
        const amount = web3.toWei(1, 'ether');
        const deadline = Math.floor(Date.now() / 1000) + 3600; // Set deadline to one hour from now
        await assert.isRejected(escrowContractInstance.addEscrow(buyer, seller, deadline, { from: buyer, value: amount }));
    });

    it('should allow the buyer to confirm the escrow', async function() {
        const result = await escrowContractInstance.confirmEscrow({ from: buyer });
        assert.equal(result.logs[0].event, 'EscrowConfirmed');
        assert.equal(result.logs[0].args.buyer, buyer);
        assert.equal(result.logs[0].args.seller, seller);
    });

    it('should not allow the seller to confirm the escrow', async function() {
        await assert.isRejected(escrowContractInstance.confirmEscrow({ from: seller }));
    });

    it('should allow the seller to withdraw the funds after the deadline has passed', async function() {
        const deadline = Math.floor(Date.now() / 1000) - 3600; // Set deadline to one hour ago
        await escrowContractInstance.addEscrow(buyer, seller, deadline, { from: owner, value: web3.toWei(1, 'ether') });
        await escrowContractInstance.confirmEscrow({ from: buyer });
        const result = await escrowContractInstance.withdrawFunds({ from: seller });
        assert.equal(result.logs[0].event, 'FundsWithdrawn');
        assert.equal(result.logs[0].args.seller, seller);
        assert.equal(result.logs[0].args.amount.toNumber(), web3.toWei(1, 'ether'));
    });

    it('should not allow the seller to withdraw the funds before the deadline has passed', async function() {
        const deadline = Math.floor(Date.now() / 1000) + 3600; // Set deadline to one hour from now
        await escrowContractInstance.addEscrow(buyer, seller, deadline, { from: owner, value: web3.toWei(1, 'ether') });
        await escrowContractInstance.confirmEscrow({ from: buyer });
        await assert.isRejected(escrowContractInstance.withdrawFunds({ from: seller }));
    });
});
