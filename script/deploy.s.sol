// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import {PiLeftCore} from "../src/PiLeftCore.sol";
import {PiLeftPair} from "../src/PiLeftPair.sol";
import {PiLeftFactory} from "../src/PiLeftFactory.sol";

// $ source .env      # This is to store the environmental variables in the shell session
// $ forge script script/deploy.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv

contract DeployScript is Script {
    address token1;
    address token2;

    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address public noirVerifier = vm.envAddress("VERIFIER_ADDRESS");

    function deploy() public {
        // Deploy the PiLeftCore contract
        PiLeftCore core = new PiLeftCore(noirVerifier);
        
        console.log("PiLeftCore deployed at: ", address(core));

        // Deploy the PiLeftFactory contract
        PiLeftFactory factory = new PiLeftFactory();
        factory.setCore(address(core));
        console.log("PiLeftFactory deployed at: ", address(factory));
        core.setFactory(address(factory));

        // Create a new pair using the factory
        address pairContract = factory.createPair(token1, token2);

        PiLeftPair pair = PiLeftPair(pairContract);

        console.log("PiLeftPair deployed at: ", address(pair));
    }

}

