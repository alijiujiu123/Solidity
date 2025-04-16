# SimpleSwap - 简易恒定乘积自动做市商（CPAMM）DEX

## 📌 项目简介

`SimpleSwap` 是一个基于恒定乘积自动做市商（CPAMM）的去中心化交易所（DEX）合约。它允许用户添加/移除流动性并进行代币兑换，LP 会获得流动性凭证代币（LP Token）。

该合约使用 OpenZeppelin 的 `ERC20` 实现 LP Token 标准，用户提供代币对流动性后可获得相应比例的 LP Token，反之亦可赎回。

---

## ⚙️ 合约功能

### 📥 添加流动性 `addLiquidity(token0Amount, token1Amount)`
- 首次添加：按 `sqrt(token0Amount * token1Amount)` 铸造 LP Token
- 后续添加：按两种代币比例较小值计算 LP
- 会将用户转入的 `token0` 和 `token1` 存入合约，并更新储备

### 📤 移除流动性 `removeLiquidity(liquidity)`
- 用户销毁 LP Token，从合约中取回其在池中对应比例的 `token0` 和 `token1`

### 🔄 交换代币 `swap(amountIn, tokenIn, amountOutMin)`
- 实现恒定乘积 `x * y = k` 公式
- 通过传入 `tokenIn` 和数量 `amountIn`，换出另一种代币
- 若实际兑换金额小于 `amountOutMin`，交易回滚

### 🧮 辅助函数
- `calculateSwapOutAmount(amountIn, reserveIn, reserveOut)`：基于恒定乘积公式计算输出金额
- `sqrt(num)`：用于首次添加流动性时计算 LP 数量
- `min(a, b)`：返回较小值

### 📤 事件定义

-	LiquidityAdded: 添加流动性时触发
-	LiquidityRemoved: 移除流动性时触发
-	SwapSuccess: 交易成功时触发

---

## 📜 License

MIT
