// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
// 维护逻辑合约地址
// 维护admin地址
// 维护初始化执行状态
// delegate汇编底层调用
library ERC1967Utils {
    // 逻辑合约自定义存储槽
    struct AddressSlot {
        address value;
    }
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1.
     */
    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    // 获取IMPLEMENTATION_SLOT存储地址
    function getImplementationAddress() internal view returns(address) {
        return getAddressSlot(IMPLEMENTATION_SLOT).value;
    }
    // 设置IMPLEMENTATION_SLOT存储地址
    function setImplementationAddress(address _implementationAddress) internal {
        getAddressSlot(IMPLEMENTATION_SLOT).value = _implementationAddress;
    }
    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1.
     */
    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
    // 获取ADMIN_SLOT存储地址
    function getAdminAddress() internal view returns(address) {
        return getAddressSlot(ADMIN_SLOT).value;
    }
    // 设置ADMIN_SLOT存储地址
    function setAdminAddress(address _adminAddress) internal {
        getAddressSlot(ADMIN_SLOT).value = _adminAddress;
    }

    // 获取ADMIN_SLOT存储槽
    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly ("memory-safe") {
            r.slot := slot
        }
    }

    function delegatecall() internal {
        _delegate(getImplementationAddress());
    }
    // delegatecall底层汇编调用
    function _delegate(address implementation) private {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
    // 生成存储槽地址
    function generateStorageSlot(string memory data) public pure returns (bytes32) {
        return bytes32(uint256(keccak256(bytes(data)))-1);
    }

}
