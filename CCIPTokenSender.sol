// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
// Deployed on Sepolia Test Network: 0x8Fe9b40fCAe5cD8D73156E3D74E3eC40e3008B5f


import {IRouterClient} from "@chainlink/contracts@1.3.0/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts@1.3.0/src/v0.8/ccip/libraries/Client.sol";
import {IERC20} from "@openzeppelin/contracts@5.2.0/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts@5.2.0/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts@5.2.0/access/Ownable.sol";

// Token Approvals: Before users can call transferTokens(address _receiver, uint256 _amount), they must approve CCIPTokenSender to spend their USDC tokens.
// Contract Funding: CCIPTokenSender must be funded with LINK tokens to pay the CCIP fees.
// Chain Selectors: The destination chain selector is a unique identifier for Base Sepolia. Different destinations require different selectors
// Fee Management: CCIP fees are paid in LINK tokens (or native tokens) and vary based on the destination chain and current network conditions

contract CCIPTokenSender is Ownable {

    using SafeERC20 for IERC20;

    error CCIPTokenSender__InsufficientBalance(IERC20 token, uint256 currentBalance, uint256 requiredAmount);
    error CCIPTokenSender__NothingToWithdraw();

    // https://docs.chain.link/ccip/supported-networks/v1_2_0/testnet#ethereum-testnet-sepolia
    // Ethereum testnet sepolia (Router) = 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59
    IRouterClient private constant CCIP_ROUTER = IRouterClient(0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59);
    
    // https://docs.chain.link/resources/link-token-contracts#ethereum-testnet-sepolia
    // Ethereum testnet sepolia = 0x779877A7B0D9E8603169DdbD7836e478b4624789
    IERC20 private constant LINK_TOKEN = IERC20(0x779877A7B0D9E8603169DdbD7836e478b4624789);

    // https://developers.circle.com/stablecoins/docs/usdc-on-test-networks
    // Ethereum testnet sepolia = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238
    IERC20 private constant USDC_TOKEN = IERC20(0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238);

    // https://docs.chain.link/ccip/directory/testnet/chain/ethereum-testnet-sepolia-base-1
    // Base testnet sepolia (chain selector) = 10344971235874465080
    uint64 private constant DESTINATION_CHAIN_SELECTOR = 10344971235874465080;

    event USDCTransferred(bytes32 messageId, uint64 indexed destinationChainSelector, address indexed receiver, uint256 amount, uint256 ccipFee);

    constructor() Ownable(msg.sender) {
    }

    function transferTokens(address _receiver, uint256 _amount) external returns (bytes32 messageId) {

        if (_amount > USDC_TOKEN.balanceOf(msg.sender)) {
            revert CCIPTokenSender__InsufficientBalance(USDC_TOKEN, USDC_TOKEN.balanceOf(msg.sender), _amount);
        }

        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);

        Client.EVMTokenAmount memory tokenAmount = Client.EVMTokenAmount({
                                                token: address(USDC_TOKEN),
                                                amount: _amount
                                            });

        tokenAmounts[0] = tokenAmount;

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
                                                receiver: abi.encode(_receiver),
                                                data: "",
                                                tokenAmounts: tokenAmounts,
                                                extraArgs: Client._argsToBytes(
                                                    Client.EVMExtraArgsV1(200_000) // Setting gasLimit to 200,000 to prevent destination L2 execution failure (state = 3)
                                                ),
                                                feeToken: address(LINK_TOKEN)
                                            });

        uint256 ccipFee = CCIP_ROUTER.getFee(DESTINATION_CHAIN_SELECTOR, message);

        if (ccipFee > LINK_TOKEN.balanceOf(address(this))) {
            revert CCIPTokenSender__InsufficientBalance(LINK_TOKEN, LINK_TOKEN.balanceOf(address(this)), ccipFee);
        }

        LINK_TOKEN.approve(address(CCIP_ROUTER), ccipFee);

        USDC_TOKEN.safeTransferFrom(msg.sender, address(this), _amount);

        USDC_TOKEN.approve(address(CCIP_ROUTER), _amount);

        messageId = CCIP_ROUTER.ccipSend(DESTINATION_CHAIN_SELECTOR, message);

        emit USDCTransferred(messageId, DESTINATION_CHAIN_SELECTOR, _receiver, _amount, ccipFee);
    }

    function withdrawToken(address _beneficiary) public onlyOwner {
        uint256 amount = IERC20(USDC_TOKEN).balanceOf(address(this));

        if (amount == 0) 
            revert CCIPTokenSender__NothingToWithdraw();

        IERC20(USDC_TOKEN).transfer(_beneficiary, amount);
    }
}