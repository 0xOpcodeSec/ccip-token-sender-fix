# CCIP Token Sender (L2 Gas Fix)
<img width="1916" height="1018" alt="Ekran görüntüsü 2026-11-16 005819" src="https://github.com/user-attachments/assets/90b4b755-62b2-434d-a99b-4054febda804" />

A simple smart contract to send USDC cross-chain via Chainlink CCIP (Ethereum Sepolia -> Base Sepolia), with the fix for L2 out-of-gas errors.

<img width="1424" height="771" alt="Ekran görüntüsü 2026-11-16 005707" src="https://github.com/user-attachments/assets/558e1b43-bace-4ee6-8919-0a52263c34ef" />

## ⚠️ The Problem (`state = 3` / Out of Gas)
<img width="1537" height="2079" alt="image" src="https://github.com/user-attachments/assets/afb75c0b-a0c4-4633-8a72-b9959e6f3040" />

If you use the default Chainlink example where `extraArgs` gas limit is set to `0`:
```solidity
extraArgs: Client._argsToBytes(
    Client.EVMExtraArgsV1({gasLimit: 0})
),
💡 The Fix

Instead of relying on the default 0 gas limit, we explicitly set gasLimit to 200_000 inside EVMExtraArgsV1:

extraArgs: Client._argsToBytes(
    Client.EVMExtraArgsV1({gasLimit: 200_000})
),


This ensures enough execution gas is allocated for the destination token pool logic on the L2 chain, completely resolving the state = 3 error.

📍 Deployed Addresses (Sepolia)

CCIPTokenSender: 0x8Fe9b40fCAe5cD8D73156E3D74E3eC40e3008B5f

CCIP Router: 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59

USDC: 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238

LINK: 0x779877A7B0D9E8603169DdbD7836e478b4624789
