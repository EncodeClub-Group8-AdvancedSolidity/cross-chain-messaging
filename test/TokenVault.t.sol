// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

// Testing utilities
import {Test, console2} from "forge-std/Test.sol";

// Contracts
import {ERC20} from "@openzeppelin-contracts-5.2.0/token/ERC20/ERC20.sol";

// Libraries
// import {PredeployAddresses} from "@interop-lib/libraries/PredeployAddresses.sol";

// Target contract
import {TokenVault} from "../src/TokenVault.sol";
import {L2ERC4626TokenVault} from "../src/L2ERC4626TokenVault.sol";

contract TokenVaultTest is Test {
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

        vm.prank(owner);
        depositToken = new MockERC20("Deposit Token", "DT");
        depositToken.mint(alice, 10 ether);
        depositToken.mint(bob, 10 ether);
        depositToken.mint(owner, 12 ether);
        tokenVault = new L2ERC4626TokenVault(address(depositToken), address(this), "Test", "TEST", 18);
        vm.stopPrank();
    }

    function setup_mint() public {
        vm.startPrank(alice);
        depositToken.approve(address(tokenVault), 1 ether);
        tokenVault.mint(1 ether, alice);
        assertEq(tokenVault.balanceOf(alice), 1 ether);
        assertEq(depositToken.balanceOf(address(tokenVault)), 1 ether);
        vm.stopPrank();
    }

    function test_deposit() public {
        vm.startPrank(alice);
        depositToken.approve(address(tokenVault), 1 ether);
        tokenVault.mint(1 ether, alice);
        assertEq(tokenVault.balanceOf(alice), 1 ether);
        assertEq(depositToken.balanceOf(address(tokenVault)), 1 ether);
        vm.stopPrank();
    }

    function test_withdraw() public {
        setup_mint();
        vm.startPrank(alice);
        tokenVault.withdraw(1 ether, alice, alice);
        assertEq(tokenVault.balanceOf(alice), 0);
        assertEq(depositToken.balanceOf(address(tokenVault)), 0);
        assertEq(depositToken.balanceOf(alice), 10 ether);
        vm.stopPrank();
    }

    function test_redeem() public {
        setup_mint();
        vm.startPrank(alice);
        tokenVault.redeem(1 ether, alice, alice);
        assertEq(tokenVault.balanceOf(alice), 0);
        assertEq(depositToken.balanceOf(address(tokenVault)), 0);
        assertEq(depositToken.balanceOf(alice), 10 ether);
        vm.stopPrank();
    }

    function setup_shareholders() public {
        vm.startPrank(owner);
        depositToken.approve(address(tokenVault), 10 ether);
        tokenVault.deposit(10 ether, owner);
        vm.stopPrank();
        vm.startPrank(alice);
        depositToken.approve(address(tokenVault), 10 ether);
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
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
