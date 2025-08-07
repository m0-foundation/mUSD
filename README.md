## MUSD

This M extension is derived from [MYieldToOne](), an upgradeable ERC20 token contract designed to wrap $M into a non-rebasing token, where all accrued $M yield is claimable by a single designated recipient.

Additionally, **MUSD** includes the following functionality:

- Pausing logic
- Ability to force transfers from blacklisted accounts
- Restrictions on who can trigger claiming of yield for `claimRecipient` .

## MUSD System Design

### 🧩 M Extensions Framework 

**M Extension Framework** is a modular templates of ERC-20 **stablecoin extensions** that wrap the yield-bearing `$M` token into non-rebasing variants for improved composability within DeFi. Each extension manages yield distribution differently and integrates with a central **SwapFacility** contract that acts as the exclusive entry point for wrapping (swapping into extension) and unwrapping(swapping out of extension).

All contracts are deployed behind transparent upgradeable proxies (by default).

- **`MYieldToOne`**

  - All yield goes to a single configurable `yieldRecipient`
  - Includes a blacklist enforced on all user actions
  - Handles loss of `$M` earner status gracefully

---

### 🔁 SwapFacility

The `SwapFacility` contract acts as the **exclusive router** for all wrapping and swapping operations involving `$M` and its extensions.

#### Key Functions

- `swap()` – Switch between extensions by unwrapping and re-wrapping
- `swapInM()`, `swapInMWithPermit()` – Accept `$M` and wrap into the selected extension
- `swapOutM()` – Unwrap to `$M` (restricted to whitelisted addresses only)

> All actions are subject to the rules defined by each extension (e.g., blacklists, whitelists)
