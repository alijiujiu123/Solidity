// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "contracts/LogLibrary.sol";
import "contracts/proxy/ERC1967/ERC1967Utils.sol";
// 权限控制交由ProxyAdmin处理
contract ProxyAdmin {
    error NotAdminError(string data);
    constructor(address _adminAddress) {
        ERC1967Utils.setAdminAddress(_adminAddress);
    }
    // 提供onlyAdmin修饰器
    modifier onlyAdmin() {
        if (msg.sender != ERC1967Utils.getAdminAddress()) {
            revert NotAdminError("only admin can call this");
        }
        _;
    }
    // 变更admin
    function _changeAdmin(address _newAdmin) internal onlyAdmin {
        ERC1967Utils.setAdminAddress(_newAdmin);
    }
}
// 实现特性：
// 1.fallbcak转发逻辑合约
// 2._fallback返回数据汇编处理
// 3.逻辑合约可升级，可变更权限管理（adminAddress）
// 4.内存布局一致性处理（自定义存储槽ERC1967）
// 5.初始化逻辑调用
contract TransparentUpgradeableProxy is ProxyAdmin {
    using LogLibrary for *;
    error AddressEmptyError();
    event FallbackLog(address indexed from, bytes4 indexed msgSig, bytes msgData);
    event UpgradeAndCallLog(address indexed logicAddress, bytes data, bool success, bytes resultData);
    constructor(address _logicAddress, bytes memory data) ProxyAdmin(msg.sender) {
        _upgradeAndCall(_logicAddress, data);
    }
    fallback() external payable {
        emit FallbackLog(msg.sender, msg.sig, msg.data);
        // 转发到逻辑合约
        ERC1967Utils.delegatecall();
    }
    receive() external payable {}
    // 升级合约
    function upgradeLogicAddress(address newLogicAddress, bytes memory data) external onlyAdmin {
        _upgradeAndCall(newLogicAddress, data);
    }
    function _upgradeAndCall(address _address, bytes memory data) private {
        if (_address==address(0)) {
            revert AddressEmptyError();
        }
        // 变更逻辑合约地址
        ERC1967Utils.setImplementationAddress(_address);
        // 执行初始化逻辑
        if (data.length>0) {
            (bool success,bytes memory resultData) = _address.delegatecall(data);
            emit UpgradeAndCallLog(_address, data, success, resultData);
        }
    }
    // 变更admin
    function changeAdmin(address _newAdmin) external onlyAdmin {
        super._changeAdmin(_newAdmin);
    }
}

contract LogicInitialMethodGenerateTest {
    function generateLogicInitialize(uint256 value) external pure returns (bytes memory) {
        return abi.encodeWithSignature("initialize(uint256)", value);
    }
}

// v1合约：只支持自增1
contract LogicV1 {
    uint256 private counter;
    bool private isInitialized;
    error InitailizerCallRepeat();
    function increa() external {
        counter++;
    }
    function getCounter() external view returns (uint256) {
        return counter;
    }
    // 初始化方法
    function initialize(uint256 value) external {
        if (isInitialized) {
            revert InitailizerCallRepeat();
        }
        counter = value;
        isInitialized = true;
    }
}

// v2合约：支持自增1，自减1，支持自增任意数字
contract LogicV2 {
    uint256 private counter;
    bool private isInitialized;
    error InitailizerCallRepeat();
    function increa() external {
        counter++;
    }
    function increaBy(uint256 num) external {
        counter += num;
    }
    function decrea() external {
        counter--;
    }
    function getCounter() external view returns (uint256) {
        return counter;
    }
    // 初始化方法
    function initialize(uint256 value) external {
        if (isInitialized) {
            revert InitailizerCallRepeat();
        }
        counter = value+6;
        isInitialized = true;
    }
}
