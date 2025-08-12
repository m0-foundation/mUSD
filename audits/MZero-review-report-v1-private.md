# M^0 MUSD M Extension Security Review

Date: **06.08.25**

Produced by **Kirill Fedoseev** (telegram: [kfedoseev](http://t.me/kfedoseev),
twitter: [@k1rill_fedoseev](http://twitter.com/k1rill_fedoseev))

## Introduction

An independent security review of the M^0 MUSD M Extension contracts was conducted by **kfedoseev** on 06.08.25. The
following methods were used for conducting a security review:

- Manual source code review

## Disclaimer

No security review can guarantee or verify the absence of vulnerabilities. This security review is a time-bound process
where I tried to identify as many potential issues and vulnerabilities as possible, using my personal expertise in the
smart contract development and review.

## About the M^0 MUSD M Extension

The MUSD M Extension is an upgradeable, semi-permissioned ERC20 wrapper for M that forwards all accumulated yield to a
designated address. MUSD also includes pause/unpause functionality, address blacklisting, and blacklisted token
recovery features.

## Observations and Limitations

- The MUSD M Extension is upgradeable, with upgradeability managed by an admin address.
- The pause/unpause, address blacklisting, and blacklisted token recovery features of the MUSD M Extension are
  controlled by different roles within the smart contract. For better security, it is highly encouraged to configure
  these addresses to be distinct and controlled by different parties. For the blacklisted token recovery feature, it is
  also recommended to configure an intermediary on-chain timelock between the MUSD contract and the address controlling
  token recovery.

## Severity classification

| **Severity**           | **Impact: High** | **Impact: Medium** | **Impact: Low** |
| ---------------------- | ---------------- | ------------------ | --------------- |
| **Likelihood: High**   | Critical         | High               | Medium          |
| **Likelihood: Medium** | High             | Medium             | Low             |
| **Likelihood: Low**    | Medium           | Low                | Low             |

**Impact** - the economic, technical, reputational or other damage to the protocol implied from a successful exploit.

**Likelihood** - the probability that a particular finding or vulnerability gets exploited.

**Severity** - the overall criticality of the particular finding.

## Scope summary

Reviewed commits:

- MUSD -
  [f55e98cfc3d6b58c67c144e25ce994caec5fb1e3](https://github.com/m0-foundation/mUSD/tree/f55e98cfc3d6b58c67c144e25ce994caec5fb1e3)
- EVM M Extensions -
  [fc4cd6cd64c1645abd0d0a2737b32d79a07d5eb7](https://github.com/m0-foundation/evm-m-extensions/tree/fc4cd6cd64c1645abd0d0a2737b32d79a07d5eb7)
- Common -
  [66657d984bb77ba83863dd4607704594a6c610bc](https://github.com/m0-foundation/common/tree/66657d984bb77ba83863dd4607704594a6c610bc)

Reviewed contracts:

- `src/IMUSD.sol`
- `src/MUSD.sol`

Reviewed contract diffs:

- [EVM M Extensions](https://github.com/m0-foundation/evm-m-extensions/compare/9b8eb0ad02f03594afde975a575246fc569e375f..fc4cd6cd64c1645abd0d0a2737b32d79a07d5eb7)
- [Common](https://github.com/m0-foundation/common/compare/36b3cc900dba907bafa2ca3f9d2fc9c00fabe805..66657d984bb77ba83863dd4607704594a6c610bc)

---

# Findings Summary

| ID     | Title                                                  | Severity      | Status |
| ------ | ------------------------------------------------------ | ------------- | ------ |
| [I-01] | Missing `_beforeApprove` override                      | Informational |        |
| [I-02] | Duplicated access control check in `setYieldRecipient` | Informational |        |
| [I-03] | Inconsistencies in imported submodules                 | Informational |        |

# Security & Economic Findings

No security or economic-impacting issues were identified.

# Informational & Gas Optimizations

## [I-01] Missing `_beforeApprove` override

The `MUSD` contract overrides `_beforeWrap`, `_beforeUnwrap`, and `_beforeTransfer` to include a `_requireNotPaused`
check for the corresponding operations.

For consistency with the existing blacklisting logic, consider also overriding `_beforeApprove` to include the same
check.

## [I-02] Duplicated access control check in `setYieldRecipient`

The `setYieldRecipient` function includes an access control check to ensure the caller has the
`YIELD_RECIPIENT_MANAGER_ROLE` role. However, since `setYieldRecipient` immediately calls `claimYield`, which also
performs the same validation, the check is duplicated.

Consider overriding `setYieldRecipient` to remove the redundant `YIELD_RECIPIENT_MANAGER_ROLE` check.

## [I-03] Inconsistencies in imported submodules

The reviewed commit in the MUSD repository imports the `evm-m-extensions` and `common` dependencies as submodules.
However, their commit hashes do not match the latest commits in the relevant repositories' `main` branches.

Consider updating the submodule versions to ensure consistency between the repositories.

Additionally, the MUSD repository references the `common` dependency as both `lib/common/` and
`lib/evm-m-extensions/lib/common/` throughout the codebase.

Consider using a single import path throughout the repository and/or introducing an import remapping alias. If
feasible, consider removing the `common` submodule from the MUSD repository.
