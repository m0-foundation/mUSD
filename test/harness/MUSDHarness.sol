// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { MUSD } from "../../src/MUSD.sol";

contract MUSDHarness is MUSD {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address mToken, address swapFacility) MUSD(mToken, swapFacility) {}

    function setBalanceOf(address account, uint256 amount) external {
        _getMYieldToOneStorageLocation().balanceOf[account] = amount;
    }

    function setTotalSupply(uint256 amount) external {
        _getMYieldToOneStorageLocation().totalSupply = amount;
    }
}
