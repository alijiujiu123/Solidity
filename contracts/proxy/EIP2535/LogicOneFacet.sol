// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/utils/SlotDerivation.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";
contract LogicOneFacet {
    using SlotDerivation for *;
    using StorageSlot for *;
    string internal constant MY_COUNTER = "eip2535.LogicOneFacet.counter";
    function getMyCounter() external view returns (uint256) {
        return _getCounterSlot().value;
    }
    function setMyCounter(uint256 _num) external returns (bool) {
        _getCounterSlot().value = _num;
        return true;
    }
    function increMyCounter() external returns (bool) {
        _getCounterSlot().value++;
        return true;
    }
    function decreMyCounter() external virtual returns (bool) {
        if (_getCounterSlot().value > 1){
            _getCounterSlot().value--;
            return true;
        }else {
            return false;
        }
    }
    function _getCounterSlot() internal  pure returns (StorageSlot.Uint256Slot storage) {
        return MY_COUNTER.erc7201Slot().getUint256Slot();
    }
}
