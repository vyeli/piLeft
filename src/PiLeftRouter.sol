// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "./interfaces/IPiLeftFactory.sol";
import "./interfaces/IPiLeftPair.sol";
import "./PiLeftLibrary.sol";

contract PiLeftRouter {
    error ExcessiveInputAmount();
    error InsufficientAAmount();
    error InsufficientBAmount();
    error InsufficientOutputAmount();
    error SafeTransferFailed();

    IPiLeftFactory factory;

    constructor(address factoryAddress) {
        factory = IPiLeftFactory(factoryAddress);
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to
    )
        public
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        if (factory.pairs(tokenA, tokenB) == address(0)) {
            factory.createPair(tokenA, tokenB);
        }

        (amountA, amountB) = _calculateLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin
        );
        address pairAddress = PiLeftLibrary.pairFor(
            address(factory),
            tokenA,
            tokenB
        );
        _safeTransferFrom(tokenA, msg.sender, pairAddress, amountA);
        _safeTransferFrom(tokenB, msg.sender, pairAddress, amountB);
        liquidity = IPiLeftPair(pairAddress).mint(to);
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to
    ) public returns (uint256 amountA, uint256 amountB) {
        address pair = PiLeftLibrary.pairFor(
            address(factory),
            tokenA,
            tokenB
        );
        IPiLeftPair(pair).transferFrom(msg.sender, pair, liquidity);
        (amountA, amountB) = IPiLeftPair(pair).burn(to);
        if (amountA < amountAMin) revert InsufficientAAmount();
        if (amountA < amountBMin) revert InsufficientBAmount();
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) public returns (uint256[] memory amounts) {
        amounts = PiLeftLibrary.getAmountsOut(
            address(factory),
            amountIn,
            path
        );
        if (amounts[amounts.length - 1] < amountOutMin)
            revert InsufficientOutputAmount();
        _safeTransferFrom(
            path[0],
            msg.sender,
            PiLeftLibrary.pairFor(address(factory), path[0], path[1]),
            amounts[0]
        );
        _swap(amounts, path, to);
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to
    ) public returns (uint256[] memory amounts) {
        amounts = PiLeftLibrary.getAmountsIn(
            address(factory),
            amountOut,
            path
        );
        if (amounts[amounts.length - 1] > amountInMax)
            revert ExcessiveInputAmount();
        _safeTransferFrom(
            path[0],
            msg.sender,
            PiLeftLibrary.pairFor(address(factory), path[0], path[1]),
            amounts[0]
        );
        _swap(amounts, path, to);
    }

    //
    //
    //
    //  PRIVATE
    //
    //
    //
    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        address to_
    ) internal {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = PiLeftLibrary.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to = i < path.length - 2
                ? PiLeftLibrary.pairFor(
                    address(factory),
                    output,
                    path[i + 2]
                )
                : to_;
            IPiLeftPair(
                PiLeftLibrary.pairFor(address(factory), input, output)
            ).swap(amount0Out, amount1Out, to, "");
        }
    }

    function _calculateLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal returns (uint256 amountA, uint256 amountB) {
        (uint256 reserveA, uint256 reserveB) = PiLeftLibrary.getReserves(
            address(factory),
            tokenA,
            tokenB
        );

        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = PiLeftLibrary.quote(
                amountADesired,
                reserveA,
                reserveB
            );
            if (amountBOptimal <= amountBDesired) {
                if (amountBOptimal <= amountBMin) revert InsufficientBAmount();
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = PiLeftLibrary.quote(
                    amountBDesired,
                    reserveB,
                    reserveA
                );
                assert(amountAOptimal <= amountADesired);

                if (amountAOptimal <= amountAMin) revert InsufficientAAmount();
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                from,
                to,
                value
            )
        );
        if (!success || (data.length != 0 && !abi.decode(data, (bool))))
            revert SafeTransferFailed();
    }
}