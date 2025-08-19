// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { Script, console } from "../../lib/forge-std/src/Script.sol";

import { Options } from "../../lib/evm-m-extensions/lib/openzeppelin-foundry-upgrades/src/Options.sol";

import { Upgrades } from "../../lib/evm-m-extensions/lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

abstract contract UpgradeMUSDBase is Script {
    /// @dev Same address across all supported mainnet and testnets networks.
    address public constant MUSD_PROXY = 0xacA92E438df0B2401fF60dA7E4337B687a2435DA;
    address public constant M_TOKEN = 0x866A2BF4E572CbcF37D5071A7a58503Bfb36be1b;
    address public constant SWAP_FACILITY = 0xB6807116b3B1B321a390594e31ECD6e0076f6278;

    Options public upgradeOptions;

    function _upgradeMUSD(address mToken, address swapFacility) internal {
        address proxyAdmin = _getAdminAddress(MUSD_PROXY);
        console.log("Proxy Admin Address:", proxyAdmin);

        upgradeOptions.constructorData = abi.encode(mToken, swapFacility);
        upgradeOptions.referenceBuildInfoDir = "build-info-v1";
        upgradeOptions.referenceContract = "build-info-v1:MUSD";

        Upgrades.upgradeProxy(MUSD_PROXY, "MUSD.sol:MUSD", "", upgradeOptions, proxyAdmin);
    }

    /// @dev Deploys the new MUSD implementation and returns its address.
    function _prepareMUSDUpgrade(address mToken, address swapFacility) internal returns (address) {
        upgradeOptions.constructorData = abi.encode(mToken, swapFacility);
        upgradeOptions.referenceBuildInfoDir = "build-info-v1";
        upgradeOptions.referenceContract = "build-info-v1:MUSD";

        return Upgrades.prepareUpgrade("MUSD.sol:MUSD", upgradeOptions);
    }

    function _getAdminAddress(address proxy) internal view returns (address) {
        return Upgrades.getAdminAddress(proxy);
    }

    function _getUpgradeAndCallCalldata(address implementation) internal pure returns (bytes memory) {
        return abi.encodeWithSignature("upgradeAndCall(address,address,bytes)", MUSD_PROXY, implementation, "");
    }
}
