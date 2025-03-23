// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

// Testing utilities
import {Test, console2} from "forge-std/Test.sol";

// Contracts
import {IERC20} from "@openzeppelin-contracts/token/ERC20/IERC20.sol";
// import {ERC20} from "@openzeppelin-contracts/token/ERC20/ERC20.sol";

// Libraries
import {PredeployAddresses} from "@interop-lib/libraries/PredeployAddresses.sol";

import {Ownable} from "@solady/auth/Ownable.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";

// Target contract
import {TokenVault} from "../src/TokenVault.sol";
import {L2ERC4626TokenVault} from "../src/L2ERC4626TokenVault.sol";
import {SuperchainERC20} from "../src/SuperchainERC20.sol";
import {L2NativeSuperchainERC20} from "../src/L2NativeSuperchainERC20.sol";


contract L2ERC4626TokenVaultTest is Test {
    address internal constant ZERO_ADDRESS = address(0);
    address internal constant SUPERCHAIN_TOKEN_BRIDGE =
        PredeployAddresses.SUPERCHAIN_TOKEN_BRIDGE;
    address internal constant MESSENGER =
        PredeployAddresses.L2_TO_L2_CROSS_DOMAIN_MESSENGER;

    MockSuperchainERC20 public superchainERC20;

    address owner;
    address alice;
    address bob;
    address charlie;
    TokenVault tokenVault;

    function setUp() public {
        owner = makeAddr("owner");
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");

        superchainERC20 = new MockSuperchainERC20(
            owner,
            "Deposit Token",
            "DT",
            18
        );

        vm.prank(owner);
        tokenVault = new L2ERC4626TokenVault(
            address(superchainERC20),
            address(this),
            "Test",
            "TEST",
            18
        );
        vm.stopPrank();
    }

    /// @notice Helper function to setup a mock and expect a call to it.
    function _mockAndExpect(
        address _receiver,
        bytes memory _calldata,
        bytes memory _returned
    ) internal {
        vm.mockCall(_receiver, _calldata, _returned);
        vm.expectCall(_receiver, _calldata);
    }

    /// @notice Tests the metadata of the token is set correctly.
    function testMetadata() public view {
        assertEq(superchainERC20.name(), "Deposit Token");
        assertEq(superchainERC20.symbol(), "DT");
        assertEq(superchainERC20.decimals(), 18);
        // TokenVault
        assertEq(tokenVault.name(), "Test");
        assertEq(tokenVault.symbol(), "TEST");
        assertEq(tokenVault.decimals(), 18);
    }

    /// @notice Tests that owner can mint tokens to an address.
    function testFuzz_mintTo_succeeds(address _to, uint256 _amount) public {
        vm.expectEmit(true, true, true, true);
        emit IERC20.Transfer(address(0), _to, _amount);

        vm.prank(owner);
        superchainERC20.mintTo(_to, _amount);

        assertEq(superchainERC20.totalSupply(), _amount);
        assertEq(superchainERC20.balanceOf(_to), _amount);

    }

    /// @notice Tests tokenVault mint function
    // function testFuzz_minTo_succeeds(uint256 _amount) public {
    //     // vm.assume(_spender == address(tokenVault));
    //     // vm.assume(_to == alice);
    //     vm.assume(_amount < type(uint256).max);
    //     address _spender = address(tokenVault);
    //     uint256 _sendAmount = _amount - 1;
    //     // uint256 _sendAmount = bound(_sendAmount, _amount - 1, type(uint256).max);
    //     // _sendAmount = bound(_sendAmount, _mintAmount + 1, type(uint256).max);

    //     vm.prank(owner);
    //     superchainERC20.mintTo(alice, _sendAmount);

    //     vm.prank(alice);
    //     superchainERC20.approve(_spender, _amount + 1);

    //     console2.log("Allowance for spender: ", superchainERC20.allowance(alice, _spender));
    //     tokenVault.mint(_sendAmount, alice);
    //     assertEq(tokenVault.balanceOf(alice), _sendAmount);
    // }

    /// @notice Tests the mintTo function reverts when the caller is not the owner.
    function testFuzz_mintTo_succeeds(
        address _minter,
        address _to,
        uint256 _amount
    ) public {
        vm.assume(_minter != owner);

        // Expect the revert with `Unauthorized` selector
        vm.expectRevert(Ownable.Unauthorized.selector);

        vm.prank(_minter);
        superchainERC20.mintTo(_to, _amount);
    }

    /// @notice Tests that ownership of the token can be renounced.
    function testRenounceOwnership() public {
        vm.expectEmit(true, true, true, true);
        emit Ownable.OwnershipTransferred(owner, address(0));

        vm.prank(owner);
        superchainERC20.renounceOwnership();
        assertEq(superchainERC20.owner(), address(0));
    }

    /// @notice Tests that ownership of the token can be transferred.
    function testFuzz_testTransferOwnership(address _newOwner) public {
        vm.assume(_newOwner != owner);
        vm.assume(_newOwner != ZERO_ADDRESS);

        vm.expectEmit(true, true, true, true);
        emit Ownable.OwnershipTransferred(owner, _newOwner);

        vm.prank(owner);
        superchainERC20.transferOwnership(_newOwner);

        assertEq(superchainERC20.owner(), _newOwner);
    }

    /// @notice Tests that tokens can be transferred using the transfer function.
    function testFuzz_transfer_succeeds(
        address _sender,
        uint256 _amount
    ) public {
        vm.assume(_sender != ZERO_ADDRESS);
        vm.assume(_sender != bob);

        vm.prank(owner);
        superchainERC20.mintTo(_sender, _amount);

        vm.expectEmit(true, true, true, true);
        emit IERC20.Transfer(_sender, bob, _amount);

        vm.prank(_sender);
        assertTrue(superchainERC20.transfer(bob, _amount));
        assertEq(superchainERC20.totalSupply(), _amount);

        assertEq(superchainERC20.balanceOf(_sender), 0);
        assertEq(superchainERC20.balanceOf(bob), _amount);
    }

    /// @notice Tests that tokens can be transferred using the transferFrom function.
    function testFuzz_transferFrom_succeeds(
        address _spender,
        uint256 _amount
    ) public {
        vm.assume(_spender != ZERO_ADDRESS);
        vm.assume(_spender != bob);
        vm.assume(_spender != alice);

        vm.prank(owner);
        superchainERC20.mintTo(bob, _amount);

        vm.prank(bob);
        superchainERC20.approve(_spender, _amount);

        vm.prank(_spender);
        vm.expectEmit(true, true, true, true);
        emit IERC20.Transfer(bob, alice, _amount);
        assertTrue(superchainERC20.transferFrom(bob, alice, _amount));

        assertEq(superchainERC20.balanceOf(bob), 0);
        assertEq(superchainERC20.balanceOf(alice), _amount);
    }

    /// @notice tests that an insufficient balance cannot be transferred.
    function testFuzz_transferInsufficientBalance_reverts(
        address _to,
        uint256 _mintAmount,
        uint256 _sendAmount
    ) public {
        vm.assume(_mintAmount < type(uint256).max);
        _sendAmount = bound(_sendAmount, _mintAmount + 1, type(uint256).max);

        vm.prank(owner);
        superchainERC20.mintTo(address(this), _mintAmount);

        vm.expectRevert(ERC20.InsufficientBalance.selector);
        superchainERC20.transfer(_to, _sendAmount);
    }

    /// @notice tests that an insufficient allowance cannot be transferred.
    function testFuzz_transferFromInsufficientAllowance_reverts(
        address _to,
        address _from,
        uint256 _approval,
        uint256 _amount
    ) public {
        vm.assume(_from != ZERO_ADDRESS);
        vm.assume(_approval < type(uint256).max);
        _amount = _bound(_amount, _approval + 1, type(uint256).max);

        vm.prank(owner);
        superchainERC20.mintTo(_from, _amount);

        vm.prank(_from);
        superchainERC20.approve(address(this), _approval);

        vm.expectRevert(ERC20.InsufficientAllowance.selector);
        superchainERC20.transferFrom(_from, _to, _amount);
    }

    // function setup_mint() public {
    //     vm.startPrank(alice);
    //     superchainERC20.approve(address(tokenVault), 1 ether);
    //     tokenVault.mint(1 ether, alice);
    //     assertEq(tokenVault.balanceOf(alice), 1 ether);
    //     assertEq(superchainERC20.balanceOf(address(tokenVault)), 1 ether);
    //     // assertEq(superchainERC20.balanceOf(alice), 10 ether);
    //     vm.stopPrank();
    // }

    // function test_deposit() public {
    //     vm.startPrank(alice);
    //     superchainERC20.approve(address(tokenVault), 1 ether);
    //     tokenVault.deposit(1 ether, alice);
    //     assertEq(tokenVault.balanceOf(alice), 1 ether);
    //     assertEq(superchainERC20.balanceOf(address(tokenVault)), 1 ether);
    //     vm.stopPrank();
    // }

    // function test_withdraw() public {
    //     setup_mint();
    //     vm.startPrank(alice);
    //     tokenVault.withdraw(1 ether, alice, alice);
    //     assertEq(tokenVault.balanceOf(alice), 0);
    //     assertEq(superchainERC20.balanceOf(address(tokenVault)), 0);
    //     assertEq(superchainERC20.balanceOf(alice), 10 ether);
    //     vm.stopPrank();
    // }

    // function test_redeem() public {
    //     setup_mint();
    //     vm.startPrank(alice);
    //     tokenVault.redeem(1 ether, alice, alice);
    //     assertEq(tokenVault.balanceOf(alice), 0);
    //     assertEq(superchainERC20.balanceOf(address(tokenVault)), 0);
    //     assertEq(superchainERC20.balanceOf(alice), 10 ether);
    //     vm.stopPrank();
    // }

    // function setup_shareholders() public {
    //     vm.startPrank(owner);
    //     superchainERC20.approve(address(tokenVault), 10 ether);
    //     tokenVault.deposit(10 ether, owner);
    //     vm.stopPrank();
    //     vm.startPrank(alice);
    //     superchainERC20.approve(address(tokenVault), 10 ether);
    //     tokenVault.deposit(10 ether, alice);
    //     vm.stopPrank();
    //     assertEq(tokenVault.balanceOf(owner), 10 ether);
    //     assertEq(tokenVault.balanceOf(alice), 10 ether);
    // }

    // function test_profitSharing() public {
    //     setup_shareholders();
    //     vm.startPrank(owner);
    //     depositToken.approve(address(tokenVault), 2 ether);
    //     tokenVault.shareProfits(2 ether);
    //     vm.stopPrank();
    //     assertEq(depositToken.balanceOf(address(tokenVault)), 22 ether);
    //     uint256 owner_share = tokenVault.previewRedeem(10 ether);
    //     assertEq(owner_share, 11 ether);
    // }
}

contract MockSuperchainERC20 is L2NativeSuperchainERC20 {
    constructor(
        address owner_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) L2NativeSuperchainERC20(owner_, name_, symbol_, decimals_) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}