## MUSD

<img width="750" height="750" alt="mUSD-hero" src="https://github.com/user-attachments/assets/4e163205-dcd0-4d7a-939c-a8de87e283d8" />

This M extension is derived from [MYieldToOne](https://github.com/m0-foundation/evm-m-extensions/blob/main/src/projects/yieldToOne/MYieldToOne.sol), an upgradeable ERC20 token contract designed to wrap $M into a non-rebasing token, where all accrued $M yield is claimable by a single designated recipient.

Additionally, **MUSD** includes the following functionality:

- Pausing logic.
- Ability to force transfers from frozen accounts.
- Restrictions on who can trigger claiming of yield for `claimRecipient`.

## MUSD System Design

<img width="4702" height="5423" alt="SystemDesign" src="https://github.com/user-attachments/assets/4e258277-b791-42a1-9296-ae2923abca58" />

### 🧩 M Extensions Framework

**M Extension Framework** is a modular templates of ERC-20 **stablecoin extensions** that wrap the yield-bearing `$M` token into non-rebasing variants for improved composability within DeFi. Each extension manages yield distribution differently and integrates with a central **SwapFacility** contract that acts as the exclusive entry point for wrapping (swapping into extension) and unwrapping(swapping out of extension).

All contracts are deployed behind transparent upgradeable proxies (by default).

**MUSD** is derived from **MYieldToOne**.

**`MYieldToOne`** core features:

- All yield goes to a single configurable `yieldRecipient`
- Includes a freeze list enforced on all user actions
- Handles loss of `$M` earner status gracefully

---

### 🔁 SwapFacility

The `SwapFacility` contract acts as the **exclusive router** for all wrapping and swapping operations involving `$M` and its extensions.

#### Key Functions

- `swap()` – Switch between extensions by unwrapping and re-wrapping
- `swapInM()`, `swapInMWithPermit()` – Accept `$M` and wrap into the selected extension
- `swapOutM()` – Unwrap to `$M` (restricted to whitelisted addresses only)

> All actions are subject to the rules defined by each extension (e.g., blacklists, whitelists)

## Development

### Installation

You may have to install the following tools to use this repository:

- [Foundry](https://github.com/foundry-rs/foundry) to compile and test contracts
- [lcov](https://github.com/linux-test-project/lcov) to generate the code coverage report
- [slither](https://github.com/crytic/slither) to static analyze contracts

Install dependencies:

```bash
npm i
```

### Env

Copy `.env.example` and write down the env variables needed to run this project.

```bash
cp .env.example .env
```

### Compile

Run the following command to compile the contracts:

```bash
npm run compile
```

### Coverage

Forge is used for coverage, run it with:

```bash
npm run coverage
```

You can then consult the report by opening `coverage/index.html`:

```bash
open coverage/index.html
```

### Test

To run all tests:

```bash
npm test
```

Run test that matches a test contract:

```bash
forge test --mc <test-contract-name>
```

Test a specific test case:

```bash
forge test --mt <test-case-name>
```

To run slither:

```bash
npm run slither
```

## Deployment

### Build

To compile the contracts for production, run:

```bash
npm run build
```

### Deploy

MUSD is deployed via CREATE3 behind an Open Zeppelin's transparent upgradeable proxy.

#### Local

Open a new terminal window and run [anvil](https://book.getfoundry.sh/reference/anvil/) to start a local fork:

```bash
anvil --fork-url ${ETHEREUM_RPC_URL}
```

Deploy the contracts by running:

```bash
npm run deploy-local
```

#### Sepolia

To deploy to the Sepolia testnet, run:

```bash
npm run deploy-sepolia
```

To deploy to Linea Sepolia testnet, run:

```bash
npm run deploy-linea-sepolia
```

#### Mainnet

To deploy to Ethereum Mainnet, run:

```bash
npm run deploy-mainnet
```

To deploy to Linea Mainnet, run:

```bash
npm run deploy-linea
```

### Deployments

#### Mainnet

| Network  | Implementation                                                                                                           | Proxy                                                                                                                    | Proxy Admin                                                                                                              |
| -------- | ------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------ |
| --       |
| Ethereum | [0x37A309611E1d278cDdC341E479957Ec8Bc6256CE](https://etherscan.io/address/0x37A309611E1d278cDdC341E479957Ec8Bc6256CE)    | [0xacA92E438df0B2401fF60dA7E4337B687a2435DA](https://etherscan.io/address/0xacA92E438df0B2401fF60dA7E4337B687a2435DA)    | [0x685E7F8C9414bfa716b254b349153e2317929ac9](https://etherscan.io/address/0x685E7F8C9414bfa716b254b349153e2317929ac9)    |
| Linea    | [0x58a3A9C561591bab0dd11110EcA755EA455f1841](https://lineascan.build/address/0x58a3A9C561591bab0dd11110EcA755EA455f1841) | [0xacA92E438df0B2401fF60dA7E4337B687a2435DA](https://lineascan.build/address/0xacA92E438df0B2401fF60dA7E4337B687a2435DA) | [0x685E7F8C9414bfa716b254b349153e2317929ac9](https://lineascan.build/address/0x685E7F8C9414bfa716b254b349153e2317929ac9) |
| BNB |[0x23d8162e084aa33d8ef6fcc0ab33f4028a53ee79](https://bscscan.com/address/0x58a3A9C561591bab0dd11110EcA755EA455f1841) | [0xacA92E438df0B2401fF60dA7E4337B687a2435DA](https://bscscan.com/address/0xacA92E438df0B2401fF60dA7E4337B687a2435DA) | [0x685E7F8C9414bfa716b254b349153e2317929ac9](https://bscscan.com/address/0x685E7F8C9414bfa716b254b349153e2317929ac9) |

#### Sepolia

| Network | MUSD (Governance aware)                                                                                                       | MUSD (Governanceless)                                                                                                         |
| ------- | ----------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| Sepolia | [0x35f35B91A16fe5b3869f4a2A9c79782DF4443316](https://sepolia.etherscan.io/address/0x35f35b91a16fe5b3869f4a2a9c79782df4443316) | [0x6539fa0DfA46Ad0Fac8F7694e7521f233fa0926C](https://sepolia.etherscan.io/address/0x6539fa0dfa46ad0fac8f7694e7521f233fa0926c) |
