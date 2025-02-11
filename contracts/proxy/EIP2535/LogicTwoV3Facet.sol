// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/utils/SlotDerivation.sol";
import "contracts/proxy/EIP2535/LogicTwoV2Facet.sol";

contract LogicTwoV3Facet is LogicTwoFacet {
    using SlotDerivation for *;
    function getSlot() external view returns (bytes32) {
        return _getContentSlot().value.erc7201Slot();
    }

    function init() external {
        _getContentSlot().value = "tian lei gun gun wo hao pa pa pi de wo quan shen diao zha zha";
    }
}
