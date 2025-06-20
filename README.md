# Ripple Liquid Mining Protocol

A liquid mining smart contract built on the Stacks blockchain that allows users to stake STX tokens while maintaining liquidity through liquid tokens that can be traded or used in DeFi protocols.

## 🌊 Overview

Ripple Protocol introduces liquid mining to the Stacks ecosystem, enabling users to:
- Stake STX tokens and receive liquid tokens representing their stake
- Earn block-based mining rewards on staked assets
- Maintain liquidity through tradeable liquid tokens
- Unstake flexibly without lock-up periods

## ✨ Features

### Core Functionality
- **Liquid Staking**: 1:1 ratio between staked STX and liquid tokens
- **Flexible Rewards**: Block-based reward system with configurable rates
- **Instant Liquidity**: Liquid tokens can be traded or used in other protocols
- **Partial Unstaking**: Unstake any amount using liquid tokens
- **Compound Staking**: Add more stake to existing positions

### Advanced Features
- **Multiple Mining Pools**: Support for different pools with varying reward multipliers
- **Emergency Unstaking**: Quick exit option (forfeits pending rewards)
- **Real-time Calculations**: Dynamic reward calculations based on block height
- **Admin Controls**: Configurable parameters and emergency pause functionality

## 🚀 Quick Start

### Prerequisites
- Stacks CLI installed
- Clarinet for local development and testing
- STX tokens for staking

### Deployment

1. Clone the repository:
```bash
git clone <repository-url>
cd ripple-liquid-mining
```

2. Deploy using Clarinet:
```bash
clarinet deploy --network testnet
```

3. Initialize the contract:
```clarity
(contract-call? .ripple initialize)
```

## 📖 Usage

### Staking STX

Stake STX tokens and receive liquid tokens:

```clarity
;; Stake 10 STX (10,000,000 microSTX)
(contract-call? .ripple stake u10000000)
```

### Adding to Existing Stake

Add more STX to your existing stake position:

```clarity
;; Add 5 more STX to existing stake
(contract-call? .ripple add-stake u5000000)
```

### Claiming Rewards

Claim accumulated mining rewards:

```clarity
;; Claim all pending rewards
(contract-call? .ripple claim-rewards)
```

### Unstaking

Unstake using liquid tokens (partial or full):

```clarity
;; Unstake 3 STX worth of liquid tokens
(contract-call? .ripple unstake u3000000)
```

### Emergency Unstaking

Quick unstake that forfeits pending rewards:

```clarity
;; Emergency unstake (forfeits rewards)
(contract-call? .ripple emergency-unstake)
```

## 🔍 Contract Interface

### Read-Only Functions

| Function | Description | Returns |
|----------|-------------|---------|
| `get-user-stake(user)` | Get user's stake information | Stake details or none |
| `get-total-staked()` | Get total STX staked in protocol | uint |
| `get-reward-rate()` | Get current reward rate | uint |
| `calculate-pending-rewards(user)` | Calculate user's pending rewards | uint |
| `get-liquid-token-balance(user)` | Get user's liquid token balance | uint |
| `get-contract-info()` | Get contract state information | Contract info object |

### Public Functions

| Function | Description | Parameters |
|----------|-------------|------------|
| `stake(amount)` | Stake STX and receive liquid tokens | amount: uint |
| `add-stake(amount)` | Add more STX to existing stake | amount: uint |
| `claim-rewards()` | Claim pending mining rewards | none |
| `unstake(amount)` | Unstake using liquid tokens | amount: uint |
| `emergency-unstake()` | Emergency unstake (forfeits rewards) | none |

### Admin Functions

| Function | Description | Access |
|----------|-------------|---------|
| `set-reward-rate(rate)` | Update reward rate | Owner only |
| `set-minimum-stake(amount)` | Update minimum stake amount | Owner only |
| `pause-contract()` | Pause contract operations | Owner only |
| `unpause-contract()` | Resume contract operations | Owner only |
| `create-pool(id, multiplier)` | Create new mining pool | Owner only |

## ⚙️ Configuration

### Default Parameters

- **Minimum Stake**: 1 STX (1,000,000 microSTX)
- **Reward Rate**: 0.1% per 1000 blocks
- **Liquid Token Ratio**: 1:1 with staked STX

### Error Codes

| Code | Description |
|------|-------------|
| u100 | Owner only operation |
| u101 | Not authorized |
| u102 | Insufficient balance |
| u103 | Invalid amount |
| u104 | Pool not found |
| u105 | Already staked |
| u106 | Not staked |
| u107 | Below minimum stake |

## 🔒 Security Features

- **Authorization Checks**: Proper access control for admin functions
- **Input Validation**: All amounts and parameters validated
- **Emergency Controls**: Pause functionality for security incidents
- **Error Handling**: Comprehensive error codes and handling
- **Overflow Protection**: Safe arithmetic operations

## 📊 Tokenomics

### Liquid Token (ripple-liquid-token)

- **Supply**: Backed 1:1 by staked STX
- **Utility**: Represents claim on staked STX + accrued rewards
- **Transferability**: Fully transferable and tradeable
- **Composability**: Can be used in other DeFi protocols

### Reward Distribution

- Rewards calculated per block based on stake amount
- Configurable reward rate (default: 0.1% per 1000 blocks)
- Rewards distributed in STX tokens
- Compound reward potential through re-staking

## 🧪 Testing

Run the test suite using Clarinet:

```bash
clarinet test
```

### Test Coverage

- Staking and unstaking flows
- Reward calculation accuracy
- Edge cases and error conditions
- Admin function security
- Emergency scenarios

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request


## 🔗 Links

- [Stacks Documentation](https://docs.stacks.co/)
- [Clarity Language Reference](https://docs.stacks.co/clarity/)
- [Clarinet Documentation](https://github.com/hirosystems/clarinet)

## ⚠️ Disclaimer

This smart contract is provided as-is. Users should conduct their own security audits and due diligence before deploying to mainnet or staking significant amounts. The developers are not responsible for any loss of funds.

## 📞 Support

For questions, issues, or contributions:
- Open an issue on GitHub
- Join our community discussions
- Review the documentation

---

**Ripple Protocol** - Bringing liquid mining to the Stacks ecosystem 🌊