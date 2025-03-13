# NFT Swap Exchange Protocol

[![Solidity Version](https://img.shields.io/badge/Solidity-0.8.21-blue)](https://soliditylang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![OpenZeppelin Contracts](https://img.shields.io/badge/OpenZeppelin-4.9.3-green)](https://openzeppelin.com/contracts/)

去中心化NFT交易协议，实现零平台抽成、动态手续费补偿和收益共享机制。

## 目录

- [核心特性](#核心特性)
- [合约架构](#合约架构)
- [安装部署](#安装部署)
- [使用指南](#使用指南)
- [接口规范](#接口规范)
- [手续费模型](#手续费模型)
- [安全审计](#安全审计)
- [许可证](#许可证)

## 核心特性

### 🖼 NFT交易引擎
- **白名单管理**
  - 管理员控制支持的NFT合约
  - ERC721合规性验证
- **订单系统**
  - 上架/修改/撤销订单
  - 价格验证机制
  - 链上订单簿查询
- **自动结算**
  - ETH/ERC20双模式支付
  - 资金自动转换为流动性份额

### 💰 动态手续费模型
- **分层费率结构**
  ```solidity
  struct FoundInfo {
      uint256 nftOrderFee;    // NFT交易费 (0.5%-5%)
      uint256 withdrawFee;    // 提现费 (0.2%-3%)
      uint256 flashFee;       // 闪电贷费 (0.01%-0.1%)
  }
  ```
- **手续费补偿**
  - 用户免手续费额度累计
  - 自动抵扣系统
- **收益分配**
  - 手续费收益池透明化
  - 收益再投资机制

### 🌊 流动性池体系
- **ERC4626 标准实现**
  - 份额化流动性代币 (SC)
  - 动态定价算法
  ```math
  shares = assets × (totalSupply + 1e18) / (totalAssets + 1)
  ```
- **存取款机制**
  - 存款即时份额铸造
  - 取款手续费动态计算

### ⚡ 闪电贷系统
- **ERC3156 标准兼容**
  ```solidity
  function flashLoan(
      IERC3156FlashBorrower receiver,
      address token,
      uint256 amount,
      bytes calldata data
  ) external returns (bool)
  ```
- **风险控制**
  - 最大贷款额度验证
  - 强制还款检查

## 合约架构

```solidity
contract NFTSwap is IERC721Receiver, ERC20FlashMint, Pausable {
    // 状态存储
    mapping(address => mapping(uint256 => Order)) private orderInfos;
    mapping(address => bool) private nftWhiteList;
    FoundInfo private foundInfo;
    
    // 核心功能
    function onSale() external;          // 上架NFT
    function purchase() external payable;// 购买NFT
    function deposit() external payable; // 存入ETH
    function withdraw() external;        // 提取ETH
    function flashLoan() external;       // 闪电贷
    
    // 管理功能
    function changeFeeRates() external onlyAdmin; // 费率调整
    function pause() external onlyAdmin;          // 紧急暂停
}
```

## 使用指南

### NFT交易流程
1. 上架NFT
```solidity
// 调用示例
nftContract.approve(swapAddress, tokenId);
swap.onSale(nftAddress, tokenId, 1 ether);
```

2. 购买NFT
```solidity
swap.purchase{value: 1.5 ether}(nftAddress, tokenId);
```

3. 查询订单
```solidity
(address owner, uint256 price) = swap.queryOrderInfo(nftAddress, tokenId);
```

### 流动性操作
1. 存入ETH获取份额
```solidity
uint256 shares = swap.deposit{value: 1 ether}();
```

2. 赎回份额
```solidity
uint256 assets = swap.redeem(1000 ether, msg.sender, msg.sender);
```

3. 闪电贷示例
```solidity
// 借款100 ETH
uint256 amount = 100 ether;
swap.flashLoan(this, address(0), amount, "");
```

## 接口规范

### 主要函数
| 函数名        | 参数                          | 功能描述               |
|---------------|-------------------------------|----------------------|
| onSale        | (nftAddress, tokenId, price)  | NFT上架              |
| purchase      | (nftAddress, tokenId)         | 购买NFT             |
| deposit       | () payable                    | 存入ETH获取份额      |
| withdraw      | (assets, receiver, owner)     | 赎回ETH             |
| flashLoan     | (receiver, token, amount, data)| 发起闪电贷         |

### 事件列表
```solidity
event OrderOnSale(address indexed nftAddress, uint256 tokenId, address owner);
event OrderPurchase(address indexed nftAddress, uint256 tokenId, address buyer);
event Deposit(address indexed caller, address receiver, uint256 assets, uint256 shares);
```

## 手续费模型

### 费率计算示例
1. **NFT交易费**
   ```solidity
   uint256 fee = price * nftOrderFee / 1000; // 默认1.5%
   ```

2. **提现手续费**
   ```solidity
   uint256 fee = assets * withdrawFee / 1000; // 默认0.5%
   ```

3. **闪电贷费用**
   ```solidity
   uint256 fee = amount * flashFee / 10000; // 默认0.03%
   ```

### 免手续费机制
```solidity
mapping(address => uint256) public fundsAvailable;

function _processFeeAssets() internal {
    uint256 freeAmount = fundsAvailable[user];
    // 自动抵扣逻辑...
}
```

## 安全审计

### 已实施措施
- 重入攻击防护
- 算术溢出检查
- 权限分级控制
- 紧急暂停机制

### 建议措施
- 使用Chainlink价格预言机
- 实施提现限额
- 定期安全审计

## 许可证

MIT License
Copyright (c) 2023 NFT Swap Protocol
``` 

这个README提供了完整的协议文档，包含：
1. 详细的合约架构说明
2. 完整的部署和使用指南
3. 交互式代码示例
4. 数学公式表示的定价模型
5. 可视化接口文档
6. 安全最佳实践建议

可根据实际项目需求调整各部分的详细程度，建议配合Swagger API文档和NatSpec注释使用。
