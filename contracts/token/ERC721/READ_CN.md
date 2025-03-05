# ERC721Airdrop 合约

## 介绍
`ERC721Airdrop` 是一个支持空投功能的 ERC-721 NFT 合约，支持基于 Merkle Proof 和签名验证的空投，同时具有可暂停和可销毁功能。

## 功能特点
1. **支持 ERC-721 枚举**: 允许查询某地址的 NFT 列表及全局 NFT 记录。
2. **支持 NFT 销毁**: 允许 NFT 持有者销毁其持有的 NFT。
3. **可暂停**: 允许管理员暂停或恢复 NFT 交易和铸造操作。
4. **Merkle Proof 空投**: 使用 Merkle Tree 进行空投验证，确保只有符合条件的用户可以领取 NFT。
5. **签名验证空投**: 由管理员签名批准 NFT 领取地址，用户使用签名领取 NFT。

## 合约方法
### 1. 仅管理员可调用的方法
#### **pause()**
暂停所有 NFT 转移、铸造和销毁功能。

#### **unpause()**
恢复 NFT 交易。

#### **addAirdropWithMerkleRoot(bytes32 _merkleRoot_)**
设置空投的 Merkle Root。

#### **specificAirdropToken(address to) → uint256**
直接向指定地址空投 NFT。

### 2. 公开可调用的方法
#### **claimWithMerkleProof(bytes32[] calldata merkleProofs) → uint256**
使用 Merkle Proof 领取空投 NFT。

#### **claimWithSignature(bytes memory signature) → uint256**
使用管理员签名领取 NFT。

#### **burn(uint256 tokenId)**
销毁持有的 NFT。

### 3. 辅助方法
#### **getMessageHash(address _address) → bytes32**
计算指定地址的哈希值，用于生成签名。

#### **getETHMessageHash(bytes32 hash) → bytes32**
将哈希值转换为以太坊标准签名消息格式。

#### **_recoverSigner(bytes32 messageHash, bytes memory signature) → address**
从签名数据中恢复签名者地址。

## Merkle Proof 空投流程
1. **生成 Merkle Tree**
   - 计算空投地址的 Merkle Tree，并获取 Merkle Root。
   - 调用 `addAirdropWithMerkleRoot()` 设置 Merkle Root。
2. **用户领取 NFT**
   - 计算自身地址的 leaf 哈希值。
   - 提供 Merkle Proof 并调用 `claimWithMerkleProof()` 领取 NFT。

## 签名空投流程
1. **管理员生成签名**
   - 计算目标地址的哈希值 `getMessageHash(toAddress)`。
   - 使用管理员钱包进行签名，生成 `signature`。
2. **用户领取 NFT**
   - 调用 `claimWithSignature(signature)`，合约验证签名者为管理员后进行空投。

## 部署与使用
1. **部署合约**
   - 通过 Remix、Hardhat 或 Foundry 部署 `ERC721Airdrop` 合约。
2. **设置空投**
   - 管理员调用 `addAirdropWithMerkleRoot()` 设置 Merkle Root。
3. **用户领取 NFT**
   - 通过 Merkle Proof 或管理员签名方式领取 NFT。

## 许可证
本项目遵循 MIT 许可证。

