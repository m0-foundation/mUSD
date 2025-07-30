// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

/**
 * @title  MUSD Interface
 * @author M0 Labs
 *
 */
interface IMUSD {
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

    /* ============ View/Pure Functions ============ */

    /// @notice The role that can pause and unpause the contract.
    function PAUSER_ROLE() external view returns (bytes32);
}
