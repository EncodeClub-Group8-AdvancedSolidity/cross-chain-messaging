// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {Vm} from "forge-std/Vm.sol";
import {L2ERC4626TokenVault} from "../src/L2ERC4626TokenVault.sol";
import {L2NativeSuperchainERC20} from "../src/L2NativeSuperchainERC20.sol";
import {SuperchainERC20Deployer} from "./SuperchainERC20Deployer.s.sol";

contract L2ERC4626TokenVaultDeployer is Script {
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

    function setUp() public {}

    function run() public {
        string[] memory chainsToDeployTo = vm.parseTomlStringArray(deployConfig, ".deploy_config.chains");

        address deployedAddress;
        address ownerAddr;

        for (uint256 i = 0; i < chainsToDeployTo.length; i++) {
            string memory chainToDeployTo = chainsToDeployTo[i];

            console.log("Deploying to chain: ", chainToDeployTo);

            vm.createSelectFork(chainToDeployTo);

            uint256 currentNonce = vm.getNonce(msg.sender);
            if (keccak256(abi.encodePacked(chainToDeployTo)) == keccak256(abi.encodePacked("902"))) {
                vm.setNonce(msg.sender, uint64(currentNonce + 1));
            }

            (address _deployedAddress, address _ownerAddr) = deployL2ERC4626TokenVault();
            deployedAddress = _deployedAddress;
            ownerAddr = _ownerAddr;
        }

        outputDeploymentResult(deployedAddress, ownerAddr);
    }

    function deployL2ERC4626TokenVault() public broadcast returns (address addr_, address ownerAddr_) {
        ownerAddr_ = vm.parseTomlAddress(deployConfig, ".vault.owner_address");
        string memory name = vm.parseTomlString(deployConfig, ".vault.name");
        string memory symbol = vm.parseTomlString(deployConfig, ".vault.symbol");
        uint256 decimals = vm.parseTomlUint(deployConfig, ".vault.decimals");
        require(decimals <= type(uint8).max, "decimals exceeds uint8 range");
        (address assetAddress,) = _precomputeTokenInitAddress();

        console.log("Asset address: ", assetAddress);

        bytes memory initCode = abi.encodePacked(
            type(L2ERC4626TokenVault).creationCode, abi.encode(assetAddress, ownerAddr_, name, symbol, uint8(decimals))
        );
        address preComputedAddress = vm.computeCreate2Address(_implSalt(1), keccak256(initCode));
        if (preComputedAddress.code.length > 0) {
            console.log(
                "L2ERC4626TokenVault already deployed at %s", preComputedAddress, "on chain id: ", block.chainid
            );
            addr_ = preComputedAddress;
        } else {
            addr_ = address(
                new L2ERC4626TokenVault{salt: _implSalt(1)}(assetAddress, ownerAddr_, name, symbol, uint8(decimals))
            );
            console.log("Deployed L2ERC4626TokenVault at address: ", addr_, "on chain id: ", block.chainid);
        }
    }

    function outputDeploymentResult(address deployedAddress, address ownerAddr) public {
        console.log("Outputting deployment result");

        string memory obj = "result";
        vm.serializeAddress(obj, "deployedAddress", deployedAddress);
        string memory jsonOutput = vm.serializeAddress(obj, "ownerAddress", ownerAddr);

        vm.writeJson(jsonOutput, "deployment-erc4626.json");
    }

    // struct ERC20Json {
    //     string deployedAddress;
    //     string ownerAddress;
    // }

    // function getAssetAddressFromJson() public view {
    //     string memory root = vm.projectRoot();
    //     string memory path = string.concat(root, "/deployment-erc20.json");
    //     string memory json = vm.readFile(path);
    //     bytes memory data = vm.parseJson(json);
    //     ERC20Json memory erc20Json = abi.decode(data, (ERC20Json));
    //     console2.log("Asset address: ", erc20Json.deployedAddress);
    // }

    /// @notice The CREATE2 salt to be used when deploying the vault.
    function _implSalt(uint8 _index) internal view returns (bytes32) {
        string[] memory salt = vm.parseTomlStringArray(deployConfig, ".deploy_config.salt");
        return keccak256(abi.encodePacked(salt[_index]));
    }

    function _precomputeTokenInitAddress() public view returns (address preComputedAddress_, address ownerAddr_) {
        ownerAddr_ = vm.parseTomlAddress(deployConfig, ".token.owner_address");
        string memory name = vm.parseTomlString(deployConfig, ".token.name");
        string memory symbol = vm.parseTomlString(deployConfig, ".token.symbol");
        uint256 decimals = vm.parseTomlUint(deployConfig, ".token.decimals");
        require(decimals <= type(uint8).max, "decimals exceeds uint8 range");
        bytes memory initCode = abi.encodePacked(
            type(L2NativeSuperchainERC20).creationCode, abi.encode(ownerAddr_, name, symbol, uint8(decimals))
        );

        preComputedAddress_ = vm.computeCreate2Address(_implSalt(0), keccak256(initCode));
    }
}
