// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import {
    PausableUpgradeable
} from "../lib/evm-m-extensions/lib/common/lib/openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol";

import { MYieldToOne } from "../lib/evm-m-extensions/src/projects/yieldToOne/MYieldToOne.sol";
import { IMYieldToOne } from "../lib/evm-m-extensions/src/projects/yieldToOne/IMYieldToOne.sol";

import { IMUSD } from "./IMUSD.sol";

/**
 * @title  MUSD
 * @notice M extension for the MUSD token.
 * @author M0 Labs
 */
contract MUSD is IMUSD, MYieldToOne, PausableUpgradeable {
    /* ============ Variables ============ */

    /// @inheritdoc IMUSD
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /* ============ Constructor ============ */

    /**
     * @custom:oz-upgrades-unsafe-allow constructor
     * @notice Constructs MUSD Implementation contract
     * @dev    `_disableInitializers()` is called in the inherited MExtension's constructor.
     * @param  mToken       The address of the MToken
     * @param  swapFacility The address of the SwapFacility
     */
    constructor(address mToken, address swapFacility) MYieldToOne(mToken, swapFacility) {}

    /* ============ Initializer ============ */

    /**
     * @dev   Initializes the MUSD token.
     * @param yieldRecipient        The address of a yield destination.
     * @param admin                 The address of an admin.
     * @param blacklistManager      The address of a blacklist manager.
     * @param yieldRecipientManager The address of a yield recipient setter.
     * @param pauser                The address of a pauser.
     */
    function initialize(
        address yieldRecipient,
        address admin,
        address blacklistManager,
        address yieldRecipientManager,
        address pauser
    ) public virtual initializer {
        __MYieldToOne_init("MUSD", "mUSD", yieldRecipient, admin, blacklistManager, yieldRecipientManager);
        _grantRole(PAUSER_ROLE, pauser);
    }

    /* ============ Interactive Functions ============ */

    /// @inheritdoc IMYieldToOne
    function claimYield() public override onlyRole(YIELD_RECIPIENT_MANAGER_ROLE) returns (uint256) {
        return super.claimYield();
    }

    /// @inheritdoc IMUSD
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @inheritdoc IMUSD
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /* ============ Hooks For Internal Interactive Functions ============ */

    /**
     * @dev   Hook called before wrapping M into mUSD.
     * @param account   The account from which M is deposited.
     * @param recipient The account receiving the minted mUSD.
     * @param amount    The amount of tokens to wrap.
     */
    function _beforeWrap(address account, address recipient, uint256 amount) internal view override {
        _requireNotPaused();
        super._beforeWrap(account, recipient, amount);
    }

    /**
     * @dev   Hook called before unwrapping mUSD.
     * @param account The account from which mUSD is burned.
     * @param amount  The amount of tokens to unwrap.
     */
    function _beforeUnwrap(address account, uint256 amount) internal view override {
        _requireNotPaused();
        super._beforeUnwrap(account, amount);
    }

    /**
     * @dev   Hook called before transferring mUSD.
     * @param sender    The address from which the tokens are being transferred.
     * @param recipient The address to which the tokens are being transferred.
     * @param amount    The amount of tokens to transfer.
     */
    function _beforeTransfer(address sender, address recipient, uint256 amount) internal view override {
        _requireNotPaused();
        super._beforeTransfer(sender, recipient, amount);
    }
}
