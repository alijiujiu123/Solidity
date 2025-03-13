// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// nft交易所，解决抽成高，手续费补偿机制确实，收益分配机制问题
contract NFTSwap is IERC721Receiver,ERC20FlashMint,Pausable {
    using Math for uint256;
    // 异常定义
    error UnsupportedToken(address nftAddress);
    error NotReceivedToken(address nftAddress, uint256 tokenId);
    error OrderNotExists(address nftAddress, uint256 _tokenId, address sender);
    error OrderPriceInsufficient(uint256 orderPrice, uint256 msgValue);
    error WithdrawCallFail(address receiver, uint256 amount, bytes returnData);
    // 事件定义
    // nft支持白名单添加
    event NFTSupportAdded(address indexed nftAddress);
    // nft支持白名单删除
    event NFTSupportRemoved(address indexed nftAddress);
    // nft接收
    event ERC721Received(
        address indexed operator, 
        address from, 
        uint256 indexed tokenId, 
        bytes data);
    // nft上架
    event OrderOnSale(
        address indexed nftAddress, 
        uint256 indexed tokenId, 
        address indexed owner);
    // nft价格修改
    event OrderInfoUpdate(
        address indexed nftAddress, 
        uint256 indexed tokenId, 
        uint256 oldPrice, 
        uint256 newPrice);
    // 撤单
    event Revoke(
        address indexed nftAddress, 
        uint256 indexed tokenId, 
        address owner);
    // 购买事件
    event OrderPurchase(
        address indexed nftAddress, 
        uint256 indexed tokenId, 
        uint256 price, 
        address owner, 
        address indexed buyer);
    event Log(string desc, uint256 assets,uint256 shares);
    // 订单
    struct Order {
        address owner;
        uint256 price;
    }
    // 订单信息
    mapping(address nftAddress => mapping(uint256 tokenId => Order)) private orderInfos;
    // 状态变量
    uint256 public orderCounter;
    // nft可信白名单
    mapping(address nftAddress => bool) private nftWhiteList;
    // 资金池相关
    event NFTOrderFeeChange(uint256 oldFee, uint256 newFee);
    event WithdrawFeeChange(uint256 oldFee, uint256 newFee);
    // 买入基金份额
    event Deposit(address indexed caller, address indexed receiver, uint256 assets, uint256 shares);
    // 卖出基金份额
    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );
    // 收益获取
    event GetBenefit(
        // 收益
        uint256 feeAssets, 
        // 收益类型
        FeeType indexed feeType, 
        // 资产规模
        uint256 assets, 
        // 调用方
        address indexed caller, 
        // 持有者
        address indexed owner
    );
    // 购买基金份额，eth不充足
    error ETHInsufficient(uint256 msgValue, uint256 needAssets);
    // 卖出shares，账户基金份额不足
    error SharesInsufficient(uint256 shares, uint256 maxShares);
    struct FoundInfo {
        // nft交易佣金比率(千分比)
        uint256 nftOrderFee;
        // nft交易佣金总和
        uint256 nftOrderEarning;

        // 资金池提取佣金比率(千分比)
        uint256 withdrawFee;
        // 提取佣金总和
        uint256 withdrawEarning;

        // 资金池提取佣金比率(万分比)
        uint256 flashFee;
        // 提取佣金总和
        uint256 flashEarning;

        // 免佣金总和
        uint256 feeFree;
    }
    // fee类型
    enum FeeType {NFTOrder, Withdraw, FlashLoan}
    // 基金信息
    FoundInfo private foundInfo;
    // 免佣金额度
    mapping(address account => uint256) public fundsAvailable;
    // admin地址
    address public admin;
    string private constant NAME = "SwapCoin";
    string private constant SYMBOL = "SC"; 
    constructor1() ERC20(NAME, SYMBOL) {
        admin = msg.sender;
        // 默认nft交易手续费1.5%
        foundInfo.nftOrderFee = 15;
        // 默认体现手续费0.5%
        foundInfo.withdrawFee = 5;
        // 默认闪电贷手续费:万分之三
        foundInfo.flashFee = 3;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "not authorized");
        _;
    }
    // admin变更
    function changeAdmin(address account) external onlyAdmin{
        require(account != address(0), "invalid account");
        admin = account;
    }

    //一、 交易所相关
    // 添加nft白名单
    function addNFTSupport(address _nftAddress) external onlyAdmin {
        require(_nftAddress != address(0), "invalid nft address");
        require(address(this) != _nftAddress, "invalid nft address");
        require(!nftWhiteList[_nftAddress],"already exists in whitelist");
        // 校验是否为ERC721
        require(IERC721(_nftAddress).supportsInterface(type(IERC721).interfaceId), "invalid nft type");
        // 拍卖品白名单
        nftWhiteList[_nftAddress] = true;
        emit NFTSupportAdded(_nftAddress);
    }
    // 移除nft白名单
    function removeNFTSupport(address _nftAddress) external onlyAdmin {
        require(_nftAddress != address(0), "invalid nft");
        // 拍卖品白名单
        delete nftWhiteList[_nftAddress];
        emit NFTSupportRemoved(_nftAddress);
    }

    // 接收拍卖品
    // 一、交易所
    // 1.NFT接收
    function onERC721Received(address operator, address from, uint256 _tokenId, bytes memory data) public virtual returns (bytes4) {
        emit ERC721Received(operator, from, _tokenId, data);
        return IERC721Receiver.onERC721Received.selector;
    }
    // 2.商品上架
    function onSale(IERC721 nftContract, uint256 _tokenId, uint256 _price) external {
        address nftAddress = address(nftContract);
        // checks
        _checkNFTSupport(nftAddress);
        // 是否已approve
        _checkOwnerable(nftContract, _tokenId);
        // effects
        orderInfos[nftAddress][_tokenId].owner = msg.sender;
        orderInfos[nftAddress][_tokenId].price = _price;
        // interactions
        _transferFromIfNeed(nftContract, _tokenId);
        // emit
        emit OrderOnSale(nftAddress, _tokenId, msg.sender);
    }
    // nft转账到本合约
    function _transferFromIfNeed(IERC721 nftContract, uint256 _tokenId) private {
        if (nftContract.ownerOf(_tokenId) != address(this)) {
            nftContract.safeTransferFrom(msg.sender, address(this), _tokenId);
        }
    }
    // nft是否支持
    function _checkNFTSupport(address _nftAddress) private view {
        if (!nftWhiteList[_nftAddress]) {
            revert UnsupportedToken(_nftAddress);
        }
    }
    // 检查是否已转账或授权
    function _checkOwnerable(IERC721 nftContract, uint256 _tokenId) private view {
        if(nftContract.ownerOf(_tokenId) != address(this) && nftContract.getApproved(_tokenId) != address(this)) {
            revert NotReceivedToken(address(nftContract), _tokenId);
        }
    }
    // 3.商品价格修改
    modifier onlyOwner(address _nftAddress, uint256 _tokenId) {
        require(orderInfos[_nftAddress][_tokenId].owner == msg.sender, "not authorized");
        _;
    }
    function update(address _nftAddress, uint256 _tokenId, uint256 _newPrice) external onlyOwner(_nftAddress, _tokenId) {
        // checks
        _checkOrderExists(_nftAddress, _tokenId);
        // effects
        uint256 oldPrice = orderInfos[_nftAddress][_tokenId].price;
        orderInfos[_nftAddress][_tokenId].price = _newPrice;
        //interactions
        emit OrderInfoUpdate(_nftAddress, _tokenId, oldPrice, _newPrice);
    }
    // check order exists
    function _checkOrderExists(address _nftAddress, uint256 _tokenId) private view {
        if (orderInfos[_nftAddress][_tokenId].owner == address(0)) {
            revert OrderNotExists(_nftAddress, _tokenId, msg.sender);
        }
    }
    // 4.商品撤单
    function revoke(address _nftAddress, uint256 _tokenId) external onlyOwner(_nftAddress, _tokenId){
        // checks
        _checkOrderExists(_nftAddress, _tokenId);
        // effects
        delete orderInfos[_nftAddress][_tokenId];
        // interactions
        IERC721(_nftAddress).safeTransferFrom(address(this), msg.sender, _tokenId);
        emit Revoke(_nftAddress, _tokenId, msg.sender);
    }
    // 5.商品下单
    function purchase(address _nftAddress, uint256 _tokenId) external payable returns (uint256) {
        // checks
        _checkOrderExists(_nftAddress, _tokenId);
        _checkValue(_nftAddress, _tokenId);
        // effects
        address owner = orderInfos[_nftAddress][_tokenId].owner;
        uint256 price = orderInfos[_nftAddress][_tokenId].price;
        delete orderInfos[_nftAddress][_tokenId];
        // interactions
        IERC721(_nftAddress).safeTransferFrom(address(this), msg.sender, _tokenId);
        // 将owner(订单卖家)应收金额转换为基金份额
        uint256 shares = _convertSharesByNFTOrderPrice(owner, price, msg.value);
        // 余额退还
        if (msg.value > price) {
            _doTransfer(msg.sender, msg.value - price);
        }
        emit OrderPurchase(_nftAddress, _tokenId, price, owner, msg.sender);
        return shares;
    }
    // nft订单金额assets转换为，owner的基金份额
    // 相当于owner，以1.5%的佣金，买入基金份额
    function _convertSharesByNFTOrderPrice(
        // nft订单卖家
        address receiver, 
        // nft订单金额
        uint256 orderPrice, 
        uint256 msgValue
    ) private returns (uint256) {
        uint256 feeAmount = orderPrice.mulDiv(foundInfo.nftOrderFee, 1000, Math.Rounding.Ceil);
        uint256 assets = orderPrice - feeAmount;
        uint256 shares;
        if (assets != 0) {
            // 计算份额
            shares = _convertToShares(assets, Math.Rounding.Floor, msgValue);
            // effects
            _deposit(receiver, assets, shares);
            // 这里的caller=_msgSender(),即订单买家; owner=receiver,即订单卖家（这个逻辑没有问题，后续的免手续费是需要从订单卖家receiver额度中扣除的）
            _processFeeAssets(feeAmount, FeeType.NFTOrder, assets, _msgSender(), receiver);
        }
        return shares;
    }
    // 金额校验
    function _checkValue(address _nftAddress, uint256 _tokenId) private view {
        if (orderInfos[_nftAddress][_tokenId].price > msg.value) {
            revert OrderPriceInsufficient(orderInfos[_nftAddress][_tokenId].price, msg.value);
        }
    }
    // 6.商品查询
    function queryOrderInfo(address _nftAddress, uint256 _tokenId) external view returns (address owner, uint256 price) {
        _checkOrderExists(_nftAddress, _tokenId);
        owner = orderInfos[_nftAddress][_tokenId].owner;
        price = orderInfos[_nftAddress][_tokenId].price;
    }

    //二、支付托管机制
    // 2.1 基金份额代币相关
    // 代币交易开关
    function _update(address from, address to, uint256 value) internal override whenNotPaused {
        super._update(from, to, value);
    }
    // 交易开关状态变更: 触发暂停状态
    function pause() external onlyAdmin {
        super._pause();   
    }
    // 解除交易暂停状态
    function unpause() external onlyAdmin {
        super._unpause();
    }
    // 2.2 ERC4626相关
    // 合约总资产(当前请求之前)
    function totalAssets() public view returns (uint256) {
        return address(this).balance;
    }
    // 最大可赎回份额
    function maxRedeem() external view returns (uint256) {
        return this.balanceOf(_msgSender());
    }
    function maxRedeem(address owner) public view returns (uint256) {
        return this.balanceOf(owner);
    }
    // assets转换为基金份额：计算理论上可兑换的份额
    function _convertToShares(uint256 assets, Math.Rounding rounding, uint256 msgValue) internal view virtual returns (uint256) {
        // assets*(totalSupply+1)/(totalAssets()+1)  防止出现分母为0所以分子分母加1
        // (totalSupply+1)/(totalAssets()+1)：当前基金池每单位数量的资产(eth)，相当于多少基金份额
        return assets.mulDiv(totalSupply() + 10 ** _decimalsOffset(), totalAssets() + 1 - msgValue, rounding);
    }
    // 预估assets数量的eth可以购买多少份额：计算用户存入 assets 数量的基础资产后，可以获得多少 shares（金库份额）。
    // 入金不需要手续费，所以直接调用_convertToShares
    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        // 向下取整: 避免因计算误差导致用户多获得 shares,损害现有存款人的权益
        return _convertToShares(assets, Math.Rounding.Floor, 0);
    }
    // 预估购买shares数量的基金份额需要多少eth：计算用户想要获得 shares 数量的金库份额，需要存入多少 assets 资产。
    // 入金不需要手续费
    function previewMint(uint256 shares) public view virtual returns (uint256) {
        // 向上取整: 避免因计算误差导致用户少拿eth,损害现有存款人的权益
        return _convertToAssets(shares, Math.Rounding.Ceil, 0);
    }
    // 与eth的换算偏移量,这里采用1:1
    function _decimalsOffset() internal view virtual returns (uint8) {
        return 0;
    }
    // shares转换为资产金额：计算理论上shares数量的基金份额，需要入金多少eth
    function _convertToAssets(uint256 shares, Math.Rounding rounding, uint256 msgValue) internal view virtual returns (uint256) {
        // shares*(totalAssets()+1)/(totalSupply()+1)   防止出现分母为0所以分子分母加1
        // (totalAssets()+1)/(totalSupply()+1): 当前基金池每单位基金份额，相当于多少资产(eth)
        return shares.mulDiv(totalAssets() + 1 - msgValue, totalSupply() + 10 ** _decimalsOffset(), rounding);
    }

    // 预估取现assets数量的eth，需要多少基金份额：计算用户想要取出 assets 数量的基础资产，需要销毁多少 shares。
    // 出金需要手续费：默认0.5%
    function previewWithdraw(uint256 assets) public view returns (uint256) {
        (uint256 shares, ) = _calcWithdraw(assets);
        return shares;
    }
    // 计算取现assets需要的shares, 
    // 返回：shares(需要卖出的基金份额)，feeAssets(交易佣金)
    function _calcWithdraw(uint256 assets) private view returns (uint256 shares, uint256 feeAssets) {
        // 交易手续费，向上取整，避免损害存款人权益
        feeAssets = assets.mulDiv(foundInfo.withdrawFee, 1000, Math.Rounding.Ceil);
        // 向上取整：避免因计算误差导致用户少拿shares(即多获得eth)，损害存款人权益
        shares = _convertToShares((assets - feeAssets), Math.Rounding.Ceil, 0);
    }

    // 预估shares数量的基金份额，可以赎回多少eth：计算用户想要赎回 shares 数量的金库份额，可以获得多少 assets 资产。
    // 出金需要手续费：默认0.5%
    function previewRedeem(uint256 shares) public view returns (uint256) {
        (uint256 assets, ) = _calcRedeem(shares);
        return assets;
    }
    // 计算shares可以卖出的eth
    // assets(卖出可以得到的eth)，feeAssets(交易佣金)
    function _calcRedeem(uint256 shares) private view returns (uint256 assets, uint256 feeAssets) {
        // 向下取整，确保用户不会多拿走eth，使资金池受损
        uint256 originAssets = _convertToAssets(shares, Math.Rounding.Floor, 0);
        // 手续费，向上取整，确保用户不会多拿ETH，保证资金池安全
        feeAssets = originAssets.mulDiv(foundInfo.withdrawFee, 1000, Math.Rounding.Ceil);
        assets = originAssets - feeAssets;
    }

    // 指定msg.value,购买基金份额给receiver，返回购买基金份额数
    function deposit(address receiver) public payable returns (uint256) {
        require(receiver != address(0), "invalid receiver");
        uint256 assets = msg.value;
        uint256 shares;
        // checks
        if (assets != 0) {
            shares = _convertToShares(assets, Math.Rounding.Floor, assets);
            // effects
            _deposit(receiver, assets, shares);
        }
        return shares;
    }
    // 买入指定shares基金份额给receiver，多余eth返还，返回花费eth数
    function mint(uint256 shares, address receiver) public payable returns (uint256) {
        // checks
        require(receiver != address(0), "invalid receiver");
        uint256 assets = _convertToAssets(shares, Math.Rounding.Ceil, msg.value);
        if (msg.value < assets) {
            revert ETHInsufficient(msg.value, assets);
        }
        // effects
        _deposit(receiver, assets, shares);
        // 返还eth
        if (msg.value > assets) {
            payable(_msgSender()).transfer(msg.value - assets);
        }
        return assets;
    }
    // 买入基金份额给receiver
    function _deposit(address receiver, uint256 assets, uint256 shares) private {
        _mint(receiver, shares);
        emit Deposit(_msgSender(), receiver, assets, shares);
    }

    // 卖出owner基金份额，赎回assets数量的eth给receiver, 返回卖出的shares数量
    function withdraw(
        // 卖出价值assets的基金份额
        uint256 assets, 
        // 卖出基金的eth收入接收者
        address receiver, 
        // 基金份额持有者
        address owner
        ) public returns (uint256) {
        // checks
        require(receiver != address(0), "invalid receiver");
        require(owner != address(0), "invalid owner");
        (uint256 shares, uint256 feeAssets) = _calcWithdraw(assets);
        // effects
        // 处理fee相关
        uint256 freeFee = _processFeeAssets(feeAssets, FeeType.Withdraw, assets, _msgSender(), owner);
        // 如果owner的余额小于shares，或approvel给sender的数量小于shares，ERC20会revert
        _withdraw(_msgSender(), receiver, owner, assets+freeFee, shares);
        
        return shares;
    }
    // 卖出owner的shares数量基金，赎回eth给receiver，返回赎回的eth数量
    function redeem(uint256 shares, address receiver, address owner) public virtual returns (uint256) {
        require(receiver != address(0), "invalid receiver");
        require(owner != address(0), "invalid owner");
        // shares转化为eth的数量shares
        (uint256 assets, uint256 feeAssets) = _calcRedeem(shares);
        uint256 freeFee = _processFeeAssets(feeAssets, FeeType.Withdraw, assets, _msgSender(), owner);
        // 如果owner的余额小于shares，或approvel给sender的数量小于shares，ERC20会revert
        _withdraw(_msgSender(), receiver, owner, assets+freeFee, shares);
        return assets;
    }
    // 卖出shares
    function _withdraw(
        // 基金份额卖出的调用人
        address caller,
        // eth接收者
        address receiver,
        // 基金份额持有人
        address owner,
        // 需要向用户转账的eth数额
        uint256 assets,
        // 卖出的基金份额
        uint256 shares
    ) internal {
        // 校验owner是否approvel给caller，shares数量的基金份额
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }
        _burn(owner, shares);
        // 转账给receiver
        _doTransfer(receiver, assets);
        emit Withdraw(caller, receiver, owner, assets, shares);
    }
    // 转账
    function _doTransfer(address receiver, uint256 amount) private {
        (bool success, bytes memory returnData)  = receiver.call{value: amount}("");
        if (!success) {
            revert WithdrawCallFail(receiver, amount, returnData);
        }
    }
    // 收益处理, 返回免佣金额
    function _processFeeAssets(
        // 佣金金额
        uint256 feeAssets, 
        // 佣金类型
        FeeType feeType, 
        // 资产规模
        uint256 assets, 
        // 调用者
        address caller, 
        // 资产拥有者
        address owner
    ) private returns (uint256) {
        // checks
        // require(uint(feeType) <= unit(FeeType.FlashLoan), "invalid FeeType value");
        // effects
        (uint256 needFee, uint256 freeFee) = _calcReturnAmount(owner, feeAssets);
        if(feeType == FeeType.NFTOrder) {
            // nft交易佣金
            foundInfo.nftOrderEarning += needFee;
            foundInfo.feeFree += freeFee;
        } else if(feeType == FeeType.Withdraw) {
            foundInfo.withdrawEarning += needFee;
            foundInfo.feeFree += freeFee;
        }else if(feeType == FeeType.FlashLoan) {
            foundInfo.flashEarning += needFee;
            foundInfo.feeFree += freeFee;
        }
        if (freeFee > assets) {
            revert ("freeFee calc error!");
        }
        emit GetBenefit(feeAssets, feeType, assets, caller, owner);
        return freeFee;
    }
    // 计算免除的佣金金额, 返回：needFee（需要支付的佣金）；freeFee（免除的佣金）
    function _calcReturnAmount(address owner, uint256 feeAssets) private returns (uint256 needFee, uint256 freeFee) {
        // 免佣额度
        uint256 freeAmount = fundsAvailable[owner];
        if (freeAmount == 0) {
            needFee = feeAssets;
            freeFee = 0;
        }else {
            if (freeAmount > feeAssets) {
                // 可以直接全部免掉
                needFee = 0;
                freeFee = feeAssets;
                fundsAvailable[owner] = freeAmount-feeAssets;
            }else {
                // 可以部分免掉
                needFee = feeAssets - freeAmount;
                freeFee = freeAmount;
                delete fundsAvailable[owner];
            }
        }
    }
    


    // 2.3 基金池及费率相关
    // 免佣金额度修改
    function updateFundsAvailable(address account, uint256 _available) external onlyAdmin {
        if (_available <= fundsAvailable[account]) {
            revert ("fund available must be greater");
        }
        fundsAvailable[account] = _available;
    }
     // 免佣金额度查询
    function getFundsAvailable(address account) public view returns (uint256){
         return fundsAvailable[account];
    }

    // nftOrderfee修改: [0.5%, 5%]
    function changeNFTOrderFee(uint256 _nftOrderFee) external onlyAdmin {
        require(_nftOrderFee >= 5 && _nftOrderFee <= 50, "invalid nftOrderFee");
        uint256 oldFee = foundInfo.nftOrderFee;
        foundInfo.nftOrderFee = _nftOrderFee;
        emit NFTOrderFeeChange(oldFee, _nftOrderFee);
    }
    // withdrawFee修改: [0.2%, 3%]
    function changeWithdrawFee(uint256 _withdrawFee) external onlyAdmin {
        require(_withdrawFee >= 2 && _withdrawFee <= 30, "invalid withdrawFee");
        uint256 oldFee = foundInfo.withdrawFee;
        foundInfo.withdrawFee = _withdrawFee;
        emit WithdrawFeeChange(oldFee, _withdrawFee);
    }
    // flashFee修改: [0.01%, 0.1%]
    function changeFlashFee(uint256 flashFee) external onlyAdmin {
        require(flashFee >= 1 && flashFee <= 10, "invalid flashFee");
        uint256 oldFee = foundInfo.flashFee;
        foundInfo.flashFee = flashFee;
        emit WithdrawFeeChange(oldFee, flashFee);
    }
    // found信息查询
    function queryFoundInfo() external view returns(
        // nft订单抽成比例（千分比）
        uint256 nftOrderFee,
        // nft订单完成收益 
        uint256 nftOrderEarning, 
        // 基金取现抽成比例（千分比）
        uint256 withdrawFee,
        // 基金取现收益 
        uint256 withdrawEarning, 
        // 闪电贷抽成比例（万分比）
        uint256 flashFee, 
        // 闪电贷收益
        uint256 flashEarning, 
        // 免佣总和
        uint256 feeFree
    ) {
        nftOrderFee = foundInfo.nftOrderFee;
        nftOrderEarning = foundInfo.nftOrderEarning;
        withdrawFee = foundInfo.withdrawFee;
        withdrawEarning = foundInfo.withdrawEarning;
        flashFee = foundInfo.flashFee;
        flashEarning = foundInfo.flashEarning;
        feeFree = foundInfo.feeFree;
    }

    //三、资金池收益方案
    // 3.1 闪电贷相关
    // 闪电贷费用: 万分之五
    // 不指定flashFeeReceiver(受益人),目的是make the flash loan mechanism deflationary, 使代币价值上升：本质为闪电贷收益平分给所有基金持有者
    function _flashFee(address token, uint256 value) internal view override returns (uint256) {
        // silence warning about unused variable without the addition of bytecode.
        token;
        return value.mulDiv(foundInfo.flashFee, 10000, Math.Rounding.Ceil);
    }
    // 重写flashLoan，记录收益
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 value,
        bytes calldata data
    ) public override returns (bool) {
        // feeAssets为什么最开始计算：因为flashLoan会,执行_burn(fee)，导致previewMint()计算错误
        // 基金份额fee
        uint256 feeShares = flashFee(token, value);
        // 转换为资产价值: feeShares值多少eth
        uint256 feeAssets = previewMint(feeShares);
        bool success = super.flashLoan(receiver, token, value, data);
        if (success) {
            // 记录收益: 将assets(资产规模)设置为feeAssets：因为闪电贷没有资金规模; 并且这样可以避免因feeFree>assets问题导致的revert
            _processFeeAssets(feeAssets, FeeType.FlashLoan, feeAssets, _msgSender(), _msgSender());
        }
        return success;
    }
    // 3.2 todo 

    receive() external payable {
        if (msg.value > 0) {
            deposit(_msgSender());
        }
    }
    fallback() external payable {
        if (msg.value > 0) {
            deposit(_msgSender());
        }
    }
}
contract FlashLoanBorrower is IERC3156FlashBorrower {
    address public constant nftSwapAddress = 0x473E6A19aCff054ae6Ef353b71dBf300E76B40C4;
    address public constant lenderAddress = 0x473E6A19aCff054ae6Ef353b71dBf300E76B40C4;
    event OnFlashLoanEvent(address initiator, address token, uint256 amount, uint256 fee, bytes data, uint256 approveAmount);
    function testFlashLoan() external {
        // 相当于1w eth
        uint256 amount = 10000000000000000000000;
        IERC3156FlashLender(nftSwapAddress).flashLoan(IERC3156FlashBorrower(address(this)), nftSwapAddress, amount, "");
    }
    // 闪电贷回调
    function onFlashLoan(
        // flashLoan调用者
        address initiator,
        // ERC20代币合约地址
        address token,
        // 借出金额
        uint256 amount,
        // 费用
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {
        // use amount do sth
        // 假如有一个合约，transfer shares,会多返还万分之5的shares
        // 而flashLoan的手续费只有万分之3，那么，剩余的万分之2，就是本合约的了
        uint256 approveAmount = amount + fee;
        // approve(amount+fee)
        IERC20(nftSwapAddress).approve(lenderAddress, approveAmount);
        emit OnFlashLoanEvent(initiator, token, amount, fee, data, approveAmount);
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
}
