// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {TicTacToe} from "../../src/examples/TicTacToe.sol";

contract TicTacToeDeployer is Script {
    string deployConfig;
    bytes32 constant _TICTACTOE_SALT = "tictactoe";

    constructor() {
        string memory deployConfigPath = vm.envOr("DEPLOY_CONFIG_PATH", string("/configs/deploy-config.toml"));
        string memory filePath = string.concat(vm.projectRoot(), deployConfigPath);
        deployConfig = vm.readFile(filePath);
    }

    function run() public {
        string[] memory chainsToDeployTo = vm.parseTomlStringArray(deployConfig, ".deploy_config.chains");

        for (uint256 i = 0; i < chainsToDeployTo.length; i++) {
            string memory chainToDeployTo = chainsToDeployTo[i];

            console.log("Deploying to chain: ", chainToDeployTo);

            vm.createSelectFork(chainToDeployTo);
            deploy();
        }
    }

    function deploy() public {
        address tictactoeAddress = contractAddress();
        if (tictactoeAddress.code.length > 0) {
            console.log("TicTacToe already deployed at %s", tictactoeAddress, "on chain id: ", block.chainid);
            return;
        }

        vm.startBroadcast();

        TicTacToe tictactoe = new TicTacToe{salt: _TICTACTOE_SALT}();
        require(address(tictactoe) == tictactoeAddress);

        vm.stopBroadcast();

        console.log("Deployed TicTacToe at address: ", tictactoeAddress, "on chain id: ", block.chainid);
    }

    function contractAddress() public pure returns (address) {
        bytes32 tictactoeBytecodehash = keccak256(abi.encodePacked(type(TicTacToe).creationCode));
        return vm.computeCreate2Address(_TICTACTOE_SALT, tictactoeBytecodehash);
    }
}
