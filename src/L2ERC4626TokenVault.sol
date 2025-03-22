//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
// import {SafeERC20} from "@openzeppelin-contracts-5.2.0/token/ERC20/utils/SafeERC20.sol";
import "./TokenVault.sol";

// Libraries
import {PredeployAddresses} from "@interop-lib/libraries/PredeployAddresses.sol";

// Interfaces
import {IERC20} from "@openzeppelin-contracts-5.2.0/interfaces/IERC20.sol";
// import {IERC20Metadata} from "@openzeppelin-contracts-5.2.0/interfaces/IERC20Metadata.sol";

// Utils
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {Ownable} from "@solady/auth/Ownable.sol";

contract L2ERC4626TokenVault is Ownable, TokenVault {
    string private _name;
    string private _symbol;
    uint8 private immutable _decimals;
    address immutable _asset;

    constructor(
        address asset_,
        address owner_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) TokenVault(owner_,name_,symbol_,decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;

        _asset = asset_;

        _initializeOwner(owner_);
    }

    function asset() public view virtual override returns (address) {
        return _asset;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    // function shareProfits(uint256 amount) public {
    //     SafeERC20.safeTransferFrom(IERC20(_asset), msg.sender, address(this), amount);
    // }

}
