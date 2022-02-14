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

## 2. Comment typo

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

----

## 3. nonReentrant modifier on internal function causes revert

A clear and concise description of the bug.

## Proof of concept/Steps to Reproduce

## Impact

## Risk Breakdown
Difficulty to Exploit: Easy
Weakness:
CVSS2 Score:

## Recommendation

## References

