// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { console } from "../../lib/forge-std/src/console.sol";

import { UpgradeMUSDBase } from "./UpgradeMUSDBase.sol";

contract PrepareMUSDUpgrade is UpgradeMUSDBase {
    function run() external {
        address deployer_ = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
        console.log("Deployer:", deployer_);

        vm.startBroadcast(deployer_);

        address implementation = _prepareMUSDUpgrade(M_TOKEN, SWAP_FACILITY);

        vm.stopBroadcast();

        console.log("MUSD Implementation successfully deployed at: %s", implementation);
        console.log("Proxy admin to call to perform the upgrade: %s", _getAdminAddress(MUSD_PROXY));

        console.log("Calldata to call the proxy admin with to perform the upgrade:");
        console.logBytes(_getUpgradeAndCallCalldata(implementation));
    }
}
