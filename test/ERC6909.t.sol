// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";

import {ERC6909, MockERC6909} from "./utils/mocks/MockERC6909.sol";

contract ER6909Test is SoladyTest {
    MockERC6909 token;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed id,
        uint256 amount
    );

    event OperatorSet(
        address indexed owner,
        address indexed spender,
        bool approved
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 indexed id,
        uint256 amount
    );

    struct _TestTemps {
        address from;
        address to;
        uint256 id;
        uint256 mintAmount;
        uint256 transferAmount;
        uint256 burnAmount;
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
        }
    }

    function testMint(uint256) public {
        _TestTemps memory t = _testTemps();

        _expectTransferEvent(address(0), t.to, t.id, t.mintAmount);
        token.mint(t.to, t.id, t.mintAmount);

        assertEq(token.balanceOf(t.to, t.id), t.mintAmount);
    }

    function testBurn(uint256) public {
        _TestTemps memory t = _testTemps();

        t.burnAmount = _bound(t.burnAmount, 0, t.mintAmount);

        _expectTransferEvent(address(0), t.to, t.id, t.mintAmount);
        token.mint(t.to, t.id, t.mintAmount);

        vm.prank(t.to);
        token.approve(address(this), t.id, t.burnAmount);

        _expectTransferEvent(t.to, address(0), t.id, t.burnAmount);
        token.burn(t.to, t.id, t.burnAmount);

        assertEq(token.balanceOf(t.to, t.id), t.mintAmount - t.burnAmount);
    }

    function _expectTransferEvent(
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) internal {
        vm.expectEmit(true, true, true, true);
        emit Transfer(from, to, id, amount);
    }

    function _expectOperatorSetEvent(
        address owner,
        address spender,
        bool approved
    ) internal {
        vm.expectEmit(true, true, true, true);
        emit OperatorSet(owner, spender, approved);
    }

    function _expectApprovalEvent(
        address owner,
        address spender,
        uint256 id,
        uint256 amount
    ) internal {
        vm.expectEmit(true, true, true, true);
        emit Approval(owner, spender, id, amount);
    }
}
