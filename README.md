# Task1\* & Task2 Liquidity Tests

## Prerequisites

- [Foundry](https://github.com/foundry-rs/foundry) (`forge` CLI)
- BSC RPC URL (archive or public node with fork support)

### Quick start

1. Clone reo & setup env:

   ```bash
   git clone <repo>
   cd <repo>
   forge install
   ```

2. Add BSC RPC URL in .env:

```cp .env.example .env
# Open it .env and substitute:
# # BSC_RNC_URL=https://YOUR_BSC_RPC_URL
```

3. Try test:
   `forge test -vv`
