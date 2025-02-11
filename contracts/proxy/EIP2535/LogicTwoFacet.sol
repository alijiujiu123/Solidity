// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/utils/SlotDerivation.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract LogicTwoFacet {
    using SlotDerivation for *;
    using StorageSlot for *;
    string internal constant MY_CONTENT = "eip2535.LogicTwoFacet.content";
    function getMyContent() external view returns (string memory) {
        return _getContentSlot().value;
    }
    function setMyCounter(string memory _content) external returns (bool) {
        _getContentSlot().value = _content;
        return true;
    }
    function _getContentSlot() internal pure returns (StorageSlot.StringSlot storage) {
        return MY_CONTENT.erc7201Slot().getStringSlot();
    }
}
