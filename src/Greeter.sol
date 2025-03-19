//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
import { Predeploys } from "@eth-optimism/contracts-bedrock/src/libraries/Predeploys.sol";
import { IL2ToL2CrossDomainMessenger } from "@eth-optimism/contracts-bedrock/interfaces/L2/IL2ToL2CrossDomainMessenger.sol";    

contract Greeter {
 
    IL2ToL2CrossDomainMessenger public immutable messenger =
        IL2ToL2CrossDomainMessenger(Predeploys.L2_TO_L2_CROSS_DOMAIN_MESSENGER);
 
    string greeting;
 
    event SetGreeting(
        address indexed sender,     // msg.sender
        string greeting
    ); 
 
    event CrossDomainSetGreeting(
        address indexed sender,   // Sender on the other side
        uint256 indexed chainId,  // ChainID of the other side
        string greeting
    );
 
    function greet() public view returns (string memory) {
        return greeting;
    }
 
    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
        emit SetGreeting(msg.sender, _greeting);
 
        if (msg.sender == Predeploys.L2_TO_L2_CROSS_DOMAIN_MESSENGER) {
            (address sender, uint256 chainId) =
                messenger.crossDomainMessageContext();              
            emit CrossDomainSetGreeting(sender, chainId, _greeting);
        }
    }
}