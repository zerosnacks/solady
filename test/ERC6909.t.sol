// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";

import {ERC6909, MockERC6909} from "./utils/mocks/MockERC6909.sol";

contract MockERC6909WithHooks is MockERC6909 {
    uint256 public beforeCounter;
    uint256 public afterCounter;

    function _useBeforeTokenTransfer() internal view virtual override returns (bool) {
        return true;
    }

    function _useAfterTokenTransfer() internal view virtual override returns (bool) {
        return true;
    }

    function _beforeTokenTransfer(address, address, uint256, uint256) internal virtual override {
        beforeCounter++;
    }

    function _afterTokenTransfer(address, address, uint256, uint256) internal virtual override {
        afterCounter++;
    }
}

contract ERC6909HooksTest is SoladyTest {
    uint256 public expectedBeforeCounter;
    uint256 public expectedAfterCounter;

    function _checkCounters() internal view {
        require(
            expectedBeforeCounter == MockERC6909WithHooks(msg.sender).beforeCounter(),
            "Before counter mismatch."
        );
        require(
            expectedAfterCounter == MockERC6909WithHooks(msg.sender).afterCounter(),
            "After counter mismatch."
        );
    }

    function _testHooks(MockERC6909WithHooks token) internal {
        address from = _randomNonZeroAddress();
        expectedBeforeCounter++;
        expectedAfterCounter++;
        token.mint(address(this), 1, 1000);

        expectedBeforeCounter++;
        expectedAfterCounter++;
        token.transferFrom(address(this), from, 1, 1000);

        vm.prank(from);
        expectedBeforeCounter++;
        expectedAfterCounter++;
        token.transferFrom(from, address(this), 1, 1);

        expectedBeforeCounter++;
        expectedAfterCounter++;
        token.burn(address(this), 1, 1);
    }

    function testERC6909Hooks() public {
        MockERC6909WithHooks token = new MockERC6909WithHooks();

        for (uint256 i; i < 32; ++i) {
            _testHooks(token);
        }
    }
}

contract ER6909Test is SoladyTest {
    MockERC6909 token;

    event Transfer(address indexed from, address indexed to, uint256 indexed id, uint256 amount);

    event OperatorSet(address indexed owner, address indexed spender, bool approved);

    event Approval(
        address indexed owner, address indexed spender, uint256 indexed id, uint256 amount
    );

    struct _TestTemps {
        address from;
        address to;
        uint256 id;
        uint256 mintAmount;
        uint256 transferAmount;
        uint256 burnAmount;
        bool approved;
    }

    function setUp() public {
        token = new MockERC6909();
    }

    function _testTemps() internal returns (_TestTemps memory t) {
        unchecked {
            t.from = _randomNonZeroAddress();
            do {
                t.to = _randomNonZeroAddress();
            } while (t.from == t.to);
            t.id = _random();
            t.mintAmount = _random();
            t.transferAmount = _random();
            t.burnAmount = _random();
            t.approved = _random() % 2 == 0;
        }
    }

    function testMint(uint256) public {
        _TestTemps memory t = _testTemps();

        _expectTransferEvent(address(0), t.to, t.id, t.mintAmount);
        token.mint(t.to, t.id, t.mintAmount);

        assertEq(token.balanceOf(t.to, t.id), t.mintAmount);
        assertEq(token.totalSupply(t.id), t.mintAmount);
    }

    function testBurn(uint256) public {
        _TestTemps memory t = _testTemps();

        t.burnAmount = _bound(t.burnAmount, 0, t.mintAmount);

        _expectTransferEvent(address(0), t.to, t.id, t.mintAmount);
        token.mint(t.to, t.id, t.mintAmount);

        _expectApprovalEvent(t.to, address(this), t.id, t.burnAmount);
        vm.prank(t.to);
        token.approve(address(this), t.id, t.burnAmount);

        _expectTransferEvent(t.to, address(0), t.id, t.burnAmount);
        token.burn(t.to, t.id, t.burnAmount);

        assertEq(token.balanceOf(t.to, t.id), t.mintAmount - t.burnAmount);
        assertEq(token.totalSupply(t.id), t.mintAmount - t.burnAmount);
    }

    function testTransfer(uint256) public {
        _TestTemps memory t = _testTemps();

        t.transferAmount = _bound(t.transferAmount, 0, t.mintAmount);

        _expectTransferEvent(address(0), t.from, t.id, t.mintAmount);
        token.mint(t.from, t.id, t.mintAmount);

        _expectTransferEvent(t.from, t.to, t.id, t.transferAmount);
        vm.prank(t.from);
        token.transfer(t.to, t.id, t.transferAmount);

        assertEq(token.balanceOf(t.from, t.id), t.mintAmount - t.transferAmount);
        assertEq(token.balanceOf(t.to, t.id), t.transferAmount);
        assertEq(token.totalSupply(t.id), t.mintAmount);
    }

    function testTransferFrom(uint256) public {
        _TestTemps memory t = _testTemps();

        t.transferAmount = _bound(t.transferAmount, 0, t.mintAmount);

        _expectTransferEvent(address(0), t.from, t.id, t.mintAmount);
        token.mint(t.from, t.id, t.mintAmount);

        _expectApprovalEvent(t.from, t.to, t.id, t.transferAmount);
        vm.prank(t.from);
        token.approve(t.to, t.id, t.transferAmount);

        _expectTransferEvent(t.from, t.to, t.id, t.transferAmount);
        vm.prank(t.to);
        token.transferFrom(t.from, t.to, t.id, t.transferAmount);

        assertEq(token.balanceOf(t.from, t.id), t.mintAmount - t.transferAmount);
        assertEq(token.balanceOf(t.to, t.id), t.transferAmount);
        assertEq(token.totalSupply(t.id), t.mintAmount);
    }

    function testSetOperator(uint256) public {
        _TestTemps memory t = _testTemps();

        _expectOperatorSetEvent(t.from, t.to, t.approved);
        vm.prank(t.from);
        token.setOperator(t.to, t.approved);

        assertEq(token.isOperator(t.from, t.to), t.approved);
    }

    function _expectTransferEvent(address from, address to, uint256 id, uint256 amount) internal {
        vm.expectEmit(true, true, true, true);
        emit Transfer(from, to, id, amount);
    }

    function _expectOperatorSetEvent(address owner, address spender, bool approved) internal {
        vm.expectEmit(true, true, true, true);
        emit OperatorSet(owner, spender, approved);
    }

    function _expectApprovalEvent(address owner, address spender, uint256 id, uint256 amount)
        internal
    {
        vm.expectEmit(true, true, true, true);
        emit Approval(owner, spender, id, amount);
    }
}
