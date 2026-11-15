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



