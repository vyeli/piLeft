// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IPiLeftPair} from "./interfaces/IPiLeftPair.sol";
import {PiLeftLibrary} from "./PiLeftLibrary.sol";
contract FragmentedSwapExchange {
    using ECDSA for bytes32;

    struct EncryptedSwap {
        bytes encryptedData;
        address initiator;
        uint256 timestamp;
        uint256 operation;
    }
    struct PermitData{
        address owner;
        address spender;
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
    mapping(bytes32 => EncryptedSwap) public encryptedSwaps;
    address public factoryAddress;
    // Uniswap V2 style pair contracts
    // 
    mapping(address => mapping(address => address)) public pairs;
    function setFactory(address fac) public {
        factoryAddress = fac;
    }

    event SwapInitiated(bytes32 indexed swapId, address indexed initiator);
    event SwapExecuted(bytes32 indexed swapId, address indexed initiator, uint256 amountIn, uint256 amountOut);

    function initiateSwap(bytes memory encryptedData, uint256 operation) external {
        bytes32 swapId = keccak256(abi.encode(encryptedData, msg.sender, block.timestamp,operation));
        encryptedSwaps[swapId] = EncryptedSwap(encryptedData, msg.sender, block.timestamp,operation);
        emit SwapInitiated(swapId, msg.sender);
    }
    // swap from PiLeftPair.
    function executeSwap(bytes32 swapId, bytes memory decryptionKey) external {
        EncryptedSwap storage swap = encryptedSwaps[swapId];
        require(swap.initiator != address(0), "Swap does not exist");
        require(swap.initiator == msg.sender, "Only initiator can execute swap");
        require(swap.timestamp < block.timestamp,"Same block execution");
        require(swap.operation == 0, "Not a simple swap");
        // Decrypt data (implement decryption logic)
        (address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOutMin, PermitData memory params) = decryptSwapData(swap.encryptedData, decryptionKey);

        // Perform the swap (simplified, you'd need to implement full Uniswap V2 logic)
        address pair = PiLeftLibrary.pairFor(factoryAddress,tokenIn,tokenOut);
        // Should be on a try/catch in order to prevent denials.
        IERC20Permit(tokenIn).permit(params.owner,params.spender,params.value,params.deadline,params.v,params.r,params.s);
        IERC20(tokenIn).transferFrom(msg.sender, pair, amountIn);
        uint256 amountOut = IPiLeftPair(pair).swap(amountIn, amountOutMin, msg.sender,"");
        require(amountOut >= amountOutMin, "Insufficient output amount");
        delete encryptedSwaps[swapId];
        emit SwapExecuted(swapId, msg.sender, amountIn, amountOut);
    }

    function executeMint(bytes32 swapId, bytes memory decryptionKey) external{
        EncryptedSwap storage swap = encryptedSwaps[swapId];
        require(swap.initiator != address(0), "Swap does not exist");
        require(swap.initiator == msg.sender, "Only initiator can execute swap");
        require(swap.timestamp < block.timestamp,"Same block execution");
        require(swap.operation == 1, "Not a mint operation");
        (address token1, address token2, uint256 amount1, uint256 amount2, PermitData memory params,PermitData memory params2) = decryptMintData(swap.encryptedData,decryptionKey);
        address pair = PiLeftLibrary.pairFor(factoryAddress,token1,token2);
        IERC20Permit(token1).permit(params.owner,params.spender,params.value,params.deadline,params.v,params.r,params.s);
        IERC20(token1).transferFrom(msg.sender, pair, amount1);
        IERC20Permit(token2).permit(params2.owner,params2.spender,params2.value,params2.deadline,params2.v,params2.r,params2.s);
        IERC20(token2).transferFrom(msg.sender, pair, amount2);
        IPiLeftPair(pair).mint(swap.initiator);

    }
    function executeBurn(bytes32 swapId, bytes memory decryptionKey) external{
        EncryptedSwap storage swap = encryptedSwaps[swapId];
        require(swap.initiator != address(0), "Swap does not exist");
        require(swap.initiator == msg.sender, "Only initiator can execute swap");
        require(swap.timestamp < block.timestamp,"Same block execution");
        require(swap.operation == 2, "Not a burn operation");
    }

    // Implement decryption logic
    function decryptSwapData(bytes memory encryptedData, bytes memory decryptionKey) internal pure returns (address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOutMin,PermitData memory params) {
        // Implement your decryption logic here
    }
    function decryptMintData(bytes memory encryptedData, bytes memory decryptionKey) internal pure returns(address token1, address token2, uint256 amount1,uint256 amount2, PermitData memory params,PermitData memory params2){
        // Implement your decryption logic here
    }

    // Other necessary functions (create pair, add liquidity, etc.)
}