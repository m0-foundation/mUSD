// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { console } from "../../lib/forge-std/src/console.sol";

import { UpgradeMUSDBase } from "./UpgradeMUSDBase.sol";

/**
 * @notice MUSD upgrade script.
 * @dev Can only be used if the current Proxy Admin owner is an EOA.
 *      If the Proxy Admin owner is a Gnosis Safe, use the `PrepareMUSDUpgrade` script to prepare the upgrade
 *      and then use the Gnosis Safe to execute the upgrade via the Proxy Admin interface or calldata.
 *      See `test_upgradeViaProxyAdmin_interface` and `test_upgradeViaProxyAdmin_calldata` in Upgrade.t.sol for details.
 */
contract UpgradeMUSD is UpgradeMUSDBase {
    function run() external {
        address upgrader = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
        console.log("Upgrader:", upgrader);

        vm.startBroadcast(upgrader);

        _upgradeMUSD(M_TOKEN, SWAP_FACILITY);

        vm.stopBroadcast();

        console.log("MUSD upgraded successfully.");
    }
}
