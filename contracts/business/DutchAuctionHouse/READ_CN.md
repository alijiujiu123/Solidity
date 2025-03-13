# 荷兰式拍卖合约 (Dutch Auction House)

## 概述
**DutchAuctionHouse** 是一个基于 **荷兰式拍卖** 机制的智能合约，专门用于 **ERC721 NFT** 交易。卖家可以设定一个 **初始价格**，该价格会随着时间下降，直到有买家出价购买。合约确保交易的公平性和安全性，同时管理卖家收益和平台手续费。

## 功能特点
- **NFT 白名单**：仅支持指定的 ERC721 NFT 进行拍卖。
- **荷兰式拍卖机制**：
  - 卖家设定 **最高价**（起拍价）和 **最低价**（最终价格）。
  - 价格会按照设定的时间间隔递减，直到有买家竞拍。
- **拍卖管理**：
  - 卖家可以上架 NFT 进行拍卖。
  - 竞拍者可以按当前价格购买 NFT。
  - 卖家可提现拍卖所得资金。
- **管理员权限**：
  - 添加/移除支持的 NFT。
  - 设定平台手续费。
  - 提取平台收益。

## 智能合约功能介绍
### DutchAuctionHouse 合约
- **结构体**：
  - `AuctionItem`：存储拍卖品信息（NFT 合约地址、拍卖价格、时间、买家信息等）。
- **事件**：
  - `ERC721Received`：当合约接收到 NFT 时触发。
  - `BidSuccess`：当拍卖成功成交时触发。
  - `NFTSupportAdded` / `NFTSupportRemoved`：当 NFT 合约被加入/移除白名单时触发。
- **错误**：
  - 采用多个 **自定义错误** 处理异常（例如 `UnsupportedToken`、`AuctionItemNotFound` 等）。
- **主要函数**：
  - `addNFTSupport(address)` / `removeNFTSupport(address)`：管理员添加/移除支持的 NFT 合约。
  - `createAuction(...)`：卖家创建拍卖。
  - `bidAuction(uint256)`：买家竞拍 NFT。
  - `getAuctionPrice(uint256)`：查询当前竞拍价格。
  - `withdraw()`：卖家提现拍卖所得资金。
  - `getBackNft(address, uint256, address)`：如果拍卖超时，取回 NFT。
  - `setFeeRate(uint256)` / `send()`：管理员设定手续费比例、提取平台收益。

## 使用方式
1. **卖家** 需要 **先将 NFT 发送到合约**（使用 `safeTransferFrom`）。
2. **卖家** 在 NFT 到达合约后，调用 `createAuction()` 进行上架。
3. **买家** 可以调用 `getAuctionPrice()` 查询当前价格，并通过 `bidAuction()` 进行购买。
4. **卖家** 可通过 `withdraw()` 提现拍卖所得资金。
5. **管理员** 可通过 `setFeeRate()` 设定手续费，并调用 `send()` 提取平台利润。

## 安全性考量
- 采用 `onlyAdmin` 修饰符保护管理员权限。
- 仅允许 **白名单** 内的 NFT 参与拍卖。
- 使用 Solidity 的 `require()` 和 **自定义错误** 确保交易安全。

## 许可证
本项目基于 **MIT License** 许可协议开源。
