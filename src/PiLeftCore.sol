// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IPiLeftPair} from "./interfaces/IPiLeftPair.sol";
import {PiLeftLibrary} from "./PiLeftLibrary.sol";
import {IUltraVerifier} from "./interfaces/IUltraVerifier.sol";

error InvalidProof();

contract PiLeftCore {
    using ECDSA for bytes32;

    struct ProofPerUser {
        bytes proof;
        uint256 timestamp;
    }

    struct SwapData {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOutMin;
        PermitData params;
    }

    struct MintData {
        address token1;
        address token2;
        uint256 amount1;
        uint256 amount2;
        PermitData params;
        PermitData params2;
    }

    struct BurnData {
        address token1;
        address token2;
        uint256 amount;
        PermitData params;
    }

    struct PermitData {
        address owner;
        address spender;
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    // user address => nonce
    mapping(address => uint256) public nonces;

    // user address => zk proof (For now there is one proof per user)
    mapping(address => ProofPerUser) public proofs;

    // Uniswap V2 style pair contracts
    mapping(address => mapping(address => address)) public pairs;

    IUltraVerifier public zkVerifier;

    address public factoryAddress;

    function setFactory(address fac) public {
        factoryAddress = fac;
    }

    event SetProof(uint256 indexed timeStamp, address indexed initiator);
    event SwapExecuted(uint256 indexed timeStamp, address indexed initiator, uint256 amountIn, uint256 amountOut);
    event MintExecuted(uint256 indexed timeStamp, address indexed initiator, uint256 amount1, uint256 amount2);
    event BurnExecuted(uint256 indexed timeStamp, address indexed initiator, uint256 amount);

    function setVerifier (address _zkVerifier) public {
        zkVerifier = IUltraVerifier(_zkVerifier);
    }

    function initiateSwap(bytes calldata proof) external {
        proofs[msg.sender] = ProofPerUser(proof, block.timestamp);
        emit SetProof(block.timestamp, msg.sender);
    }

    // swap from PiLeftPair.
    // tokenIn = token1 and tokenOut = token2
    // amountIn = amount1 and amountOutMin = amount2
    function executeSwap(
        uint256 amount1,
        uint256 amount2,
        address token1,
        address token2,
        uint256 operationType,
        PermitData calldata params,
        bytes32 proofHash
    ) external {
        ProofPerUser memory userProof = proofs[msg.sender];
        require(userProof.proof.length > 0, "No proof found");
        require(userProof.timestamp < block.timestamp, "Same block execution");
        require(operationType == 0, "Not a simple swap");

        // Verify the proof with the zkVerifier
        bytes32[] memory publicInputs = new bytes32[](7);
        publicInputs[0] = bytes32(nonces[msg.sender]);
        publicInputs[1] = bytes32(uint256(uint160(msg.sender)));
        publicInputs[2] = bytes32(amount1);
        publicInputs[3] = bytes32(amount2);
        publicInputs[4] = bytes32(uint256(uint160(token1)));
        publicInputs[5] = bytes32(uint256(uint160(token2)));
        publicInputs[6] = proofHash;

        bool verified = zkVerifier.verify(userProof.proof, publicInputs);

        if (!verified) {
            revert InvalidProof();
        }

        // Perform the swap if the proof is valid
        address pair = PiLeftLibrary.pairFor(factoryAddress, token1, token2);
        // Should be on a try/catch in order to prevent denials.
        IERC20Permit(token1).permit(
            params.owner, params.spender, params.value, params.deadline, params.v, params.r, params.s
        );
        IERC20(token1).transferFrom(msg.sender, pair, amount1);
        uint256 amountOut = IPiLeftPair(pair).swap(amount1, amount2, msg.sender, "");
        require(amountOut >= amount2, "Insufficient output amount");
        emit SwapExecuted(block.timestamp, msg.sender, amount1, amount2);

        nonces[msg.sender]++;
    }

    function executeMint(
        uint256 amount1,
        uint256 amount2,
        address token1,
        address token2,
        uint256 operationType,
        PermitData calldata params,
        PermitData calldata params2,
        bytes32 proofHash
    ) external {
        ProofPerUser memory userProof = proofs[msg.sender];
        require(userProof.proof.length > 0, "No proof found");
        require(userProof.timestamp < block.timestamp, "Same block execution");
        require(operationType == 1, "Not a mint operation");

        // Verify the proof with the zkVerifier
        bytes32[] memory publicInputs = new bytes32[](7);
        publicInputs[0] = bytes32(nonces[msg.sender]);
        publicInputs[1] = bytes32(uint256(uint160(msg.sender)));
        publicInputs[2] = bytes32(amount1);
        publicInputs[3] = bytes32(amount2);
        publicInputs[4] = bytes32(uint256(uint160(token1)));
        publicInputs[5] = bytes32(uint256(uint160(token2)));
        publicInputs[6] = proofHash;

        bool verified = zkVerifier.verify(userProof.proof, publicInputs);

        if (!verified) {
            revert InvalidProof();
        }

        address pair = PiLeftLibrary.pairFor(factoryAddress, token1, token2);
        IERC20Permit(token1).permit(
            params.owner, params.spender, params.value, params.deadline, params.v, params.r, params.s
        );
        IERC20(token1).transferFrom(msg.sender, pair, amount1);
        IERC20Permit(token2).permit(
            params2.owner, params2.spender, params2.value, params2.deadline, params2.v, params2.r, params2.s
        );
        IERC20(token2).transferFrom(msg.sender, pair, amount2);
        IPiLeftPair(pair).mint(msg.sender);
        emit MintExecuted(block.timestamp, msg.sender, amount1, amount2);

        nonces[msg.sender]++;
    }

    // amount2 = 0 in burn, amount1 = LP tokens to burn
    function executeBurn(
        uint256 amount1,
        uint256 amount2,
        address token1,
        address token2,
        uint256 operationType,
        PermitData calldata params,
        bytes32 proofHash
    ) external {
        ProofPerUser memory userProof = proofs[msg.sender];
        require(userProof.proof.length > 0, "No proof found");
        require(userProof.timestamp < block.timestamp, "Same block execution");
        require(operationType == 2, "Not a mint operation");

        // Verify the proof with the zkVerifier
        bytes32[] memory publicInputs = new bytes32[](7);
        publicInputs[0] = bytes32(nonces[msg.sender]);
        publicInputs[1] = bytes32(uint256(uint160(msg.sender)));
        publicInputs[2] = bytes32(amount1);
        publicInputs[3] = bytes32(amount2);
        publicInputs[4] = bytes32(uint256(uint160(token1)));
        publicInputs[5] = bytes32(uint256(uint160(token2)));
        publicInputs[6] = proofHash;

        bool verified = zkVerifier.verify(userProof.proof, publicInputs);

        if (!verified) {
            revert InvalidProof();
        }

        address pair = PiLeftLibrary.pairFor(factoryAddress, token1, token2);
        IERC20Permit(pair).permit(
            params.owner, params.spender, params.value, params.deadline, params.v, params.r, params.s
        );
        IERC20(pair).transferFrom(msg.sender, pair, amount1);
        IPiLeftPair(pair).burn(msg.sender);

        emit BurnExecuted(block.timestamp, msg.sender, amount1);
        nonces[msg.sender]++;
    }
}
