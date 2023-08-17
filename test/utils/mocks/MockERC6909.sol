// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC6909} from "../../../src/tokens/ERC6909.sol";

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockERC6909 is ERC6909 {
    function mint(address to, uint256 id, uint256 amount) public virtual {
        _mint(_brutalized(to), id, amount);
    }

    function burn(address from, uint256 id, uint256 amount) public virtual {
        _burn(_brutalized(from), id, amount);
    }

    function transfer(address to, uint256 id, uint256 amount) public virtual override {
        super.transfer(_brutalized(to), id, amount);
    }

    function transferFrom(address from, address to, uint256 id, uint256 amount)
        public
        virtual
        override
    {
        super.transferFrom(_brutalized(from), _brutalized(to), id, amount);
    }

    function _brutalized(address a) internal view returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := or(a, shl(160, gas()))
        }
    }
}
