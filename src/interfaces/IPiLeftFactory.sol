// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IPiLeftFactory {
    function pairs(address, address) external pure returns (address);

    function createPair(address, address) external returns (address);
}