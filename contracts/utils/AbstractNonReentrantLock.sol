// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "contracts/utils/NonReentrantLock.sol";
/**
 * @title AbstractNonReentrantLock
 * @dev Abstract contract providing reentrancy protection using transient storage (EIP-1153).
 * 
 * This contract leverages transient storage for efficient reentrancy protection.
 * Transient storage automatically resets at the end of each transaction, minimizing gas costs
 * and ensuring safe usage even in complex, multi-call scenarios.
 * 
 * The {nonReentrantLock} modifier applies a default lock to functions, while 
 * {nonReentrantcustomizeLock} allows for customized, fine-grained locks using unique seeds.
 * 
 * Inheriting from `AbstractNonReentrantLock` will make these modifiers available for use in your contract.
 *
 * Example usage:
 * ```solidity
 * contract MyContract is AbstractNonReentrantLock {
 *     uint256 private _balance;
 * 
 *     // Apply a default reentrancy lock for standard operations
 *     function deposit() external nonReentrantLock {
 *         _balance += 1;
 *     }
 * 
 *     // Use a custom lock for more granular control over reentrancy protection
 *     function withdraw() external nonReentrantcustomizeLock("withdraw.lock") {
 *         require(_balance > 0, "Insufficient balance");
 *         _balance -= 1;
 *     }
 * }
 * ```
 * 
 * TIP: Use transient storage-based locks for efficient gas savings and robust protection 
 * against reentrancy in both simple and complex contract functions.
 */
abstract contract AbstractNonReentrantLock {
    using NonReentrantLock for *;

    /**
     * @dev Prevents reentrant calls using a default transient lock.
     * Reverts if the function is called while already executing.
     */
    modifier nonReentrantLock() {
        NonReentrantLock.NonReentrantLock memory lock = NonReentrantLock.getLock();
        lock.lock();
        _;
        lock.unlock();
    }

    /**
     * @dev Provides custom reentrancy protection by specifying a unique lock seed.
     * This allows fine-grained control over which parts of your contract are locked.
     * 
     * @param seed The unique identifier for the custom lock.
     * Reverts if the lock associated with the seed is already acquired.
     */
    modifier nonReentrantcustomizeLock(string memory seed) {
        NonReentrantLock.NonReentrantLock memory lock = seed.getLock();
        lock.lock();
        _;
        lock.unlock();
    }
}
