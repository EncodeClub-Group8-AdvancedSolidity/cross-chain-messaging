// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

// Testing utilities
import {Test, console2} from "forge-std/Test.sol";

// Contracts
import {IERC20} from "@openzeppelin-contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin-contracts/token/ERC20/ERC20.sol";

// Libraries
import {PredeployAddresses} from "@interop-lib/libraries/PredeployAddresses.sol";

// Target contract
import {TokenVault} from "../src/TokenVault.sol";
import {L2ERC4626TokenVault} from "../src/L2ERC4626TokenVault.sol";
import {SuperchainERC20} from "../src/SuperchainERC20.sol";
import {L2NativeSuperchainERC20} from "../src/L2NativeSuperchainERC20.sol";


contract TokenVaultTest is Test {
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
    MockERC20 depositToken;

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
        // depositToken = new MockERC20("Deposit Token", "DT");
        // depositToken.mint(alice, 10 ether);
        superchainERC20.mint(alice, 10 ether);
        superchainERC20.mint(bob, 10 ether);
        superchainERC20.mint(owner, 12 ether);
        tokenVault = new L2ERC4626TokenVault(
            address(superchainERC20),
            address(this),
            "Test",
            "TEST",
            18
        );
        vm.stopPrank();
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

    function setup_mint() public {
        vm.startPrank(alice);
        superchainERC20.approve(address(tokenVault), 1 ether);
        tokenVault.mint(1 ether, alice);
        assertEq(tokenVault.balanceOf(alice), 1 ether);
        assertEq(superchainERC20.balanceOf(address(tokenVault)), 1 ether);
        assertEq(superchainERC20.balanceOf(alice), 9 ether);
        vm.stopPrank();
    }

    function test_deposit() public {
        vm.startPrank(alice);
        superchainERC20.approve(address(tokenVault), 1 ether);
        tokenVault.deposit(1 ether, alice);
        assertEq(tokenVault.balanceOf(alice), 1 ether);
        assertEq(superchainERC20.balanceOf(address(tokenVault)), 1 ether);
        vm.stopPrank();
    }

    function test_withdraw() public {
        setup_mint();
        vm.startPrank(alice);
        tokenVault.withdraw(1 ether, alice, alice);
        assertEq(tokenVault.balanceOf(alice), 0);
        assertEq(superchainERC20.balanceOf(address(tokenVault)), 0);
        assertEq(superchainERC20.balanceOf(alice), 10 ether);
        vm.stopPrank();
    }

    function test_redeem() public {
        setup_mint();
        vm.startPrank(alice);
        tokenVault.redeem(1 ether, alice, alice);
        assertEq(tokenVault.balanceOf(alice), 0);
        assertEq(superchainERC20.balanceOf(address(tokenVault)), 0);
        assertEq(superchainERC20.balanceOf(alice), 10 ether);
        vm.stopPrank();
    }

    function setup_shareholders() public {
        vm.startPrank(owner);
        superchainERC20.approve(address(tokenVault), 10 ether);
        tokenVault.deposit(10 ether, owner);
        vm.stopPrank();
        vm.startPrank(alice);
        superchainERC20.approve(address(tokenVault), 10 ether);
        tokenVault.deposit(10 ether, alice);
        vm.stopPrank();
        assertEq(tokenVault.balanceOf(owner), 10 ether);
        assertEq(tokenVault.balanceOf(alice), 10 ether);
    }

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

contract MockERC20 is ERC20 {
    constructor(
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
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