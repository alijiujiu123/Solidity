# 🛠 Solidity 智能合约库

本仓库包含一系列多功能 **Solidity 合约和库**，旨在提升智能合约的开发体验。模块涵盖 **数据结构**、**代理模式**、**访问控制** 以及 **安全工具**（如重入锁）。

---

## 📚 目录

### **📂 数据结构**
1. [通用链表结构](#1-通用链表结构)
2. [BitMaps & MultiBitsMaps](#2-bitmaps--multibitsmaps)

### **🔄 代理模式**
3. [自实现的可升级代理（ERC1967）](#3-自实现的可升级代理erc1967)
4. [EIP-2535 钻石标准实现](#4-eip-2535-钻石标准实现)

### **🛠 工具库**
5. [基于时间的权限管理](#5-基于时间的权限管理)
6. [重入锁库](#6-重入锁库)

---

## 1. 🗂 通用链表结构

一个支持多种数据类型的灵活链表实现，优化了性能和 Gas 费用。

### 📄 **代码位置**  
`contracts/structs/LinkedList.sol`

### ✨ **特性**

- **支持多种数据类型**：存储 `bytes32`、`uint256` 和 `address` 类型。
- **完整的 CRUD 操作**：支持添加、删除、查询和更新元素。
- **队列实现**：支持 **LIFO**（后进先出）和 **FIFO**（先进先出）模式。
- **Gas 优化**：所有操作的时间复杂度均为 **O(1)**。

### 📌 **使用场景**
- 适用于队列、订单簿、任务管理等需要有序存储的应用场景。
- 支持 LIFO（后进先出）和 FIFO（先进先出）模式，如 DeFi 交易排队、活动报名系统。

---

## 2. 🗂 BitMaps & MultiBitsMaps

### **概述**

本模块提供 Solidity 实现的高效位图结构：

- **BitMaps**：每个 bit 代表一个布尔值（`0` 或 `1`）。
- **MultiBitsMaps**：每个元素占用多个 bit（如 4-bit 或 8-bit）。

这些数据结构通过将多个值打包进 `uint256` 变量中，大幅减少存储开销，提高 Gas 效率。

### **BitMaps**

#### ✨ **特性**
- **存储布尔值**，适用于权限管理、特性开关等应用。
- **基于 `uint256` 的映射**，每个 bit 代表一个元素。
- **提供设置、清除和查询操作**。

#### **主要函数**
```solidity
function set(BitMap storage bitmap, uint256 index) internal;
function unset(BitMap storage bitmap, uint256 index) internal;
function get(BitMap storage bitmap, uint256 index) internal view returns (bool);
```

### **MultiBitsMaps**

#### ✨ **特性**
- **存储小范围整数值**，如 4-bit（0~15）、8-bit（0~255）。
- **减少存储开销**，适用于游戏属性、投票权重等应用。

#### **主要函数**
```solidity
function set(Uint256FourBitsMap storage bitmap, uint256 index, uint8 value) internal;
function get(Uint256FourBitsMap storage bitmap, uint256 index) internal view returns (uint8);

function set(Uint256ByteMap storage bitmap, uint256 index, uint8 value) internal;
function get(Uint256ByteMap storage bitmap, uint256 index) internal view returns (uint8);
```

### **Gas 优化**
- **BitMaps** 仅涉及 `SLOAD` 或 `SSTORE` 操作，极大优化 Gas 费用。
- **MultiBitsMaps** 通过数据压缩减少存储写入，提高效率。

### 📌 **使用场景**
- 高效存储用户权限、白名单状态、NFT 拥有情况等布尔值数据。
- 在链上游戏中存储角色属性、技能等级、道具状态等数值信息。
- 用于投票系统，优化投票权重存储，减少存储开销。

---

## 3. 🔄 自实现的可升级代理（ERC1967）

该模块实现了 **符合 EIP-1967 的透明可升级代理**，允许逻辑合约无缝升级，同时保持存储一致性和访问控制。

### 📄 **代码位置**
- `contracts/proxy/ERC1967/ERC1967Utils.sol`
- `contracts/proxy/ERC1967/ProxyAdmin.sol`
- `contracts/proxy/ERC1967/TransparentUpgradeableProxy.sol`

### ✨ **特性**
- **符合 EIP-1967 规范**，确保存储布局一致性。
- **透明代理模式**，将管理权限与普通用户操作分开。
- **支持升级逻辑合约**，并可在升级时进行初始化。
- **安全的管理员控制**，提供权限管理和转移功能。

### 📌 **使用场景**
- 用于需要支持升级的智能合约，如 DeFi 协议、DAO 合约等，保证存储布局的一致性。
- 通过 ProxyAdmin 进行升级管理，确保合约逻辑可控。

---

## 4. 🔄 EIP-2535 钻石标准实现

该模块提供了 [EIP-2535 钻石标准](https://eips.ethereum.org/EIPS/eip-2535) 的自定义实现，支持模块化、动态拓展的智能合约架构。

### 📄 **代码位置**  
`contracts/proxy/EIP2535/*.sol`

### ✨ **特性**
- **动态添加、替换和删除合约函数**。
- **模块化存储管理**，支持 Facet 结构。
- **更灵活的合约管理**，适用于复杂 DApp。

### 📌 **使用场景**
- 适用于功能复杂的大型智能合约，能够动态添加、替换、移除合约功能模块。
- 适合 NFT、元宇宙、链游等需要不断扩展功能的场景。

---

## 5. ⏳ 基于时间的权限管理

该模块实现了 **基于时间的访问控制** 机制，允许管理员授予用户特定功能的 **限时访问权限**，适用于订阅服务或时效性权限管理。

### 📄 **代码位置**  
`contracts/utils/GrantPrivileges.sol`

### ✨ **特性**
- **管理员控制**：只有管理员可管理授权用户。
- **基于时间的访问权限**，用户在设定时间内拥有权限。
- **可扩展的角色控制**：
  - `onlyAdmin`：仅限管理员调用。
  - `onlyOwner`：限时访问权限用户可调用。
- **动态权限管理**：
  - `addOwner(address, uint)`：授权用户访问权限。
  - `getRemainingTime()`：查询剩余访问时间。
  - `changeAdmin(address)`：管理员权限转移。

### 📌 **使用场景**
- 适用于订阅服务、限时访问权限、按时间收费的 DApp，确保用户权限在规定时间内有效。
- 适合链上访问控制，如基于时效的 NFT 权限、游戏道具租赁等场景。

---

## 6. 🔒 重入锁库

提供高效的 **重入保护机制**，包括 **基于瞬态存储（EIP-1153）** 和 **传统存储** 版本。

### 📄 **代码位置**
- **瞬态存储版（EIP-1153）**
  - `contracts/utils/AbstractNonReentrantLockTransient.sol`
  - `contracts/utils/NonReentrantLockTransient.sol`
- **标准存储版**
  - `contracts/utils/AbstractNonReentrantLock.sol`
  - `contracts/utils/NonReentrantLock.sol`

### ✨ **特性**
- **默认 & 自定义锁**：支持全局锁或自定义锁（`string` 作为唯一标识）。
- **Gas 优化**：
  - **瞬态存储** 自动在交易结束时重置，减少 Gas 消耗。
  - **标准存储** 适用于不支持 EIP-1153 的链。
- **简化的修饰符**：`nonReentrantLock` 和 `nonReentrantcustomizeLock`。

### 📌 **使用场景**
- 适用于 DeFi 协议、合约间交互、资产转账等涉及资金安全的场景，防止重入攻击。
- 提供 EIP-1153 短暂存储锁（Transient Storage），在支持的链上节省 Gas 费用。

---

✨ **欢迎贡献！**

本项目持续优化中，欢迎 PR 和 Issue！💡

