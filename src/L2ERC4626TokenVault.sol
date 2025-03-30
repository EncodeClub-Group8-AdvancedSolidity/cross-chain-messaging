//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import "./TokenVault.sol";

// Libraries
import {PredeployAddresses} from "@interop-lib/libraries/PredeployAddresses.sol";
import {Identifier, ICrossL2Inbox} from "@interop-lib/interfaces/ICrossL2Inbox.sol";
import {IL2ToL2CrossDomainMessenger} from "@interop-lib/interfaces/IL2ToL2CrossDomainMessenger.sol";

// Interfaces
import {IERC20} from "@openzeppelin-contracts/token/ERC20/IERC20.sol";
import {IERC7802, IERC165} from "@interop-lib/interfaces/IERC7802.sol";
// import {IERC20Metadata} from "@openzeppelin-contracts/interfaces/IERC20Metadata.sol";

// Utils
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {Ownable} from "@solady/auth/Ownable.sol";

/// @notice Thrown when a function is called by an address other than the L2ToL2CrossDomainMessenger.
error CallerNotL2ToL2CrossDomainMessenger();

/// @notice Thrown when the cross-domain sender is not this contract's address on another chain.
error InvalidCrossDomainSender();

/// @notice Thrown when attempting to use a token that does not implement the ERC7802 interface.
error InvalidERC7802();

/// @notice Thrown when cross l2 origin is not the SuperVault contract
error IdOriginNotSuperVault();

/// @notice Thrown when the reference chain is mismatched
error IdChainMismatch();

/// @notice Thrown when a vault tries to call themselves;
error SenderIsSelf();

/// @notice Thrown when the expected event is not Rebalance
error DataNotRebalance();

/// @notice Thrown when the expected event is not AcceptedRebalance
error DataNotAcceptedRebalance();

/// @notice Thrown when the expected event is not AlreadyRebalanced
error DataNotAlreadyRebalanced();

/// @notice Thrown when the caller is not allowed to act
error SenderNotVault();

/// @notice Thrown when trying to start a rebalance on the wrong chain
error RebalanceChainMismatch();

/// @notice Thrown when the rebalance has already been started
error RebalanceStarted();

/// @notice Thrown when a asset does not exist
error AssetNotExists();

/// @notice Thrown when the vault makes an invalid rebalance
error RebalanceInvalid();

/// @notice Thrown when the consumed event is not forward progressing the rebalance.
error RebalanceNotForwardProgressing();

/// @notice Thrown when the vault makes a rebalance that's already been done
error RebalanceDone();

/// @notice Represents the state of a rebalance for an asset
struct RebalanceState {
    uint256 amount;
    uint256 targetChainId;
    bool isRebalancing;
}

contract L2ERC4626TokenVault is Ownable, TokenVault {
    string private _name;
    string private _symbol;
    uint8 private immutable _decimals;
    address immutable _asset;

    /// @notice Tracks the rebalance state for each asset
    mapping(address => RebalanceState) private _rebalanceStates;

    /// @notice Tracks the asset amounts per chain ID
    mapping(uint256 => mapping(address => uint256)) private _vault;

    /// @notice Emitted whenever tokens are successfully relayed on this chain.
    /// @param source        Chain ID of the source chain.
    event RelayAsset(address indexed token, address indexed from, address indexed to, uint256 amount, uint256 source);

    /// @notice Emitted when a rebalance is initiated for an asset
    event RebalanceInitiated(address indexed asset, uint256 amount, uint256 targetChainId);

    /// @notice Emitted when a rebalance is completed for an asset
    event RebalanceCompleted(address indexed asset, uint256 amount, uint256 targetChainId);

    /// @notice Emitted when a rebalance is canceled for an asset
    event RebalanceCanceled(address indexed asset, uint256 amount, uint256 targetChainId);

    /// @dev The L2 to L2 cross domain messenger predeploy to handle message passing
    IL2ToL2CrossDomainMessenger internal messenger =
        IL2ToL2CrossDomainMessenger(PredeployAddresses.L2_TO_L2_CROSS_DOMAIN_MESSENGER);

    /// @dev Modifier to restrict a function to only be a cross-domain callback into this contract
    modifier onlyCrossDomainCallback() {
        if (msg.sender != address(messenger)) revert CallerNotL2ToL2CrossDomainMessenger();
        if (messenger.crossDomainMessageSender() != address(this)) revert InvalidCrossDomainSender();

        _;
    }

    constructor(address asset_, address owner_, string memory name_, string memory symbol_, uint8 decimals_)
        TokenVault(owner_, name_, symbol_, decimals_)
    {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;

        _asset = asset_;

        _initializeOwner(owner_);
    }

    /// @notice Relays assets received from another chain.
    /// @dev Tokens are minted on the destination chain.
    /// @param asset_   Token to relay.
    /// @param _from    Address of the msg.sender of initiateRebalance on the source chain.
    /// @param _to      Address to relay tokens to.
    /// @param _amount  Amount of tokens to relay.
    function relayAsset(address asset_, address _from, address _to, uint256 _amount) external onlyCrossDomainCallback {
        (address crossDomainMessageSender, uint256 source) = messenger.crossDomainMessageContext();
        crossDomainMessageSender;
        emit RelayAsset(asset_, _from, _to, _amount, source);

        bytes memory message = abi.encodeCall(this.completeRebalance, (asset_));
        messenger.sendMessage(source, address(this), message);
    }

    /// @notice Initiates a rebalance for a specific asset
    function initiateRebalance(address asset_, uint256 amount, uint256 targetChainId) external {
        if (_rebalanceStates[asset_].isRebalancing) {
            revert RebalanceStarted();
        }

        if (asset_ == address(0)) {
            revert AssetNotExists();
        }

        if (!IERC165(asset_).supportsInterface(type(IERC7802).interfaceId)) revert InvalidERC7802();

        _rebalanceStates[asset_] = RebalanceState({amount: amount, targetChainId: targetChainId, isRebalancing: true});

        // L2NativeSuperchainERC20(asset_).crosschainBurn(address(this), amount);
        // Call the SUPERCHAIN_TOKEN_BRIDGE contract's sendERC20 function
        address superchainBridge = PredeployAddresses.SUPERCHAIN_TOKEN_BRIDGE;
        bytes memory data = abi.encodeWithSignature(
            "sendERC20(address,address,uint256,uint256)", // returns Hash of the message sent.
            asset_, // Address of the token sent.
            address(this), // Address of the sender.
            amount, // Number of tokens sent.
            targetChainId // Chain ID of the destination chain.
        );

        (bool success,) = superchainBridge.call(data);
        require(success, "SUPERCHAIN_TOKEN_BRIDGE: sendERC20 failed");

        bytes memory message = abi.encodeCall(this.relayAsset, (asset_, address(this), address(this), amount));
        // Send to the destination
        messenger.sendMessage(targetChainId, address(this), message);
        emit RebalanceInitiated(asset_, amount, targetChainId);
    }

    /// @notice Completes a rebalance for a specific asset
    function completeRebalance(address asset_) external {
        if (!_rebalanceStates[asset_].isRebalancing) {
            revert RebalanceInvalid();
        }

        emit RebalanceCompleted(asset_, _rebalanceStates[asset_].amount, _rebalanceStates[asset_].targetChainId);

        delete _rebalanceStates[asset_];
    }

    /// @notice Cancels a rebalance for a specific asset
    function cancelRebalance(address asset_) external onlyOwner {
        if (!_rebalanceStates[asset_].isRebalancing) {
            revert RebalanceInvalid();
        }

        emit RebalanceCanceled(asset_, _rebalanceStates[asset_].amount, _rebalanceStates[asset_].targetChainId);

        delete _rebalanceStates[asset_];
    }

    /// @notice updateVaultUnderlyingAsset changes the underlying asset amount of the vault across the superchain
    function updateVaultUnderlyingAsset(Identifier calldata _id, bytes calldata _data) external {
        // Validate Log
        require(_id.origin == address(this));
        ICrossL2Inbox(PredeployAddresses.CROSS_L2_INBOX).validateMessage(_id, keccak256(_data));
    }

    /// @notice Updates the vault balance for a specific chain ID and asset
    /// @param chainId The chain ID
    /// @param asset_ The asset address
    /// @param amount The amount to update
    function updateVault(uint256 chainId, address asset_, uint256 amount) external onlyOwner {
        if (asset_ == address(0)) {
            revert AssetNotExists();
        }

        _vault[chainId][asset_] = amount;
    }

    function asset() public view virtual override returns (address) {
        return _asset;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}
