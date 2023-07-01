// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDT is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        // Mint 100 tokens to msg.sender
        // Similar to how
        // 1 dollar = 100 cents
        // 1 token = 1 * (10 ** decimals)
        _mint(msg.sender, 1000 * 10**uint(decimals()));
    }

    // function mintForAdmin(uint  _amount) public onlyOwner {
    //     _mint(msg.sender, _amount * 10**uint(decimals()));
    // }
}
