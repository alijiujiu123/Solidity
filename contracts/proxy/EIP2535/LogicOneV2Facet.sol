// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "contracts/proxy/EIP2535/LogicOneFacet.sol";

contract LogicOneV2Facet is LogicOneFacet {
    // feature #1 increByMyCounter
    function increByMyCounter(uint256 _num) external returns (bool) {
        _getCounterSlot().value += _num;
        return true;
    }
    // feature #2 decreByMyCounter
    function decreByMyCounter(uint256 _num) external returns (bool) {
        if (_getCounterSlot().value-_num > 0){
            _getCounterSlot().value -= _num;
            return true;
        }else {
            return false;
        }
    }
    
    // feature #3 decreMyCounter: minus two in this call
    // notice : this is a update(need to replace)
    function decreMyCounter() external override  returns (bool) {
        if (_getCounterSlot().value > 2){
            _getCounterSlot().value -= 2;
            return true;
        }else {
            return false;
        }
    }
}
