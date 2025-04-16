# Multi-Signature Wallet Contract

## 简介
这是一个基于Solidity的多签钱包合约，允许多个所有者共同管理资金。每笔交易需达到预设的签名阈值方可执行，提供安全的资金管理解决方案。

## 核心功能
- **钱包创建**：指定所有者和签名阈值，创建唯一钱包ID。
- **余额查询**：实时查看钱包余额及详细信息。
- **钱包充值**：向指定钱包地址存入ETH。
- **多签转账**：需足够签名验证方可执行转账交易。
- **防重放攻击**：使用Nonce和ChainID确保交易唯一性。

## 合约结构

### 数据结构
```solidity
struct WalletInfo {
    address[] owners;   // 所有者地址数组
    mapping(address => bool) isOwner; // 地址所有权校验
    uint256 threshold;  // 执行交易所需最小签名数
    uint256 nonce;      // 交易计数器（防重放）
    uint256 balance;    // 钱包余额
}
```

### 事件
- `WalletCreated`：钱包创建成功时触发
- `WalletRecharged`：钱包充值成功时触发
- `TransferExecutedSuccess/Failure`：转账执行结果通知

## 方法说明

### 创建钱包
```solidity
function createWallet(address[] memory _owners, uint256 _threshold) 
    public payable returns (bytes32)
```
- **参数**:
  - `_owners`: 所有者地址数组（需排序去重）
  - `_threshold`: 最小签名数（1 ≤ threshold ≤ owners.length）
- **返回**: 唯一钱包ID（根据排序后owners地址生成哈希）

### 执行交易
```solidity
function executeTransaction(
    bytes32 walletId,
    address to,
    uint256 value,
    bytes memory data,
    bytes memory signatures
) public returns (bool)
```
- **签名要求**:
  - 必须来自注册的owner地址
  - 签名按地址升序排列
  - 签名数 ≥ 阈值

### 辅助方法
- `walletInfo()`：查询钱包详细信息
- `walletBalance()`：查询余额
- `encodeTransactionData()`：生成交易哈希
- `checkSignatures()`：验证签名有效性

## 使用示例

### 1. 创建钱包
```javascript
// 参数
const owners = [
    "0x03C6FcED...",
    "0x17F6AD8E...", 
    "0x5c6B0f7B...",
    "0x617F2E2f...",
    "0x78731D3C..."
];
const threshold = 3;

// 调用
const walletId = await contract.createWallet(owners, threshold, {value: 5e18});
```

### 2. 查询钱包信息
```javascript
const info = await contract.walletInfo(walletId);
// 返回:
// owners: [排序后地址列表]
// threshold: 3
// nonce: 0 
// balance: 5 ETH
```

### 3. 充值钱包
```javascript
await contract.walletRecharge(walletId, {value: 3e18});
// 新余额: 8 ETH
```

### 4. 执行转账
```javascript
// 参数
const to = "0x5B38Da6a...";
const value = 2e18;
const data = "0x";
const signatures = "0xd01c43...1b"; // 至少3个有效签名

// 执行
const tx = await contract.executeTransaction(walletId, to, value, data, signatures);
// 转账成功:
// - 接收方获得2 ETH
// - 钱包余额更新为6 ETH
// - nonce递增
```

## 签名生成步骤
1. 生成交易哈希：
   ```solidity
   encodeTransactionData(walletId, to, value, data, nonce, chainId)
   ```
2. 每个owner使用私钥对哈希签名（遵循EIP-191）
3. 按owner地址升序排列签名
4. 拼接签名数据（每个签名65字节）

## 注意事项
- 所有owner地址必须唯一且非零
- 交易前需通过`sortOwners()`排序地址
- 签名必须按地址升序排列
- 每次交易nonce自动递增
- 支持跨链安全（chainId参与哈希）

## 安全机制
- 签名验证防止未授权操作
- Nonce机制防止重放攻击
- 余额检查确保资金安全
- 严格的地址校验（无重复/无效地址）

## 测试用例
参考合约注释中的详细测试场景，涵盖钱包创建、充值、转账全流程。

## License
MIT License
