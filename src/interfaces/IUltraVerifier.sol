// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IUltraVerifier {
    function verify(bytes calldata _proof, bytes32[] calldata _publicInputs) external view returns (bool);
}