// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {CrossChainPingPong} from "../../src/examples/CrossChainPingPong.sol";

contract CrossChainPingPongDeployer is Script {
    string deployConfig;

    constructor() {
        string memory deployConfigPath = vm.envOr("DEPLOY_CONFIG_PATH", string("/configs/deploy-config.toml"));
        string memory filePath = string.concat(vm.projectRoot(), deployConfigPath);
        deployConfig = vm.readFile(filePath);
    }

    /// @notice Modifier that wraps a function in broadcasting.
    modifier broadcast() {
        vm.startBroadcast(msg.sender);
        _;
        vm.stopBroadcast();
    }

    /// @notice The CREATE2 salt to be used when deploying the token.
    function _implSalt() internal view returns (bytes32) {
        string[] memory salt = vm.parseTomlStringArray(deployConfig, ".deploy_config.salt");
        return keccak256(abi.encodePacked(salt[0]));
    }

    function _precomputeInitAddress() public view returns (address preComputedAddress_, uint256 serverChainId_) {
        serverChainId_ = vm.parseTomlUint(deployConfig, ".pingpong.server_id"); // 901, default value
        bytes memory initCode = abi.encodePacked(type(CrossChainPingPong).creationCode, abi.encode(serverChainId_));

        preComputedAddress_ = vm.computeCreate2Address(_implSalt(), keccak256(initCode));
    }

    function setUp() public {}

    function run() public {
        string[] memory chainsToDeployTo = vm.parseTomlStringArray(deployConfig, ".deploy_config.chains");

        address deployedAddress;
        uint256 serverChainId;
        for (uint256 i = 0; i < chainsToDeployTo.length; i++) {
            string memory chainToDeployTo = chainsToDeployTo[i];

            console.log("Deploying to chain: ", chainToDeployTo);

            vm.createSelectFork(chainToDeployTo);
            (address _deployedAddress, uint256 _serverChainId) = deployCrossChainPingPong();
            deployedAddress = _deployedAddress;
            serverChainId = _serverChainId;
        }
        // outputDeploymentResult(deployedAddress, serverChainId);
    }

    function deployCrossChainPingPong() public broadcast returns (address addr_, uint256 serverChainId_) {
        (address preComputedAddress, uint256 serverChainId) = _precomputeInitAddress();
        serverChainId_ = serverChainId;

        if (preComputedAddress.code.length > 0) {
            console.log("CrossChainPingPong already deployed at %s", preComputedAddress, "on chain id: ", block.chainid);
            addr_ = preComputedAddress;
        } else {
            addr_ = address(new CrossChainPingPong{salt: _implSalt()}(serverChainId_));
            console.log("Deployed CrossChainPingPong at address: ", addr_, "on chain id: ", block.chainid);
        }
    }
}
