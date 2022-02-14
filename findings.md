# Team Minamoto

## 1. Slurp function ERC4626 withdraw parameters reversed

The `slurp` function in TurboSafe.sol uses incorrect ordering of input parameters in the `withdraw` function

## Proof of concept/Steps to Reproduce

[Lines 263 and 264 of the TurboSafe.sol are](https://github.com/fei-protocol/tribe-turbo/blob/fcdabb7ca87065d64b296d3519f3f62c675684b6/src/TurboSafe.sol#L263-L264):
```
// If we have unaccrued fees, withdraw them from the Vault and transfer them to the Master.
if (protocolFeeAmount != 0) vault.withdraw(protocolFeeAmount, address(this), address(master));
```

The [`withdraw` function in ERC4626.sol](https://github.com/Rari-Capital/solmate/blob/4079c295d18abadd7835dbcda9368af91ed779f4/src/mixins/ERC4626.sol#L73-L76) has the input parameters ordered as `function withdraw(uint256 amount, address to, address from)`. This means the "to" and "from" addresses are the reverse of what they should be in 

## Impact

## Risk Breakdown
High risk, because the amount withdrawn will be sent in the wrong direction. This will likely cause a revert.

If this was deployed on mainnet, I suspect the Turbo contracts would need to be redeployed because the TurboMaster.sol contract has no way to set a new TurboSafe.sol contract because TurboSafe.sol is not a module.

## Recommendation

Easy, swap the withdraw function parameters to the following:
```
// If we have unaccrued fees, withdraw them from the Vault and transfer them to the Master.
if (protocolFeeAmount != 0) vault.withdraw(protocolFeeAmount, address(master), address(this));
```
----

## 2. nonReentrant modifier on internal function causes revert

The two TurboSafe.sol internal functions `beforeWithdraw` and `afterDeposit` override ERC4626 functions but add the nonReentrant modifier. When these internal nonReentrant functions are called from the `boost` and `less` public nonReentrant functions in TurboSafe.sol, they will revert.

## Proof of concept/Steps to Reproduce

See demo code which can be imported into Remix: [https://remix.ethereum.org/](https://remix.ethereum.org/)

## Impact

High, because the functions cannot be used in current form

## Risk Breakdown
Difficulty to Exploit: Easy, just use the contract normally and experience a revert

## Recommendation

Remove the nonReentrant modifier from the `beforeWithdraw` and `afterDeposit` internal functions

----

## 3. Remove unnecessary nonReentrant modifiers for gas savings

The only two functions that benefit from the nonReentrant modifier are the `boost` and `slurp` functions of TurboSafe.sol.
The other functions can remove the nonReentrant modifier because they either 1. do not modify state variables or 2. follow the checks-effects-interaction pattern. As a result, the ReentrancyGuard import in TurboGibber.sol can be completely removed.

## Proof of concept/Steps to Reproduce

Manual testing

## Impact

Gas savings

## Risk Breakdown

Gas savings

## Recommendation

Remove the nonReentrant modifier from all functions besides `boost` and `slurp`

----

## 4. Gas optimization in TurboClerk.sol

A small gas savings in TurboClerk.sol is possible

t11s mentioned this during the walkthrough but we include it for completeness.

## Proof of concept/Steps to Reproduce

[Line 108 of TurboClerk.sol](https://github.com/fei-protocol/tribe-turbo/blob/fcdabb7ca87065d64b296d3519f3f62c675684b6/src/modules/TurboClerk.sol#L108)

```
if (getCustomFeePercentageForSafe[safe] != 0) return getCustomFeePercentageForSafe[safe];
```

we can cache this value for gas savings. The updated code might look like

```
// Get the custom fee percentage set for the Safe
uint256 customFeePercentageForSafe = getCustomFeePercentageForSafe[safe];
if (customFeePercentageForSafe != 0) return customFeePercentageForSafe;
```

## Impact

Gas savings

## Risk Breakdown

None

## Recommendation

Cache value for gas savings

----

## 5. Unnecessary unchecked clause

There is an unchecked clause in TurboMaster.sol around code that performs no arithmetic operations. The unchecked clause can be removed because it doesn't provide gas savings.

## Proof of concept/Steps to Reproduce

[Lines 252-260 of TurboMaster.sol](https://github.com/fei-protocol/tribe-turbo/blob/fcdabb7ca87065d64b296d3519f3f62c675684b6/src/TurboMaster.sol#L252-L260) have an unnecessary unchecked clause. The code inside the clause only sets two variables and does not benefit from unchecked
```
getTotalBoostedForVault[vault] = newTotalBoostedForVault;
getTotalBoostedAgainstCollateral[underlying] = newTotalBoostedAgainstCollateral;
```

## Impact

Clean code

## Risk Breakdown

No risk

## Recommendation

Remove unnecessary unchecked clause

----

## 6. Comment typo

There is a typo in a comment

## Proof of concept/Steps to Reproduce

The word "Safe" should be added to the end of this comment in [TurboSafe.sol line 243](https://github.com/fei-protocol/tribe-turbo/blob/fcdabb7ca87065d64b296d3519f3f62c675684b6/src/TurboSafe.sol#L243)

```
// Compute what percentage of the interest earned will go back to the
```

## Impact
Developer confusion :)

## Risk Breakdown
No risk

## Recommendation

Add missing word to comment
