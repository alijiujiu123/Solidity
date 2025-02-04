// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
// 带有时间限制的授权合约
contract GrantPrivileges {
    error AddressEmpty();
    error TimeLimitZero();
    // admin地址
    address private adminAddress;
    // 授权用户信息
    struct OwnerInfo {
        // 授权开始时间
        uint timestamp;
        // 授权期限
        uint timeLimit;
    }
    // 授权用户映射
    mapping(address => OwnerInfo) public ownerInfoMapping;
    // 构造器传入admin地址
    // 修饰器定义
    modifier onlyAdmin() {
        require(msg.sender==adminAddress, "only admin address can access");
        _;
    }
    modifier onlyOwner() {
        require(msg.sender==adminAddress || _legalOwner(msg.sender), "only owner address can access");
        _;
    }
    // 判断是否为授权期内的合法用户
    function _legalOwner(address senderAddress) private view returns (bool) {
        OwnerInfo memory owner = ownerInfoMapping[senderAddress];
        // 授权开始时间
        uint timestamp = owner.timestamp;
        // 授权期限
        uint timeLimit = owner.timeLimit;
        if (timestamp==uint(0) || timeLimit==uint(0)) {
            return false;
        }
        // 判断是否超过授权时间
        if (block.timestamp > (timestamp+timeLimit)){
            return false;
        }
        return true;
    }

    // 授权用户,单位：秒
    function addOwner(address newOwner,uint timeLimit) external onlyAdmin {
        if (newOwner == address(0)) {
            revert AddressEmpty();
        }
        if (timeLimit == uint(0)) {
            revert TimeLimitZero();
        }
        ownerInfoMapping[newOwner] = OwnerInfo(block.timestamp, timeLimit);
    }

    
    function getAdminAddress() external view onlyAdmin returns (address) {
        return adminAddress;
    }

    function changeAdmin(address newAdmin) external onlyAdmin {
        if (newAdmin == address(0)) {
            revert AddressEmpty();
        }
        adminAddress = newAdmin;
    }
}
contract EatFoodContract is GrantPrivileges {
    // 最终要的函数（主要依靠这个功能授权给付费用户，核心代码，饭碗）
    // 返回输入字符串的keccak256的hash结果
    function eatFood(string calldata str) external view onlyOwner returns (bytes32) {
        return keccak256(abi.encode(str));
    }
}
