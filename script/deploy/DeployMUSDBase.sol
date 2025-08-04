// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { DeployHelpers } from "../../lib/common/script/deploy/DeployHelpers.sol";

import { Options } from "../../lib/evm-m-extensions/lib/openzeppelin-foundry-upgrades/src/Options.sol";

import { Upgrades } from "../../lib/evm-m-extensions/lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import { MUSD } from "../../src/MUSD.sol";

abstract contract DeployMUSDBase is DeployHelpers {
    /// @dev Same address across all supported mainnet and testnets networks.
    address public constant M_TOKEN = 0x866A2BF4E572CbcF37D5071A7a58503Bfb36be1b;

    // TODO: Replace with actual address when deployed
    /// @dev Same address across all supported mainnet and testnets networks.
    address public constant SWAP_FACILITY = 0x78678C4Ab4C32d1b4c2514ea2c8ebe7F8a363140;

    Options public deployOptions;

    function _deployMUSD(
        address deployer,
        address mToken,
        address swapFacility,
        address yieldRecipient,
        address admin,
        address blacklistManager,
        address yieldRecipientManager,
        address pauser, 
        address forceTransferManager
    ) internal returns (address implementation, address proxy, address proxyAdmin) {
        deployOptions.constructorData = abi.encode(address(mToken), address(swapFacility));

        implementation = Upgrades.deployImplementation("MUSD.sol:MUSD", deployOptions);

        proxy = _deployCreate3TransparentProxy(
            implementation,
            admin,
            abi.encodeWithSelector(
                MUSD.initialize.selector,
                yieldRecipient,
                admin,
                blacklistManager,
                yieldRecipientManager,
                pauser, 
                forceTransferManager
            ),
            _computeSalt(deployer, "MUSD")
        );

        proxyAdmin = Upgrades.getAdminAddress(proxy);
    }
}
