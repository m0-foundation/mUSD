// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

interface IOwnableLike {
    function owner() external view returns (address);
    function transferOwnership(address newOwner) external;
}
