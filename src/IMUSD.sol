// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

/**
 * @title  MUSD Interface
 * @author M0 Labs
 *
 */
interface IMUSD {
    /* ============ Events ============ */

    /**
     * @notice Emitted when tokens are forcefully transferred from a blacklisted account.
     * @param  blacklistedAccount The address of the blacklisted account.
     * @param  recipient The address of the recipient.
     * @param  forceTransferManager The address of the force transfer manager that triggered the event.
     */
    event ForcedTransfer(
        address indexed blacklistedAccount,
        address indexed recipient,
        address indexed forceTransferManager,
        uint256 amount
    );

    /* ============ Custom Errors ============ */

    /// @notice Emitted in constructor if Pauser is 0x0.
    error ZeroPauser();

    /// @notice Emitted in constructor if Force Transfer Manager is 0x0.
    error ZeroForceTransferManager();

    /// @notice Emitted when the length of the input arrays do not match in `forceTransfer` method.
    error ArrayLengthMismatch();

    /* ============ Interactive Functions ============ */

    /**
     * @notice Pauses the contract.
     * @dev    Can only be called by an account with the PAUSER_ROLE.
     */
    function pause() external;

    /**
     * @notice Unpauses the contract.
     * @dev    Can only be called by an account with the PAUSER_ROLE.
     */
    function unpause() external;

    /**
     * @notice Forcefully transfers tokens from a blacklisted accounts to a recipients.
     * @dev    Can only be called by an account with the FORCE_TRANSFER_MANAGER_ROLE.
     * @param  blacklistedAccounts The addresses of the blacklisted accounts.
     * @param  recipients The addresses of the recipients.
     * @param  amounts The amounts of tokens to transfer.
     */
    function forceTransfers(
        address[] calldata blacklistedAccounts,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external;

    /**
     * @notice Forcefully transfers tokens from a blacklisted account to a recipient.
     * @dev    Can only be called by an account with the FORCE_TRANSFER_MANAGER_ROLE.
     * @param  blacklistedAccount The address of the blacklisted account.
     * @param  recipient The address of the recipient.
     * @param  amount The amount of tokens to transfer.
     */
    function forceTransfer(address blacklistedAccount, address recipient, uint256 amount) external;

    /* ============ View/Pure Functions ============ */

    /// @notice The role that can pause and unpause the contract.
    function PAUSER_ROLE() external view returns (bytes32);

    /// @notice The role that can force transfer tokens from blacklisted accounts.
    function FORCE_TRANSFER_MANAGER_ROLE() external view returns (bytes32);
}
