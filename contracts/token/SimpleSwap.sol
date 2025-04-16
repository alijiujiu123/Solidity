// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// 去中心化交易所DEX
// 恒定乘积自动做市商（Constant Product Automated Market Maker, CPAMM）
contract SimpleSwap is ERC20 {
    // 事件
    // 流动性提供(铸币LP)事件
    event LiquidityAdded(address indexed liquidityProvider, uint256 token0Amount, uint256 token1Amount, uint256 liquidity);
    // 移除流动性(销毁LP)事件
    event LiquidityRemoved(address indexed liquidityProvider, uint256 liquidity, uint256 token0Amount, uint256 token1Amount);
    // 交易成功事件
    event SwapSuccess(address indexed tokenIn, uint256 amountIn, address indexed tokenOut, uint256 amountOut);

    // 异常
    // swap出币小于规定最小值
    error SwapAmountLessThanOutMin();

    // 代币合约
    IERC20 public token0;
    IERC20 public token1;
    // 代币0储备量
    uint256 public reserve0;
    // 代币1储备量
    uint256 public reserve1;
    constructor1(IERC20 _token0, IERC20 _token1) ERC20("SimpleSwap", "SS") {
        token0 = _token0;
        token1 = _token1;
    }
    // 添加流动性，转进代币，铸造LP
    /*liquidity计算核心逻辑：
         第一次添加流动性：
             sqrt(token0Amount * token1Amount)
         后续添加流动性：
            // 取小值
             min(
                // token0Amount占token0总储备量reserve0（本次交易后）的比例，乘以LP的总供应量totalSupply
                token0Amount * totalSupply / reserve0, 
                // token1Amount占token1总储备量reserve1（本次交易后）的比例，乘以LP的总供应量totalSupply
                token1Amount * totalSupply / reserve1
            )
    */
    // return 获得的LP代币数
    function addLiquidity(
        // 添加的token0数量
        uint256 token0Amount, 
        // 添加的token1数量
        uint256 token1Amount
    ) public returns (uint256 liquidity) {
        // checks
        require(token0Amount > 0, "addLiquidity: token0Amount can not zero");
        require(token1Amount > 0, "addLiquidity: token1Amount can not zero");
        // effects
        // 更新储备量
        reserve0 = token0.balanceOf(address(this)) + token0Amount;
        reserve1 = token1.balanceOf(address(this)) + token1Amount;
        uint256 totalSupply = totalSupply();
        if (totalSupply == 0) {
            // 第一次添加流动性，铸造sqrt(x * y)单位的LP代币
            liquidity = sqrt(token0Amount * token1Amount);
        }else {
            // 如果不是第一次添加流动性：按添加代币的数量比例铸造LP，取两个代币更小的比例
            liquidity = min(token0Amount * totalSupply / reserve0, token1Amount * totalSupply / reserve1);
        }
        // 检查LP数量
        require(liquidity > 0, "addLiquidity: insufficient liquidity");
        // 铸造LP
        _mint(msg.sender, liquidity);
        // interactions
        token0.transferFrom(msg.sender, address(this), token0Amount);
        token1.transferFrom(msg.sender, address(this), token1Amount);
        // 释放事件
        emit LiquidityAdded(msg.sender, token0Amount, token1Amount, liquidity);
    }

    // 移除流动性: 销毁liquidity数量LP代币，返还token0代币&token1代币
    /*
    核心逻辑：
        返还token0代币数量：
            // 卖出LP代币数量liquidity 占 总供应量totalSupply的比例， 乘以token0总储备量reserve0
            liquidity * reserv0 / totalSupply
        返还token1代币数量：
            // 卖出LP代币数量liquidity 占 总供应量totalSupply的比例， 乘以token1总储备量reserve1
            liquidity * reserv1 / totalSupply
    */
    function removeLiquidity(uint256 liquidity) public returns (uint256 token0Amount, uint256 token1Amount) {
        // checks
        uint256 balance = balanceOf(msg.sender);
        require(balance >= liquidity, "LP insufficient");
        // effects
        // 计算返还token代币
        uint256 totalSupply = totalSupply();
        token0Amount = liquidity * reserve0 / totalSupply;
        token1Amount = liquidity * reserve1 / totalSupply;
        reserve0 = token0.balanceOf(address(this)) - token0Amount;
        reserve1 = token1.balanceOf(address(this)) - token1Amount;
        // 销毁LP
        _burn(msg.sender, liquidity);
        // interactions
        token0.transfer(msg.sender, token0Amount);
        token1.transfer(msg.sender, token1Amount);
        emit LiquidityRemoved(msg.sender, liquidity, token0Amount,token1Amount);
    }

    // 交易: 将amount数量的tokenIn类型代币, 交换出另一种代币，另一种代币最低出币量为amountOutMin
    // 返回：amountOut  交换出的另一种代币数量；tokenOut    交换出的另一种代币类型
    function swap(uint256 amountIn, IERC20 tokenIn, uint256 amountOutMin) public returns (uint256 amountOut, IERC20 tokenOut) {
        // checks
        require(amountIn > 0, "swap: amountIn must positive");
        require(tokenIn == token0 || tokenIn == token1, "swap: tokenIn not supported");
        uint256 balance0 = token0.balanceOf(address(this));
        uint256 balance1 = token1.balanceOf(address(this));
        if (tokenIn == token0) {
            // 用token0代币交换token1代币
            amountOut = calculateSwapOutAmount(amountIn, balance0, balance1);
            tokenOut = token1;
            if (amountOut < amountOutMin) {
                revert SwapAmountLessThanOutMin();
            }
            // effects
            // reserve0增加amountIn
            reserve0 = token0.balanceOf(address(this)) + amountIn;
            // reserve1减少amountOut
            reserve1 = token1.balanceOf(address(this)) - amountOut;
            // interactions
            token0.transferFrom(msg.sender, address(this), amountIn);
            token1.transfer(msg.sender, amountOut);
        }else {
            // 用token1代币交换token0代币
            amountOut = calculateSwapOutAmount(amountIn, balance1, balance0);
            tokenOut = token0;
            if (amountOut < amountOutMin) {
                revert SwapAmountLessThanOutMin();
            }
            // effects
            // reserve1增加 amountIn
            reserve1 = token1.balanceOf(address(this)) + amountIn;
            // reserve0减少 amountOut
            reserve0 = token0.balanceOf(address(this)) - amountOut;
            // interactions
            token1.transferFrom(msg.sender, address(this), amountIn);
            token0.transfer(msg.sender, amountOut);
        }
        emit SwapSuccess(address(tokenIn), amountIn, address(tokenOut), amountOut);
    }
    
    // 计算交换出币数量
    /*
    核心逻辑：恒定乘积自动做市商（Constant Product Automated Market Maker, CPAMM）,保证: k = x*y不变
        用x代币，可以交换多少y？设：两种代币总储备量为x、y，通过δx交换出δy代币：
            交换前：k = x*y
            交换后：k = (x+δx)*(y-δy)
            由 x*y = (x+δx)*(y-δy), 可计算出：
                δy = (δx*y) / (x+δx)
    */
    // return   另一种代币出币数量
    function calculateSwapOutAmount(
        // 入币数量(δx)
        uint amountIn, 
        // 入币总储备量(x)
        uint256 reserveIn,
        // 出币总储备量(y) 
        uint256 reserveOut
    ) public pure returns (uint256 amountOut) {
        require(amountIn > 0, "calculateSwapOutAmount: amountIn must positive");
        require(reserveIn > 0, "calculateSwapOutAmount: reserveIn must positive");
        require(reserveOut > 0, "calculateSwapOutAmount: reserveOut must positive");
        amountOut = (amountIn*reserveOut) / (reserveIn+amountIn);
    }
    
    // 计算平方根
    function sqrt(uint256 num) internal pure returns (uint256 result) {
        if (num > 3) {
            result = num;
            uint256 x = num / 2 + 1;
            while (x < result) {
                result = x;
                x = (num / x + x) / 2;
            }
        }else if(num != 0) {
            result = 1;
        }
    }
    // 计算小值
    function min(uint num0, uint256 num1) internal pure returns (uint256 result) {
        result = num0 < num1 ? num0 : num1;
    }
}

/*
// 准备：部署ERC20合约
token0
	admin
		0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
	address
		0xb27A31f1b0AF2946B7F582768f03239b1eC07c2c
token1
	admin
		0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
	address
		0x5802016Bc9976C6f63D6170157adAeA1924586c1
// 铸币给0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
mint: 
	0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
	token0: 5000000000000000000
	token1: 5000000000000000000
// 部署swap合约
	// 构造函数参数
		token0: 0xb27A31f1b0AF2946B7F582768f03239b1eC07c2c
		token1: 0x5802016Bc9976C6f63D6170157adAeA1924586c1
	address
		0xdfA652ba46f72a877500fDaC5b6E212212d53549

// swap合约测试
// 1.1 增加流动性(第一次添加)
	// approve授权: 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
	token0 approve:
		0xdfA652ba46f72a877500fDaC5b6E212212d53549, 1000000000000000000
	token1 approve:
		0xdfA652ba46f72a877500fDaC5b6E212212d53549, 2000000000000000000
// 执行：addLiquidity
	token0Amount: 1000000000000000000
	token1Amount: 2000000000000000000
// 结果：ok
	lpBalance: 1414213562373095048
	reserve0: 1000000000000000000
	reserve1: 2000000000000000000
// 1.2 增加流动性(后续添加)
	// approve授权: 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
	token0 approve:
		0xdfA652ba46f72a877500fDaC5b6E212212d53549, 1000000000000000000
	token1 approve:
		0xdfA652ba46f72a877500fDaC5b6E212212d53549, 1000000000000000000
// 执行：addLiquidity
	token0Amount: 1000000000000000000
	token1Amount: 1000000000000000000
// 结果：ok
	// lp计算结果：min(707106781186547600, 471404520791031700) = 471404520791031700
		1000000000000000000*1414213562373095048/(1000000000000000000+1000000000000000000) = 707106781186547600
		1000000000000000000*1414213562373095048/(1000000000000000000+2000000000000000000) = 471404520791031700
	lpBalance: 1885618083164126730 （误差可能出现在471404520791031700计算过程中，可接受）
		1414213562373095048+471404520791031700 = 1885618083164126748
	reserve0: 2000000000000000000
	reserve1: 3000000000000000000

// 2.移除流动性
	0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
		removeLiquidity: 100000000
		result:
			token0.balanceOf(): 3000000000106066017 	ok
				3000000000000000000+106066017.17798214 = 3000000000106066017
					100000000*2000000000000000000/1885618083164126730 = 106066017.17798214
			token1.BalanceOf(): 2000000000159099025  	OK
				2000000000000000000+159099025.7669732 = 2000000000159099025
					100000000*3000000000000000000/1885618083164126730 = 159099025.7669732
			swap.balanceOf(): 					  1885618083064126730 	ok
				1885618083164126730-100000000 =   1885618083064126730
			reserve0: 1999999999893933983 	ok
				2000000000000000000-106066017 = 1999999999893933983
			reserve1: 2999999999840900975 ok
				3000000000000000000-159099025 = 2999999999840900975
// 3.交易
 	0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
 	token0.approve: 0xdfA652ba46f72a877500fDaC5b6E212212d53549,100000000
 	swap: 将 100000000 的token0，交换token1, 最少交换金额为：
 		param:
 			100000000, 0xb27A31f1b0AF2946B7F582768f03239b1eC07c2c, 139999999
 	// 计算100000000可以换多少token1?
 		(δx*y) / (x+δx)
 			δx: 100000000
 			x: 1999999999893933983
 			y: 2999999999840900975
 		(100000000*2999999999840900975)/(1999999999893933983+100000000) = 149999999.9925
 		可以换取y的数量为： 149999999

 	result:
 		token0.balanceOf(0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db): 3000000000006066017 	ok
 			3000000000106066017 - 100000000 = 3000000000006066017
 		token1.BalanceOf(0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db): 2000000000309099024 	ok
 			2000000000159099025 + 149999999 = 2000000000309099024
 		swap.balanceOf(): 					  1885618083064126730  不变 ok
 		reserve0: 1999999999993933983 	ok
 			1999999999893933983 + 100000000 = 1999999999993933983
 		reserve1: 2999999999690900976	ok
 			2999999999840900975 - 149999999 = 2999999999690900976
 		token0.balanceOf(0xdfA652ba46f72a877500fDaC5b6E212212d53549): 1999999999993933983 	ok
 		token1.BalanceOf(0xdfA652ba46f72a877500fDaC5b6E212212d53549): 2999999999690900976 	ok
*/
