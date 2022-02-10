// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

/// @title Fuse Admin
/// @author Fei Protocol
/// @notice Minimal Fuse Admin interface.
interface FuseAdmin {
    /// @notice Whitelists or blacklists a user from accessing the cTokens in the pool.
    /// @param users The users to whitelist or blacklist.
    /// @param enabled Whether to whitelist or blacklist each user.
    function _setWhitelistStatuses(address[] calldata users, bool[] calldata enabled) external;
}
