// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";

import {ER6909, MockER6909} from "./utils/mocks/MockERC6909.sol";

contract ER6909Test is SoladyTest {
    function setUp() public {
        token = new MockERC6909();
    }
}
