// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    constructor() ERC20("USDT", "USDT") {
    }

    function mint(address receipt, uint256 amount) public {
        _mint(receipt, amount);
    }

    function decimals() public override view returns (uint8) {
        return 6;
    }
}
