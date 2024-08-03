// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IPiLeftCallee {
    function PiLeftCall(
        address sender,
        uint256 amount0Out,
        uint256 amount1Out,
        bytes calldata data
    ) external;
}
