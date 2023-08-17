// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// TODO: optimize
// TODO: add metadata
// TODO: shouldn't methods return bool?

/// @notice Simple ERC6909 implementation.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/tokens/ERC6909.sol)
/// @author Modified from ERC-6909 (https://github.com/jtriley-eth/ERC-6909/blob/main/src/ERC6909.sol)
abstract contract ERC6909 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // /// @dev Thrown when `owner` balance for `id` is insufficient.
    // error InsufficientBalance(address owner, uint256 id);

    // /// @dev Thrown when `spender` allowance for `id` is insufficient.
    // error InsufficientPermission(address spender, uint256 id);

    /// @dev The total supply has overflowed.
    error TotalSupplyOverflow();

    /// @dev The allowance has overflowed.
    error AllowanceOverflow();

    /// @dev The allowance has underflowed.
    error AllowanceUnderflow();

    /// @dev Insufficient balance.
    error InsufficientBalance();

    /// @dev Insufficient allowance.
    error InsufficientAllowance();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Emitted when `amount` tokens with `id` is transferred from `from` to `to`.
    event Transfer(address indexed from, address indexed to, uint256 indexed id, uint256 amount);

    /// @dev Emitted when an operator is set by `owner` for `spender` with `approved` value.
    event OperatorSet(address indexed owner, address indexed spender, bool approved);

    /// @dev Emitted when `amount` tokens with `id` is approved from `owner` for `spender`.
    event Approval(
        address indexed owner, address indexed spender, uint256 indexed id, uint256 amount
    );

    /// @dev `keccak256(bytes("Transfer(address,address,uint256,uint256)"))`.
    uint256 private constant _TRANSFER_EVENT_SIGNATURE =
        0x9ed053bb818ff08b8353cd46f78db1f0799f31c9e4458fdb425c10eccd2efc44;

    /// @dev `keccak256(bytes("OperatorSet(address,address,bool)"))`.
    uint256 private constant _OPERATOR_SET_SIGNATURE =
        0xceb576d9f15e4e200fdb5096d64d5dfd667e16def20c1eefd14256d8e3faa267;

    /// @dev `keccak256(bytes("Approval(address,address,uint256,uint256)"))`.
    uint256 private constant _APPROVAL_EVENT_SIGNATURE =
        0xb3fd5071835887567a0671151121894ddccc2842f1d10bedad13e0d17cace9a7;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The `ownerSlotSeed` of a given owner is given by.
    /// ```
    ///     let ownerSlotSeed := or(_ERC6909_MASTER_SLOT_SEED, shl(96, owner))
    /// ```
    ///
    /// The balance slot of `owner` is given by.
    /// ```
    ///     mstore(0x20, ownerSlotSeed)
    ///     mstore(0x00, id)
    ///     let balanceSlot := keccak256(0x00, 0x40)
    /// ```
    ///
    /// The operator approval slot of `owner` is given by.
    /// ```
    ///     mstore(0x20, ownerSlotSeed)
    ///     mstore(0x00, operator)
    ///     let operatorApprovalSlot := keccak256(0x0c, 0x34)
    /// ```
    uint256 private constant _ERC6909_MASTER_SLOT_SEED = 0xedcaa89a82293940;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          ERC6909                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice The total supply of each id.
    mapping(uint256 => uint256) public totalSupply;

    /// @notice Owner balance of an id.
    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    /// @notice Spender allowance of an id.
    mapping(address => mapping(address => mapping(uint256 => uint256))) public allowance;

    /// @notice Checks if a spender is approved by an owner as an operator.
    mapping(address => mapping(address => bool)) public isOperator;

    /// @notice Transfers an amount of an id from the caller to a receiver.
    /// @param receiver The address of the receiver.
    /// @param id The id of the token.
    /// @param amount The amount of the token.
    function transfer(address receiver, uint256 id, uint256 amount) public virtual {
        if (balanceOf[msg.sender][id] < amount) revert InsufficientBalance();

        balanceOf[msg.sender][id] -= amount;
        balanceOf[receiver][id] += amount;

        emit Transfer(msg.sender, receiver, id, amount);
    }

    /// @notice Transfers an amount of an id from a sender to a receiver.
    /// @param sender The address of the sender.
    /// @param receiver The address of the receiver.
    /// @param id The id of the token.
    /// @param amount The amount of the token.
    function transferFrom(address sender, address receiver, uint256 id, uint256 amount)
        public
        virtual
    {
        if (sender != msg.sender && !isOperator[sender][msg.sender]) {
            if (allowance[sender][msg.sender][id] < amount) {
                revert InsufficientAllowance();
            }

            allowance[sender][msg.sender][id] -= amount;
        }

        if (balanceOf[sender][id] < amount) revert InsufficientBalance();

        balanceOf[sender][id] -= amount;
        balanceOf[receiver][id] += amount;

        emit Transfer(sender, receiver, id, amount);
    }

    /// @notice Approves an amount of an id to a spender.
    /// @param spender The address of the spender.
    /// @param id The id of the token.
    /// @param amount The amount of the token.
    function approve(address spender, uint256 id, uint256 amount) public virtual {
        allowance[msg.sender][spender][id] = amount;

        emit Approval(msg.sender, spender, id, amount);
    }

    /// @notice Sets or removes a spender as an operator for the caller.
    /// @param spender The address of the spender.
    /// @param approved The approval status.
    function setOperator(address spender, bool approved) public virtual {
        isOperator[msg.sender][spender] = approved;

        emit OperatorSet(msg.sender, spender, approved);
    }

    /// @dev Returns true if this contract implements the interface defined by `interfaceId`.
    /// See: https://eips.ethereum.org/EIPS/eip-165
    /// This function call must use less than 30000 gas.
    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            let s := shr(224, interfaceId)
            // ERC165: 0x01ffc9a7, ERC6909: 0xb2e69f8a.
            result := or(eq(s, 0x01ffc9a7), eq(s, 0xb2e69f8a))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                INTERNAL ALLOWANCE FUNCTIONS                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  INTERNAL MINT FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Mints `amount` of `id` tokens to `to`, increasing the total supply.
    ///
    /// Emits a {Transfer} event.
    function _mint(address to, uint256 id, uint256 amount) internal virtual {
        if (_useBeforeTokenTransfer()) {
            _beforeTokenTransfer(address(0), to, id, amount);
        }

        // WARNING: important safety checks should precede calls to this method.
        balanceOf[to][id] += amount;
        totalSupply[id] += amount;

        emit Transfer(address(0), to, id, amount);

        if (_useAfterTokenTransfer()) {
            _afterTokenTransfer(address(0), to, id, amount);
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  INTERNAL BURN FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function _burn(address from, uint256 id, uint256 amount) internal virtual {
        if (_useBeforeTokenTransfer()) {
            _beforeTokenTransfer(from, address(0), id, amount);
        }

        // WARNING: important safety checks should precede calls to this method.
        balanceOf[from][id] -= amount;
        totalSupply[id] -= amount;

        emit Transfer(from, address(0), id, amount);

        if (_useAfterTokenTransfer()) {
            _afterTokenTransfer(from, address(0), id, amount);
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    HOOKS FOR OVERRIDING                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Override this function to return true if `_beforeTokenTransfer` is used.
    /// The is to help the compiler avoid producing dead bytecode.
    function _useBeforeTokenTransfer() internal view virtual returns (bool) {
        return false;
    }

    /// @dev Hook that is called before any transfer of tokens.
    /// This includes minting and burning.
    function _beforeTokenTransfer(address from, address to, uint256 id, uint256 amount)
        internal
        virtual
    {}

    /// @dev Override this function to return true if `_afterTokenTransfer` is used.
    /// The is to help the compiler avoid producing dead bytecode.
    function _useAfterTokenTransfer() internal view virtual returns (bool) {
        return false;
    }

    /// @dev Hook that is called after any transfer of tokens.
    /// This includes minting and burning.
    function _afterTokenTransfer(address from, address to, uint256 id, uint256 amount)
        internal
        virtual
    {}
}
