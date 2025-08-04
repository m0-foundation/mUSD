// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { IAccessControl } from "../../lib/evm-m-extensions/lib/common/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";

import { PausableUpgradeable } from "../../lib/evm-m-extensions/lib/common/lib/openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol";

import { IERC20 } from "../../lib/forge-std/src/interfaces/IERC20.sol";

import { Upgrades } from "../../lib/evm-m-extensions/lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import { IMYieldToOne } from "../../lib/evm-m-extensions/src/projects/yieldToOne/IMYieldToOne.sol";

import { BaseUnitTest } from "../../lib/evm-m-extensions/test/utils/BaseUnitTest.sol";

import { MUSDHarness } from "../harness/MUSDHarness.sol";

contract MUSDUnitTests is BaseUnitTest {
    MUSDHarness public mUSD;

    string public constant NAME = "MUSD";
    string public constant SYMBOL = "mUSD";

    address public pauser = makeAddr("pauser");
    address public forceTransferManager = makeAddr("forceTransferManager");

    function setUp() public override {
        super.setUp();

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
                    forceTransferManager
                ),
                mExtensionDeployOptions
            )
        );

        registrar.setEarner(address(mUSD), true);
    }

    /* ============ initialize ============ */

    function test_initialize() external view {
        assertEq(mUSD.name(), NAME);
        assertEq(mUSD.symbol(), SYMBOL);
        assertEq(mUSD.decimals(), 6);
        assertEq(mUSD.mToken(), address(mToken));
        assertEq(mUSD.swapFacility(), address(swapFacility));
        assertEq(mUSD.yieldRecipient(), yieldRecipient);

        assertTrue(IAccessControl(address(mUSD)).hasRole(DEFAULT_ADMIN_ROLE, admin));
        assertTrue(IAccessControl(address(mUSD)).hasRole(BLACKLIST_MANAGER_ROLE, blacklistManager));
        assertTrue(IAccessControl(address(mUSD)).hasRole(YIELD_RECIPIENT_MANAGER_ROLE, yieldRecipientManager));
        assertTrue(IAccessControl(address(mUSD)).hasRole(mUSD.PAUSER_ROLE(), pauser));
    }

    /* ============ claimYield ============ */

    function test_claimYield_onlyYieldRecipientManager() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                YIELD_RECIPIENT_MANAGER_ROLE
            )
        );

        vm.prank(alice);
        mUSD.claimYield();
    }

    function test_claimYield() external {
        uint256 yield = 500e6;

        mToken.setBalanceOf(address(mUSD), 1_500e6);
        mUSD.setTotalSupply(1_000e6);

        assertEq(mUSD.yield(), yield);

        vm.expectEmit();
        emit IMYieldToOne.YieldClaimed(yield);

        vm.prank(yieldRecipientManager);
        assertEq(mUSD.claimYield(), yield);

        assertEq(mUSD.yield(), 0);

        assertEq(mToken.balanceOf(address(mUSD)), 1_500e6);
        assertEq(mUSD.totalSupply(), 1_500e6);

        assertEq(mToken.balanceOf(yieldRecipient), 0);
        assertEq(mUSD.balanceOf(yieldRecipient), yield);
    }

    /* ============ pause ============ */

    function test_pause_onlyPauser() external {
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, mUSD.PAUSER_ROLE())
        );

        vm.prank(alice);
        mUSD.pause();
    }

    function test_pause() external {
        vm.prank(pauser);
        mUSD.pause();

        assertTrue(mUSD.paused());
    }

    /* ============ unpause ============ */

    function test_unpause_onlyPauser() external {
        vm.prank(pauser);
        mUSD.pause();

        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, mUSD.PAUSER_ROLE())
        );

        vm.prank(alice);
        mUSD.unpause();
    }

    function test_unpause() external {
        vm.prank(pauser);
        mUSD.pause();

        vm.prank(pauser);
        mUSD.unpause();

        assertFalse(mUSD.paused());
    }

    /* ============ wrap ============ */

    function test_wrap_whenPaused() external {
        vm.prank(pauser);
        mUSD.pause();

        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);

        vm.prank(address(swapFacility));
        mUSD.wrap(alice, 1e6);
    }

    function test_wrap() external {
        uint256 amount_ = 1_000e6;
        mToken.setBalanceOf(address(swapFacility), amount_);

        vm.expectCall(
            address(mToken),
            abi.encodeWithSelector(mToken.transferFrom.selector, address(swapFacility), address(mUSD), amount_)
        );

        vm.expectEmit();
        emit IERC20.Transfer(address(0), alice, amount_);

        vm.prank(address(swapFacility));
        mUSD.wrap(alice, amount_);

        assertEq(mUSD.balanceOf(alice), amount_);
        assertEq(mUSD.totalSupply(), amount_);

        assertEq(mToken.balanceOf(alice), 0);
        assertEq(mToken.balanceOf(address(mUSD)), amount_);
    }

    /* ============ unwrap ============ */

    function test_unwrap_whenPaused() external {
        vm.prank(pauser);
        mUSD.pause();

        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);

        vm.prank(address(swapFacility));
        mUSD.unwrap(alice, 1e6);
    }

    function test_unwrap() external {
        uint256 amount_ = 1_000e6;

        mUSD.setBalanceOf(address(swapFacility), amount_);
        mUSD.setBalanceOf(alice, amount_);
        mUSD.setTotalSupply(amount_);

        mToken.setBalanceOf(address(mUSD), amount_);

        vm.expectEmit();
        emit IERC20.Transfer(address(swapFacility), address(0), 1e6);

        vm.prank(address(swapFacility));
        mUSD.unwrap(alice, 1e6);

        assertEq(mUSD.totalSupply(), 999e6);
        assertEq(mUSD.balanceOf(address(swapFacility)), 999e6);
        assertEq(mToken.balanceOf(address(swapFacility)), 1e6);

        vm.expectEmit();
        emit IERC20.Transfer(address(swapFacility), address(0), 499e6);

        vm.prank(address(swapFacility));
        mUSD.unwrap(alice, 499e6);

        assertEq(mUSD.totalSupply(), 500e6);
        assertEq(mUSD.balanceOf(address(swapFacility)), 500e6);
        assertEq(mToken.balanceOf(address(swapFacility)), 500e6);

        vm.expectEmit();
        emit IERC20.Transfer(address(swapFacility), address(0), 500e6);

        vm.prank(address(swapFacility));
        mUSD.unwrap(alice, 500e6);

        assertEq(mUSD.totalSupply(), 0);
        assertEq(mUSD.balanceOf(address(swapFacility)), 0);

        // M tokens are sent to SwapFacility and then forwarded to Alice
        assertEq(mToken.balanceOf(address(swapFacility)), amount_);
        assertEq(mToken.balanceOf(address(mUSD)), 0);
    }

    /* ============ transfer ============ */

    function test_transfer_whenPaused() external {
        vm.prank(pauser);
        mUSD.pause();

        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);

        vm.prank(alice);
        mUSD.transfer(bob, 1e6);
    }

    function test_transfer() external {
        uint256 amount_ = 1_000e6;
        mUSD.setBalanceOf(alice, amount_);

        vm.expectEmit();
        emit IERC20.Transfer(alice, bob, amount_);

        vm.prank(alice);
        mUSD.transfer(bob, amount_);

        assertEq(mUSD.balanceOf(alice), 0);
        assertEq(mUSD.balanceOf(bob), amount_);
    }
}
