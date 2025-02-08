// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "contracts/utils/AbstractNonReentrantLockTransient.sol";
import "contracts/utils/NonReentrantLockTransient.sol";
// 1.function default lock test
// 2.function customize lock test
// 3.code block lock test
// 3.code block tryLock test
contract TestNonReentrantLockTransient is AbstractNonReentrantLockTransient {
    event Log(string data);
    // use nonReentrantLock success
    function testNonReentrantLockSuccess() public nonReentrantLock {
        emit Log("testNonReentrantLock");
    }

    // use nonReentrantCustomizeLock success
    function testNonReentrantCustomizeLockSuccess() public nonReentrantcustomizeLock("testNonReentrantCustomizeLock") {
        emit Log("testNonReentrantLock");
    }

    // use nonReentrantLock fail : _useDefaultLock() try acquire the "default lock" again
    function testNonReentrantLockFail() public nonReentrantLock {
        emit Log("testNonReentrantLockFail");
        _useDefaultLock();
    }

    function _useDefaultLock() private {
        emit Log("_useDefaultLock");
        testNonReentrantLockSuccess();
    }

    // use nonReentrantCustomizeLock fail
    function testNonReentrantCustomizeLockFail(bool same) public nonReentrantcustomizeLock("testNonReentrantCustomizeLockFail") {
        emit Log("testNonReentrantCustomizeLockFail");
        if (same) {
            _useCustomizeSameLock();
        }else {
            _useCustomizeDifferentLock();
        }
    }

    function _useCustomizeSameLock() private nonReentrantcustomizeLock("testNonReentrantCustomizeLockFail") {
        emit Log("_useCustomizeSameLock");
    }

    function _useCustomizeDifferentLock() private nonReentrantcustomizeLock("differentLock") {
        emit Log("_useCustomizeDifferentLock");
    }

    // code block lock test
    using NonReentrantLockTransient for *;
    function testCodeBlockLock(bool triggerLockFailure) external {
        NonReentrantLockTransient.NonReentrantLock memory lock = NonReentrantLockTransient.getLock();
        lock.lock();
        emit Log("testCodeBlockLock");
        if (triggerLockFailure) {
            _getDefaultLock();
        }else {
            // get a customize lock
            _getCustomizeLock("customizeLock");
        }
        lock.unlock();
    }
    function _getDefaultLock() private {
        NonReentrantLockTransient.NonReentrantLock memory lock = NonReentrantLockTransient.getLock();
        lock.lock();
        emit Log("testCodeBlockLock");
        lock.unlock();
    }
    function _getCustomizeLock(string memory lockSeed) private {
        NonReentrantLockTransient.NonReentrantLock memory lock = NonReentrantLockTransient.getLock(lockSeed);
        lock.lock();
        emit Log(string.concat("_getCustomizeLock", lockSeed));
        lock.unlock();
    }

    function testCodeBlockTryLock(bool triggerLockFailure) external {
        NonReentrantLockTransient.NonReentrantLock memory lock = NonReentrantLockTransient.getLock("testCodeBlockTryLock");
        require(lock.tryLock(), "tryLock failure");
        emit Log("testCodeBlockTryLock");
        if (triggerLockFailure) {
            _tryCodeBlockLock("testCodeBlockTryLock");
        }else {
            // get a customize lock
            _getCustomizeLock("_tryCodeBlockLock");
        }
        require(lock.tryUnlock(), "tryUnlock failure");
    }
    function _tryCodeBlockLock(string memory lockSeed) private {
        NonReentrantLockTransient.NonReentrantLock memory lock = NonReentrantLockTransient.getLock(lockSeed);
        require(lock.tryLock(), "tryLock failure");
        emit Log("_tryCodeBlockLock");
        require(lock.tryUnlock(), "tryUnlock failure");
    }
}
