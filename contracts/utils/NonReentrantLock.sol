// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "@openzeppelin/contracts/utils/SlotDerivation.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";
/**
 * @title NonReentrantLock
 * @dev Library for managing reentrancy locks using EIP-7201 storage slots.
 * 
 * This library provides functions to acquire, release, and customize reentrancy locks.
 * It uses `uint256` storage slots for efficient gas usage compared to `boolean` slots.
 * Locks can be applied using default settings or customized with unique seeds for more granular control.
 * 
 * Key Features:
 * - `getLock()`: Retrieves the default lock, reverting if already acquired.
 * - `getLock(string memory seed)`: Retrieves a custom lock based on a unique seed.
 * - `lock()` & `unlock()`: Securely acquire and release locks, reverting on failure.
 * - `tryLock()` & `tryUnlock()`: Non-reverting lock functions that return success status.
 *
 * Example usage:
 * ```solidity
 * function criticalOperation() external {
 *    NonReentrantLock.NonReentrantLock memory lock = "critical.lock".getLock();
 *    lock.lock(); 
 *    // Critical section code
 *    lock.unlock();
 * }
 * ```
 */
library NonReentrantLock {
    using SlotDerivation for *;
    using StorageSlot for *;

    error GetLockFailure(string slotSeed);
    error AcquireLockFailure(string slotSeed);
    error UnlockFailure(string slotSeed);

    string public constant ERC7201_NAMESPACE = "NonReentrantLock.Namespace";
    string private constant DEFAULT_LOCK_SEED = "NonReentrantLock.default.lock";

    // Constants representing lock states for efficient storage management
    uint256 private constant NOT_LOCKED = 1;
    uint256 private constant LOCKED = 2;

    /**
     * @dev Structure representing a non-reentrant lock.
     * Contains a unique slot seed and the corresponding storage slot identifier.
     */
    struct NonReentrantLock {
        string _SLOT_SEED;  // Unique identifier for the lock
        bytes32 _LOCK_SLOT; // Storage slot for lock state
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

    /**
     * @dev Internal function to retrieve a lock based on the slot seed and storage slot.
     * Reverts if the lock is already held.
     */
    function _getLock(string memory slotSeed, bytes32 slot) private view returns (NonReentrantLock memory) {
        StorageSlot.Uint256Slot storage uint256Slot = slot.getUint256Slot();
        if (uint256Slot.value == LOCKED) {
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
     * @return success `true` if the lock was acquired, `false` otherwise.
     */
    function tryLock(NonReentrantLock memory _lock) internal returns (bool) {
        return _tryAcquire(_lock);
    }

    /**
     * @dev Attempts to release the lock without reverting.
     * @return success `true` if the lock was released, `false` otherwise.
     */
    function tryUnlock(NonReentrantLock memory _lock) internal returns (bool) {
        return _tryRelease(_lock);
    }

    /**
     * @dev Internal function to attempt acquiring the lock.
     * @return success `true` if the lock was successfully acquired, `false` if already locked.
     */
    function _tryAcquire(NonReentrantLock memory _lock) private returns (bool) {
        StorageSlot.Uint256Slot storage uint256Slot = _lock._LOCK_SLOT.getUint256Slot();
        if (uint256Slot.value == LOCKED) {
            return false;
        }
        uint256Slot.value = LOCKED;
        return true;
    }

    /**
     * @dev Internal function to attempt releasing the lock.
     * @return success `true` if the lock was successfully released, `false` if not currently held.
     */
    function _tryRelease(NonReentrantLock memory _lock) private returns (bool) {
        StorageSlot.Uint256Slot storage uint256Slot = _lock._LOCK_SLOT.getUint256Slot();
        if (uint256Slot.value == NOT_LOCKED) {
            return false;
        }
        uint256Slot.value = NOT_LOCKED;
        return true;
    }
}
