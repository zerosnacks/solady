// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";

import {ERC6909, MockERC6909} from "./utils/mocks/MockERC6909.sol";

contract ER6909Test is SoladyTest {
    MockERC6909 token;

    function setUp() public {
        token = new MockERC6909();
    }
}
