// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { Test } from "../../lib/forge-std/src/Test.sol";
import { IERC20 } from "../../lib/forge-std/src/interfaces/IERC20.sol";

import { IAccessControl } from "../../lib/evm-m-extensions/lib/common/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";

import { IProxyAdmin } from "../../lib/evm-m-extensions/lib/openzeppelin-foundry-upgrades/src/internal/interfaces/IProxyAdmin.sol";

import { UpgradeMUSDBase } from "../../script/upgrade/UpgradeMUSDBase.sol";

import { MUSD } from "../../src/MUSD.sol";

contract UpgradeTests is UpgradeMUSDBase, Test {
    uint256 public mainnetFork;
    uint256 public lineaFork;

    address public constant UPGRADER = 0xF2f1ACbe0BA726fEE8d75f3E32900526874740BB; // M0 deployer address

    IERC20 public mToken = IERC20(M_TOKEN);
    MUSD public mUSD = MUSD(MUSD_PROXY);

    string public constant NAME = "MetaMask USD";
    string public constant SYMBOL = "mUSD";

    address[] public mUSDHoldersEthereum = [
        0x77BAB32F75996de8075eBA62aEa7b1205cf7E004,
        0x98F2b37A1F5e6dB22c4eBa7DE0398fB9be2AF03F,
        0x6a568A616dAB0a8F092139Dd64663772c180170b
    ];

    uint256[] public mUSDBalancesEthereum = [30000000, 30000000, 10000000];

    address[] public mUSDHoldersLinea = [0x6a568A616dAB0a8F092139Dd64663772c180170b];
    uint256[] public mUSDBalancesLinea = [10000000];

    function setUp() public {
        mainnetFork = vm.createFork(vm.envString("MAINNET_RPC_URL"), 23177935);
        lineaFork = vm.createFork(vm.envString("LINEA_RPC_URL"), 22257280);
    }

    /* ============ Upgrade ============ */

    function testFork_upgradeEthereumMainnet() external {
        vm.selectFork(mainnetFork);

        vm.deal(UPGRADER, 100 ether);

        vm.startPrank(UPGRADER);

        _upgradeMUSD(M_TOKEN, SWAP_FACILITY);

        vm.stopPrank();

        _assertEthereumMainnetUpgrade();
    }

    function testFork_upgradeLineaMainnet() external {
        vm.selectFork(lineaFork);

        vm.deal(UPGRADER, 100 ether);

        vm.startPrank(UPGRADER);

        _upgradeMUSD(M_TOKEN, SWAP_FACILITY);

        vm.stopPrank();

        _assertLineaMainnetUpgrade();
    }

    function test_upgradeEthereumMainnetViaProxyAdmin_interface() external {
        vm.selectFork(mainnetFork);

        address implementation = _prepareMUSDUpgrade(M_TOKEN, SWAP_FACILITY);

        vm.startPrank(UPGRADER);

        IProxyAdmin(_getAdminAddress(MUSD_PROXY)).upgradeAndCall(MUSD_PROXY, implementation, "");

        vm.stopPrank();

        _assertEthereumMainnetUpgrade();
    }

    function test_upgradeLineaMainnetViaProxyAdmin_interface() external {
        vm.selectFork(lineaFork);

        address implementation = _prepareMUSDUpgrade(M_TOKEN, SWAP_FACILITY);

        vm.startPrank(UPGRADER);

        IProxyAdmin(_getAdminAddress(MUSD_PROXY)).upgradeAndCall(MUSD_PROXY, implementation, "");

        vm.stopPrank();

        _assertLineaMainnetUpgrade();
    }

    function test_upgradeEthereumMainnetViaProxyAdmin_calldata() external {
        vm.selectFork(mainnetFork);

        address implementation = _prepareMUSDUpgrade(M_TOKEN, SWAP_FACILITY);

        vm.startPrank(UPGRADER);

        _getAdminAddress(MUSD_PROXY).call(_getUpgradeAndCallCalldata(implementation));

        vm.stopPrank();

        _assertEthereumMainnetUpgrade();
    }

    function test_upgradeLineaMainnetViaProxyAdmin_calldata() external {
        vm.selectFork(lineaFork);

        address implementation = _prepareMUSDUpgrade(M_TOKEN, SWAP_FACILITY);

        vm.startPrank(UPGRADER);

        _getAdminAddress(MUSD_PROXY).call(_getUpgradeAndCallCalldata(implementation));

        vm.stopPrank();

        _assertLineaMainnetUpgrade();
    }

    function _assertEthereumMainnetUpgrade() internal view {
        assertEq(mUSD.name(), NAME);
        assertEq(mUSD.symbol(), SYMBOL);
        assertEq(mUSD.decimals(), 6);
        assertEq(mUSD.mToken(), M_TOKEN);
        assertEq(mUSD.swapFacility(), SWAP_FACILITY);
        assertEq(mUSD.yieldRecipient(), UPGRADER);

        assertTrue(IAccessControl(MUSD_PROXY).hasRole(mUSD.DEFAULT_ADMIN_ROLE(), UPGRADER));
        assertTrue(IAccessControl(MUSD_PROXY).hasRole(mUSD.FREEZE_MANAGER_ROLE(), UPGRADER));
        assertTrue(IAccessControl(MUSD_PROXY).hasRole(mUSD.YIELD_RECIPIENT_MANAGER_ROLE(), UPGRADER));
        assertTrue(IAccessControl(MUSD_PROXY).hasRole(mUSD.PAUSER_ROLE(), UPGRADER));
        assertTrue(IAccessControl(MUSD_PROXY).hasRole(mUSD.FORCED_TRANSFER_MANAGER_ROLE(), UPGRADER));

        assertEq(mUSD.totalSupply(), 70000000);
        assertEq(mToken.balanceOf(MUSD_PROXY), 70049683);

        for (uint256 i; i < mUSDHoldersEthereum.length; i++) {
            assertEq(mUSD.balanceOf(mUSDHoldersEthereum[i]), mUSDBalancesEthereum[i]);
        }
    }

    function _assertLineaMainnetUpgrade() internal view {
        assertEq(mUSD.name(), NAME);
        assertEq(mUSD.symbol(), SYMBOL);
        assertEq(mUSD.decimals(), 6);
        assertEq(mUSD.mToken(), M_TOKEN);
        assertEq(mUSD.swapFacility(), SWAP_FACILITY);
        assertEq(mUSD.yieldRecipient(), 0x12b1A4226ba7D9Ad492779c924b0fC00BDCb6217);

        assertTrue(IAccessControl(MUSD_PROXY).hasRole(mUSD.DEFAULT_ADMIN_ROLE(), UPGRADER));
        assertTrue(IAccessControl(MUSD_PROXY).hasRole(mUSD.FREEZE_MANAGER_ROLE(), UPGRADER));
        assertTrue(IAccessControl(MUSD_PROXY).hasRole(mUSD.YIELD_RECIPIENT_MANAGER_ROLE(), UPGRADER));
        assertTrue(IAccessControl(MUSD_PROXY).hasRole(mUSD.PAUSER_ROLE(), UPGRADER));
        assertTrue(IAccessControl(MUSD_PROXY).hasRole(mUSD.FORCED_TRANSFER_MANAGER_ROLE(), UPGRADER));

        assertEq(mUSD.totalSupply(), 10000000);
        assertEq(mToken.balanceOf(MUSD_PROXY), 10004519);

        for (uint256 i; i < mUSDHoldersLinea.length; i++) {
            assertEq(mUSD.balanceOf(mUSDHoldersLinea[i]), mUSDBalancesLinea[i]);
        }
    }
}
