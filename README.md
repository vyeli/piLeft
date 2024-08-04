
# ZK-Powered Fragmented Swap Exchange

## Introduction

This project introduces a novel decentralized exchange (DEX) that leverages the power of Zero-Knowledge (ZK) proofs using Noir, specifically targeting the NAztec (Noir on Scroll) ecosystem. Our DEX implements a unique fragmented swap mechanism, enhancing privacy and security in DeFi transactions.

Key features:
- Privacy-preserving operation data using ZK proofs
- Two-step transaction process for enhanced security
- Seamless integration with Scroll's L2 scaling solution
- Designed to meet Aztec Noir bounty requirements

By utilizing Noir for ZK proof generation and verification, this project aims to push the boundaries of what's possible in DeFi, offering users a blend of privacy, security, and efficiency. Our implementation specifically targets the bounties offered by N**Aztec, showcasing the potential of ZK technology in creating next-generation DeFi applications on Scroll.

## Overview

The ZK-Powered Fragmented Swap Exchange operates on a two-step process for each swap:

1. **Proof Submission**: Users generate and upload a ZK proof to initialize their intent to swap.
2. **Swap Execution**: Users provide public parameters, the contract verifies the proof, and executes the swap if valid.

This approach not only enhances privacy by keeping sensitive details off-chain until execution but also provides an additional layer of security against front-running and other common DeFi vulnerabilities.


Architecture
1. **Noir Circuits**: Define the logic for ZK proof generation.
2. **Smart Contracts**: Handle proof verification and swap execution.
3. **Frontend**: User interface for interacting with the exchange.

## Swap Process

1. **Initiate Swap**:
- User generates a ZK proof locally.
- Proof is uploaded to the smart contract.

2. **Execute Swap**:
- User sends a transaction with public parameters.
- Smart contract verifies the proof.
- If valid, the swap is executed.

## Security Considerations

- ZK proofs ensure privacy of sensitive transaction details until the execution of the operation.
- Two-step process prevents front-running and enhances security.
- Smart contract audits are crucial before mainnet deployment.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Disclaimer

This software is in beta. Use at your own risk.

## Contact

For any queries, please open an issue in the GitHub repository.

## Installation

### Foundry (Smart Contracts)

1. Install Foundry if you haven't already:
   ```
   curl -L https://foundry.paradigm.xyz | bash
   ```

2. Install dependencies:
   ```
   forge install
   ```

3. Build the project:
   ```
   forge build
   ```

### Frontend

1. Install Node.js dependencies:
   ```
   npm install
   ```

### NAztec - Noir on Scroll

1. Install Noirup:
   ```
   curl -L https://raw.githubusercontent.com/noir-lang/noirup/main/install | bash
   ```

2. Install the latest version of Noir:
   ```
   noirup
   ```

3. Compile the Noir circuit:
   ```
   nargo compile
   ```

### Smart Contracts

Deploy contracts using Foundry:
```
forge script script/DeployContracts.s.sol --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Frontend

Start the development server:
```
npm run dev
```

Open your browser and navigate to `http://localhost:3000`
> [!CAUTION]
> As of right now, the front-end has the contracts hardcoded.

### Generating ZK Proofs

Navigate to the Noir circuit directory and generate a proof:
```
cd circuits
nargo prove my_proof
```
## Deployed contract addresses

piLeftCore : https://sepolia.scrollscan.com/address/0xd33ccb833C42431b14687228377872C683244502

piLeftPair1 : https://sepolia.scrollscan.com/address/0xa30b0c294a2df702760eaf293a4e9a97eb36d93f#code

piLeftFactory : https://sepolia.scrollscan.com/address/0x0bDB1f74AeE623ce9068eE828F9660aFACcD9A61

testToken1 : https://sepolia.scrollscan.com/address/0x6F6D6d5f9729a5083AFd01ecE58E43002633D493

testToken2 : https://sepolia.scrollscan.com/address/0x0d475b30d699E755Be692D8a5a33FF302bcc4827

noirVerifier : https://sepolia.scrollscan.com/address/0xb4da7f797d2d6c6F6B5C70db78DeC8c269816d48
