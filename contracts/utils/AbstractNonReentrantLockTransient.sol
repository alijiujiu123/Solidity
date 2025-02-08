// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "contracts/utils/NonReentrantLockTransient.sol";

/**
 * @title NonReentrantLockTransient
 * @dev Abstract contract that provides reentrancy protection using transient storage (EIP-1153).
 * 
 * This module helps prevent reentrant calls by leveraging transient storage, 
 * which automatically resets at the end of a transaction, reducing gas costs.
 * 
 * The {nonReentrantLock} modifier applies a default lock to functions, while 
 * {nonReentrantcustomizeLock} allows for custom, fine-grained locks using unique seeds.
 * 
 * Inheriting from `NonReentrantLockTransient` will make these modifiers available.
 *
 * Example usage:
 * ```solidity
 * contract MyContract is NonReentrantLockTransient {
 *     uint256 private _balance;
 * 
 *     // Default reentrancy lock for simple functions
 *     function deposit() external nonReentrantLock {
 *         _balance += 1;
 *     }
 * 
 *     // Custom lock for more granular reentrancy protection
 *     function withdraw() external nonReentrantcustomizeLock("withdraw.lock") {
 *         require(_balance > 0, "Insufficient balance");
 *         _balance -= 1;
 *     }
 * }
 * ```
 * 
 * TIP: Use transient storage for efficient reentrancy protection, especially in complex transactions.
 */
abstract contract AbstractNonReentrantLockTransient {
    using NonReentrantLockTransient for *;

    /**
     * @dev Prevents reentrant calls using a default lock.
     */
    modifier nonReentrantLock() {
        NonReentrantLockTransient.NonReentrantLock memory lock = NonReentrantLockTransient.getLock();
        lock.lock();
        _;
        lock.unlock();
    }

    /**
     * @dev Allows custom reentrancy locks by specifying a unique seed.
     * @param seed The unique identifier for the custom lock.
     */
    modifier nonReentrantcustomizeLock(string memory seed) {
        NonReentrantLockTransient.NonReentrantLock memory lock = seed.getLock();
        lock.lock();
        _;
        lock.unlock();
    }
}
