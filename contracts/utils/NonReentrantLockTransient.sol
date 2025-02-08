// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "@openzeppelin/contracts/utils/SlotDerivation.sol";
import "@openzeppelin/contracts/utils/TransientSlot.sol";

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
abstract contract NonReentrantLockTransient {
    using NonReentrantLockTransientLibrary for *;

    /**
     * @dev Prevents reentrant calls using a default lock.
     */
    modifier nonReentrantLock() {
        NonReentrantLockTransientLibrary.NonReentrantLock memory lock = NonReentrantLockTransientLibrary.getLock();
        lock.lock();
        _;
        lock.unlock();
    }

    /**
     * @dev Allows custom reentrancy locks by specifying a unique seed.
     * @param seed The unique identifier for the custom lock.
     */
    modifier nonReentrantcustomizeLock(string memory seed) {
        NonReentrantLockTransientLibrary.NonReentrantLock memory lock = seed.getLock();
        lock.lock();
        _;
        lock.unlock();
    }
}


/**
 * @title NonReentrantLockTransientLibrary
 * @dev Library for managing transient reentrancy locks using EIP-1153 transient storage.
 * 
 * Provides functions to acquire, release, and customize locks. Locks are automatically 
 * reset at the end of transactions, ensuring safe use even in multi-call scenarios.
 * 
 * Key Functions:
 * - `getLock()`: Retrieves the default lock.
 * - `getLock(string memory seed)`: Retrieves a custom lock based on a unique seed.
 * - `lock()` & `unlock()`: Acquire and release locks, reverting on failure.
 * - `tryLock()` & `tryUnlock()`: Non-reverting lock functions returning success status.
 *
 * Example usage:
 * ```solidity
 * function criticalOperation() external {
 *    // NonReentrantLockTransientLibrary.getLock() also can get a default lock
 *    NonReentrantLockTransientLibrary.NonReentrantLock memory lock = "critical.lock".getLock();
 *    lock.lock(); 
 *    // Critical section code
 *    lock.unlock();
 * }
 * ```
 */
library NonReentrantLockTransientLibrary {
    using SlotDerivation for *;
    using TransientSlot for *;

    error GetLockFailure(string slotSeed);
    error AcquireLockFailure(string slotSeed);
    error UnlockFailure(string slotSeed);

    string public constant ERC7201_NAMESPACE = "NonReentrantLockTransientLibrary.Namespace";
    string private constant DEFAULT_LOCK_SEED = "default.lock";

    struct NonReentrantLock {
        string _SLOT_SEED;
        bytes32 _LOCK_SLOT;
    }

    /**
     * @dev Retrieves the default lock.
     * Reverts with {GetLockFailure} if the lock is already acquired.
     */
    function getLock() internal view returns (NonReentrantLock memory) {
        bytes32 slot = DEFAULT_LOCK_SEED.erc7201Slot();
        return _getLock(DEFAULT_LOCK_SEED, slot);
    }

    /**
     * @dev Retrieves a custom lock based on the provided seed.
     * @param slotSeed The unique identifier for the custom lock.
     * Reverts with {GetLockFailure} if the lock is already acquired.
     */
    function getLock(string memory slotSeed) internal view returns (NonReentrantLock memory) {
        bytes32 slot = ERC7201_NAMESPACE.erc7201Slot().deriveMapping(slotSeed);
        return _getLock(slotSeed, slot);
    }

    function _getLock(string memory slotSeed, bytes32 slot) private view returns (NonReentrantLock memory) {
        TransientSlot.BooleanSlot boolSlot = slot.asBoolean();
        if (boolSlot.tload()) {
            revert GetLockFailure(slotSeed);
        }
        return NonReentrantLock(slotSeed, slot);
    }

    /**
     * @dev Acquires the lock.
     * Reverts with {AcquireLockFailure} if the lock is already held.
     */
    function lock(NonReentrantLock memory _lock) internal {
        if (!_tryAcquire(_lock)) {
            revert AcquireLockFailure(_lock._SLOT_SEED);
        }
    }

    /**
     * @dev Releases the lock.
     * Reverts with {UnlockFailure} if the lock is not currently held.
     */
    function unlock(NonReentrantLock memory _lock) internal {
        if (!_tryRelease(_lock)) {
            revert UnlockFailure(_lock._SLOT_SEED);
        }
    }

    /**
     * @dev Attempts to acquire the lock without reverting.
     * @return success `true` if lock was acquired, `false` otherwise.
     */
    function tryLock(NonReentrantLock memory _lock) internal returns (bool) {
        return _tryAcquire(_lock);
    }

    /**
     * @dev Attempts to release the lock without reverting.
     * @return success `true` if lock was released, `false` otherwise.
     */
    function tryUnlock(NonReentrantLock memory _lock) internal returns (bool) {
        return _tryRelease(_lock);
    }

    function _tryAcquire(NonReentrantLock memory _lock) private returns (bool) {
        TransientSlot.BooleanSlot boolSlot = _lock._LOCK_SLOT.asBoolean();
        if (boolSlot.tload()) {
            return false;
        }
        boolSlot.tstore(true);
        return true;
    }

    function _tryRelease(NonReentrantLock memory _lock) private returns (bool) {
        TransientSlot.BooleanSlot boolSlot = _lock._LOCK_SLOT.asBoolean();
        if (!boolSlot.tload()) {
            return false;
        }
        boolSlot.tstore(false);
        return true;
    }
}
