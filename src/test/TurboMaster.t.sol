// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";

import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {Authority} from "solmate/auth/Auth.sol";
import {MockAuthority} from "solmate/test/utils/mocks/MockAuthority.sol";
import {MockAuthChild} from "solmate/test/utils/mocks/MockAuthChild.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {MockERC4626} from "solmate/test/utils/mocks/MockERC4626.sol";

import {FuseAdmin} from "../interfaces/FuseAdmin.sol";
import {Comptroller} from "../interfaces/Comptroller.sol";

import {TurboGibber} from "../modules/TurboGibber.sol";
import {TurboBooster} from "../modules/TurboBooster.sol";
import {TurboClerk} from "../modules/TurboClerk.sol";

import {TurboSafe} from "../TurboSafe.sol";

/// @title Turbo Master
/// @author Transmissions11
/// @notice Factory for creating and managing Turbo Safes.
/// @dev Must be authorized to call the Turbo Fuse Pool's FuseAdmin.
contract TurboMaster is DSTestPlus, Authority {
    using SafeTransferLib for MockERC20;

    /*///////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    Comptroller pool;
    MockERC20 fei;
    TurboBooster booster;
    TurboClerk clerk;
    TurboGibber gibber;
    Authority authority;
    MockERC4626 vault;
    address owner;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    function setup() public {
       // pool = _pool;
        fei = new MockERC20("FEI", "FEI", 18);
        vault = new MockERC4626(fei, "Mock Vault", "vwTKN");
        authority = authority;
        owner = "0xBEEF";
    }

    /*///////////////////////////////////////////////////////////////
                             SAFE STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The total Fei currently boosting Vaults.
    uint256 public totalBoosted;

    /// @notice Maps Safe addresses to the id they are stored under in the safes array.
    mapping(TurboSafe => uint256) public getSafeId;

    /// @notice Maps Vault addresses to the total amount of Fei they've being boosted with.
    mapping(MockERC4626 => uint256) public getTotalBoostedForVault;

    /// @notice Maps collateral types to the total amount of Fei boosted by Safes using it as collateral.
    mapping(MockERC20 => uint256) public getTotalBoostedAgainstCollateral;

    /// @notice An array of all Safes created by the Master.
    TurboSafe[] public safes;

    /*///////////////////////////////////////////////////////////////
                          SAFE CREATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a new Safe is created.
    /// @param user The user who created the Safe.
    /// @param underlying The underlying token of the Safe.
    /// @param safe The newly deployed Safe contract.
    /// @param id The index of the Safe in the safes array.
    event TurboSafeCreated(address indexed user, MockERC20 indexed underlying, TurboSafe safe, uint256 id);

    event AssertionFailed(uint);

    /// @notice Creates a new Turbo Safe which supports a specific underlying token.
    /// @param underlying The ERC20 token that the Safe should accept.
    /// @return safe The newly deployed Turbo Safe which accepts the provided underlying token.
    function echidna_createSafe(MockERC20 underlying) external requiresAuth returns (TurboSafe safe, uint256 id) {
        // Create a new Safe using the default authority and provided underlying token.
        safe = new TurboSafe(msg.sender, authority, underlying);

        // Prevent the first safe from getting id 0.
        safes.push(TurboSafe(address(0)));

        // Add the safe to the list of Safes.
        safes.push(safe);

        id = safes.length - 1;

        if (id = 0 - 1)
            emit AssertionFailed(id);

        // Store the id/index of the new Safe.
        getSafeId[safe] = id;

        emit TurboSafeCreated(msg.sender, underlying, safe, id);

        // Prepare a users array to whitelist the Safe.
        address[] memory users = new address[](1);
        users[0] = address(safe);

        // Prepare an enabled array to whitelist the Safe.
        bool[] memory enabled = new bool[](1);
        enabled[0] = true;

        // Whitelist the Safe to access the Turbo Fuse Pool.
        FuseAdmin(pool.admin())._setWhitelistStatuses(users, enabled);
    }

    /*///////////////////////////////////////////////////////////////
                          SAFE CALLBACK LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Callback triggered whenever a Safe boosts a Vault.
    /// @param underlying The underlying token of the Safe.
    /// @param vault The Vault that was boosted.
    /// @param feiAmount The amount of Fei used to boost the Vault.
    function echidna_onSafeBoost(
        MockERC20 underlying,
        MockERC4626 vault,
        uint256 feiAmount
    ) external {
        // Get the caller as a Safe instance.
        TurboSafe safe = TurboSafe(msg.sender);

        // Ensure the Safe was created by this Master.
        require(getSafeId[safe] != 0, "INVALID_SAFE");

        // Compute the total amount of Fei that will be boosting the Vault.
        uint256 newTotalBoostedForVault = getTotalBoostedForVault[vault] + feiAmount;

        // Compute the total amount of Fei boosted that will be boosted the Safe's collateral type.
        uint256 newTotalBoostedAgainstCollateral = getTotalBoostedAgainstCollateral[underlying] + feiAmount;

        // Check with the booster that the Safe is allowed to boost the Vault using this amount of Fei.
        require(
            booster.canSafeBoostVault(
                safe,
                underlying,
                vault,
                feiAmount,
                newTotalBoostedForVault,
                newTotalBoostedAgainstCollateral
            ),
            "BOOSTER_REJECTED"
        );

        // Update the total amount of Fei being using to boost Vaults.
        totalBoosted += feiAmount;

        unchecked {
            // Update the total amount of Fei being using to boost the Vault.
            // Cannot overflow because a Safe's total will never be greater than global total.
            getTotalBoostedForVault[vault] = newTotalBoostedForVault;

            // Update the total amount of Fei boosted against the collateral type.
            // Cannot overflow because a collateral type's total will never be greater than global total.
            getTotalBoostedAgainstCollateral[underlying] = newTotalBoostedAgainstCollateral;
        }
    }

    /// @notice Callback triggered whenever a Safe withdraws from a Vault.
    /// @param underlying The underlying token of the Safe.
    /// @param vault The Vault that was withdrawn from.
    /// @param feiAmount The amount of Fei withdrawn from the Vault.
    function echidna_onSafeLess(
        MockERC20 underlying,
        MockERC4626 vault,
        uint256 feiAmount
    ) external {
        // Get the caller as a Safe instance.
        TurboSafe safe = TurboSafe(msg.sender);

        // Ensure the Safe was created by this Master.
        require(getSafeId[safe] != 0, "INVALID_SAFE");

        unchecked {
            // Update the total amount of Fei being using to boost the Vault.
            // Cannot underflow as the Safe validated the withdrawal amount before.
            getTotalBoostedForVault[vault] -= feiAmount;

            // Update the total amount of Fei being using to boost Vaults.
            // Cannot underflow as the Safe validated the withdrawal amount earlier.
            totalBoosted -= feiAmount;

            // Update the total amount of Fei boosted against the collateral type.
            // Cannot underflow as the Safe validated the withdrawal amount previously.
            getTotalBoostedAgainstCollateral[underlying] -= feiAmount;
        }
    }

    /*///////////////////////////////////////////////////////////////
                              SWEEP LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted a token is sweeped from the Master.
    /// @param user The user who sweeped the token from the Master.
    /// @param to The recipient of the sweeped tokens.
    /// @param amount The amount of the token that was sweeped.
    event TokenSweeped(address indexed user, address indexed to, MockERC20 indexed token, uint256 amount);

    /// @notice Claim tokens sitting idly in the Master.
    /// @param to The recipient of the sweeped tokens.
    /// @param token The token to sweep and send.
    /// @param amount The amount of the token to sweep.
    function sweep(
        address to,
        MockERC20 token,
        uint256 amount
    ) external requiresAuth {
        emit TokenSweeped(msg.sender, to, token, amount);

        // Transfer the sweeped tokens to the recipient.
        token.safeTransfer(to, amount);
    }
}
