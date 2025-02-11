// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "contracts/proxy/EIP2535/LogicTwoFacet.sol";

contract LogicTwoV2Facet is LogicTwoFacet {
    // feature #1 beforeMyCounter
    function beforeMyCounter(string memory _content) external returns (bool) {
        string memory oldVal = _getContentSlot().value;
        _getContentSlot().value = _concat(_content, oldVal);
        return true;
    }
    // feature #2 afterMyCounter
    function afterMyCounter(string memory _content) external returns (bool) {
        string memory oldVal = _getContentSlot().value;
        _getContentSlot().value = _concat(oldVal, _content);
        return true;
    }
    function _concat(string memory str1, string memory str2) private pure returns (string memory) {
        return string(abi.encodePacked(str1, ",", str2));
    }
}
