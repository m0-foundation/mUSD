// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { IAccessControl } from "../../lib/evm-m-extensions/lib/common/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";
import { PausableUpgradeable } from "../../lib/evm-m-extensions/lib/common/lib/openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol";

import { Upgrades } from "../../lib/evm-m-extensions/lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import { IMTokenLike } from "../../lib/evm-m-extensions/src/interfaces/IMTokenLike.sol";

import { BaseIntegrationTest } from "../../lib/evm-m-extensions/test/utils/BaseIntegrationTest.sol";

import { IMUSD } from "../../src/IMUSD.sol";

import { MUSDHarness } from "../harness/MUSDHarness.sol";

contract MUSDIntegrationTests is BaseIntegrationTest {
    uint256 public mainnetFork;

    address public pauser = makeAddr("pauser");
    address public forcedTransferManager = makeAddr("forcedTransferManager");

    address public swapper;
    uint256 public swapperKey;

    MUSDHarness public mUSD;

    function setUp() public override {
        mainnetFork = vm.createSelectFork(vm.envString("MAINNET_RPC_URL"), 22_482_175);

        super.setUp();

        (swapper, swapperKey) = makeAddrAndKey("swapper");

        _fundAccounts();
        _giveM(swapper, 10e6);
        _giveEth(swapper, 0.1 ether);

        vm.prank(admin);
        swapFacility.grantRole(M_SWAPPER_ROLE, swapper);

        mUSD = MUSDHarness(
            Upgrades.deployTransparentProxy(
                "MUSDHarness.sol:MUSDHarness",
                admin,
                abi.encodeWithSelector(
                    MUSDHarness.initialize.selector,
                    yieldRecipient,
                    admin,
                    blacklistManager,
                    yieldRecipientManager,
                    pauser,
                    forcedTransferManager,
                    swapper
                ),
                mExtensionDeployOptions
            )
        );
    }

    function test_integration_constants() external view {
        assertEq(mUSD.name(), "MUSD");
        assertEq(mUSD.symbol(), "mUSD");
        assertEq(mUSD.decimals(), 6);
        assertEq(mUSD.mToken(), address(mToken));
        assertEq(mUSD.swapFacility(), address(swapFacility));
        assertEq(mUSD.yieldRecipient(), yieldRecipient);

        assertTrue(IAccessControl(address(mUSD)).hasRole(DEFAULT_ADMIN_ROLE, admin));
        assertTrue(IAccessControl(address(mUSD)).hasRole(BLACKLIST_MANAGER_ROLE, blacklistManager));
        assertTrue(IAccessControl(address(mUSD)).hasRole(YIELD_RECIPIENT_MANAGER_ROLE, yieldRecipientManager));
        assertTrue(IAccessControl(address(mUSD)).hasRole(mUSD.PAUSER_ROLE(), pauser));
        assertTrue(IAccessControl(address(mUSD)).hasRole(mUSD.FORCED_TRANSFER_MANAGER_ROLE(), forcedTransferManager));
        assertTrue(IAccessControl(address(mUSD)).hasRole(mUSD.MUSD_SWAPPER_ROLE(), swapper));
    }

    function test_yieldAccumulationAndClaim() external {
        uint256 amount = 10e6;

        // Enable earning for the contract
        _addToList(EARNERS_LIST, address(mUSD));
        mUSD.enableEarning();

        // Check the initial earning state
        assertEq(mToken.isEarning(address(mUSD)), true);

        vm.warp(vm.getBlockTimestamp() + 1 days);

        // Wrap from non-earner account
        _swapInM(address(mUSD), swapper, swapper, amount);

        // Check balances of MUSD and swapper after wrapping
        assertEq(mUSD.balanceOf(swapper), amount); // user receives exact amount
        assertApproxEqAbs(mToken.balanceOf(address(mUSD)), amount, 2); // rounds down

        // Fast forward 10 days in the future to generate yield
        vm.warp(vm.getBlockTimestamp() + 10 days);

        // Yield accrual
        assertEq(mUSD.yield(), 11375);

        // Transfers do not affect yield
        vm.prank(swapper);
        mUSD.transfer(bob, amount / 2);

        assertEq(mUSD.balanceOf(bob), amount / 2);
        assertEq(mUSD.balanceOf(swapper), amount / 2);

        // Yield stays the same
        assertEq(mUSD.yield(), 11375);

        // Unwraps
        _swapMOut(address(mUSD), swapper, swapper, amount / 2);

        // swapper receives exact amount but mUSD loses 1 wei
        // due to rounding up in M when transferring from an earner to a non-earner
        assertEq(mUSD.yield(), 11374);

        assertEq(mUSD.balanceOf(bob), amount / 2);
        assertEq(mUSD.balanceOf(swapper), 0);
        assertEq(mToken.balanceOf(bob), amount);
        assertEq(mToken.balanceOf(swapper), amount / 2);

        assertEq(mUSD.balanceOf(yieldRecipient), 0);

        // Claim yield
        vm.prank(yieldRecipientManager);
        mUSD.claimYield();

        assertEq(mUSD.balanceOf(yieldRecipient), 11374);
        assertEq(mUSD.yield(), 0);
        assertEq(mToken.balanceOf(address(mUSD)), amount / 2 + 11374);
        assertEq(mUSD.totalSupply(), amount / 2 + 11374);

        // Wrap from earner account
        _addToList(EARNERS_LIST, swapper);

        vm.prank(swapper);
        mToken.startEarning();

        _swapInM(address(mUSD), swapper, swapper, amount / 2 - 1); // Account for the rounding error

        // Check balances of MUSD and swapper after wrapping
        assertEq(mUSD.balanceOf(swapper), amount / 2 - 1);
        assertEq(mToken.balanceOf(address(mUSD)), 11374 + amount - 1);

        // Disable earning for the contract
        _removeFromList(EARNERS_LIST, address(mUSD));
        mUSD.disableEarning();

        assertFalse(mUSD.isEarningEnabled());

        // Fast forward 10 days in the future
        vm.warp(vm.getBlockTimestamp() + 10 days);

        // No yield should accrue
        assertEq(mUSD.yield(), 0);

        // Re-enable earning for the contract
        _addToList(EARNERS_LIST, address(mUSD));
        mUSD.enableEarning();

        // Yield should accrue again
        vm.warp(vm.getBlockTimestamp() + 10 days);

        assertEq(mUSD.yield(), 11388);
    }

    /* ============ enableEarning ============ */

    function test_enableEarning_notApprovedEarner() external {
        vm.expectRevert(abi.encodeWithSelector(IMTokenLike.NotApprovedEarner.selector));
        mUSD.enableEarning();
    }

    /* ============ disableEarning ============ */

    function test_disableEarning_approvedEarner() external {
        _addToList(EARNERS_LIST, address(mUSD));
        mUSD.enableEarning();

        vm.expectRevert(abi.encodeWithSelector(IMTokenLike.IsApprovedEarner.selector));
        mUSD.disableEarning();
    }

    /* ============ wrap ============ */

    function test_wrap() external {
        _addToList(EARNERS_LIST, address(mUSD));
        mUSD.enableEarning();

        assertEq(mToken.balanceOf(swapper), 10e6);

        _swapInM(address(mUSD), swapper, swapper, 5e6);

        assertEq(mUSD.balanceOf(swapper), 5e6);
        assertEq(mUSD.totalSupply(), 5e6);

        assertEq(mToken.balanceOf(swapper), 5e6);
        assertApproxEqAbs(mToken.balanceOf(address(mUSD)), 5e6, 1);

        assertEq(mUSD.yield(), 0);

        _swapInM(address(mUSD), swapper, swapper, 5e6);

        assertEq(mUSD.balanceOf(swapper), 10e6);
        assertEq(mUSD.totalSupply(), 10e6);

        assertEq(mToken.balanceOf(swapper), 0);
        assertApproxEqAbs(mToken.balanceOf(address(mUSD)), 10e6, 2);

        assertEq(mUSD.yield(), 0);

        // Move time forward to generate yield
        vm.warp(vm.getBlockTimestamp() + 365 days);

        assertEq(mUSD.yield(), 42_3730);

        assertEq(mUSD.balanceOf(swapper), 10e6);
        assertEq(mUSD.totalSupply(), 10e6);
    }

    function test_wrapWithPermits() external {
        _addToList(EARNERS_LIST, address(mUSD));

        assertEq(mToken.balanceOf(swapper), 10e6);

        _swapInMWithPermitVRS(address(mUSD), swapper, swapperKey, swapper, 5e6, 0, block.timestamp);

        assertEq(mUSD.balanceOf(swapper), 5e6);
        assertEq(mToken.balanceOf(swapper), 5e6);

        _swapInMWithPermitSignature(address(mUSD), swapper, swapperKey, swapper, 5e6, 1, block.timestamp);

        assertEq(mUSD.balanceOf(swapper), 10e6);
        assertEq(mToken.balanceOf(swapper), 0);
    }

    function test_wrap_notApprovedSwapper() external {
        _addToList(EARNERS_LIST, address(mUSD));
        mUSD.enableEarning();

        vm.prank(alice);
        mToken.approve(address(swapFacility), 10e6);

        vm.expectRevert(abi.encodeWithSelector(IMUSD.NotApprovedSwapper.selector, alice));

        vm.prank(alice);
        swapFacility.swapInM(address(mUSD), 10e6, alice);
    }

    /* ============ unwrap ============ */

    function test_unwrap() external {
        _addToList(EARNERS_LIST, address(mUSD));
        mUSD.enableEarning();

        mUSD.setBalanceOf(swapper, 10e6);
        mUSD.setTotalSupply(10e6);
        _giveM(address(mUSD), 10e6);

        // 2 wei are lost due to rounding
        assertApproxEqAbs(mToken.balanceOf(address(mUSD)), 10e6, 2);
        assertEq(mToken.balanceOf(swapper), 10e6);
        assertEq(mUSD.balanceOf(swapper), 10e6);
        assertEq(mUSD.totalSupply(), 10e6);

        // Move time forward to generate yield
        vm.warp(vm.getBlockTimestamp() + 365 days);

        assertEq(mUSD.yield(), 42_3730);

        _swapMOut(address(mUSD), swapper, swapper, 5e6);

        assertApproxEqAbs(mToken.balanceOf(address(mUSD)), 42_3730 + 5e6, 1);
        assertEq(mToken.balanceOf(swapper), 15e6);
        assertEq(mUSD.balanceOf(swapper), 5e6);
        assertEq(mUSD.totalSupply(), 5e6);

        _swapMOut(address(mUSD), swapper, swapper, 5e6);

        assertEq(mToken.balanceOf(swapper), 20e6);

        // swapper's full withdrawal would have reverted without yield.
        // The 2 wei lost due to rounding were covered by the yield.
        assertEq(mUSD.yield(), 42_3730 - 2);
        assertEq(mToken.balanceOf(address(mUSD)), 42_3730 - 2);

        assertEq(mUSD.balanceOf(swapper), 0);
        assertEq(mUSD.totalSupply(), 0);
    }

    function test_unwrapWithPermits() external {
        _addToList(EARNERS_LIST, address(mUSD));
        mUSD.enableEarning();

        mUSD.setBalanceOf(swapper, 11e6);
        mUSD.setTotalSupply(11e6);
        _giveM(address(mUSD), 11e6);

        assertEq(mToken.balanceOf(swapper), 10e6);
        assertEq(mUSD.balanceOf(swapper), 11e6);

        _swapOutMWithPermitVRS(address(mUSD), swapper, swapperKey, swapper, 5e6, 0, block.timestamp);

        assertEq(mUSD.balanceOf(swapper), 6e6);
        assertEq(mToken.balanceOf(swapper), 15e6);

        _swapOutMWithPermitSignature(address(mUSD), swapper, swapperKey, swapper, 5e6, 1, block.timestamp);

        assertEq(mUSD.balanceOf(swapper), 1e6);
        assertEq(mToken.balanceOf(swapper), 20e6);
    }

    function test_unwrap_notApprovedSwapper() external {
        _addToList(EARNERS_LIST, address(mUSD));
        mUSD.enableEarning();

        mUSD.setBalanceOf(alice, 10e6);
        mUSD.setTotalSupply(10e6);
        _giveM(address(mUSD), 10e6);

        vm.prank(alice);
        mUSD.approve(address(swapFacility), 10e6);

        vm.expectRevert(abi.encodeWithSelector(IMUSD.NotApprovedSwapper.selector, alice));

        vm.prank(alice);
        swapFacility.swapOutM(address(mUSD), 10e6, alice);
    }

    /* ============ claimYield ============ */

    function test_claimYield() external {
        _addToList(EARNERS_LIST, address(mUSD));
        mUSD.enableEarning();

        mUSD.setBalanceOf(alice, 10e6);
        mUSD.setTotalSupply(10e6);
        _giveM(address(mUSD), 10e6);

        // 2 wei are lost due to rounding
        assertApproxEqAbs(mToken.balanceOf(address(mUSD)), 10e6, 2);
        assertEq(mUSD.balanceOf(yieldRecipient), 0);

        // Move time forward to generate yield
        vm.warp(vm.getBlockTimestamp() + 365 days);

        assertEq(mUSD.yield(), 42_3730);
        assertEq(mUSD.totalSupply(), 10e6);
        assertEq(mToken.balanceOf(address(mUSD)), 10e6 + 42_3730); // Rounding error has been covered by yield

        vm.prank(yieldRecipientManager);
        assertEq(mUSD.claimYield(), 42_3730);

        assertEq(mUSD.yield(), 0);
        assertEq(mUSD.totalSupply(), 10e6 + 42_3730);
        assertEq(mUSD.balanceOf(yieldRecipient), 42_3730);
        assertEq(mToken.balanceOf(address(mUSD)), 10e6 + 42_3730);
    }

    /* ============ pause ============ */

    function test_whenPaused() external {
        uint256 amount = 1e6;

        _addToList(EARNERS_LIST, address(mUSD));
        mUSD.enableEarning();

        mUSD.setBalanceOf(alice, amount);
        mUSD.setTotalSupply(amount);

        _giveM(address(mUSD), amount);

        vm.prank(pauser);
        mUSD.pause();

        bytes4 selector = PausableUpgradeable.EnforcedPause.selector;

        // test wrap
        vm.prank(alice);
        mToken.approve(address(swapFacility), amount);

        vm.expectRevert(selector);

        vm.prank(alice);
        swapFacility.swapInM(address(mUSD), amount, alice);

        // test unwrap
        vm.prank(alice);
        mUSD.approve(address(swapFacility), amount);

        vm.expectRevert(selector);

        vm.prank(alice);
        swapFacility.swapOutM(address(mUSD), amount, alice);

        vm.expectRevert(selector);

        vm.prank(alice);
        mUSD.transfer(bob, amount);

        // claimYield is not paused
        vm.warp(block.timestamp + 1 days);

        uint256 yield = mUSD.yield();
        assertGt(yield, 0);

        vm.prank(yieldRecipientManager);
        mUSD.claimYield();

        assertEq(mUSD.balanceOf(yieldRecipient), yield);
    }
}
