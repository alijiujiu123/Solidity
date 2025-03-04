// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Utils.sol";
import "contracts/structs/BitMaps.sol";
contract DutchAuctionHouse is IERC721Receiver {
    using BitMaps for BitMaps.AddressBitMap;
    // 拍卖品不在可信白名单内
    error UnsupportedToken(address nftAddress);
    error UnreceivedToken(address nftAddress, uint256 tokenId);
    error InvalidAuctionParameters(string reason);
    error AuctionItemNotFound(uint256 itemId);
    error AuctionPriceNotEnough(uint256 auctionPrice, uint256 msgValue);
    error AuctionItemAlreadySale();
    error WithdrawCallFail(address seller, uint256 amount);
    // 收到ERC721
    event ERC721Received(address indexed operator, address from, uint256 indexed tokenId, uint256 indexed itemId, bytes data);
    // 拍卖成功
    event BidSuccess(address indexed bider, address indexed seller, uint256 price, uint256 itemId);
    event NFTSupportAdded(address indexed nftAddress);
    event NFTSupportRemoved(address indexed nftAddress);
    // 拍卖品
    struct AuctionItem{
        // uint256 itemId;
        // 1.拍卖品数据
        IERC721 nftContract;
        uint256 tokenId;
        address seller;
        // 2. 拍卖价格数据
        // 起拍价(最高价)
        uint256 startPrice;
        // 结束价(最低价)
        uint256 endPrice;
        // 拍卖开始时间
        uint256 startTime;
        // 拍卖持续时间
        uint256 duringTime;
        // 价格衰减周期
        uint256 dropInterval;
        // 衰减步长
        uint256 stepPrice;
        // 3. 买家数据
        address bider;
        uint256 auctionPrice;
    }
    uint256 public nextItemId = 0;
    // 卖家 -> 拍卖品映射
    // mapping(address seller => AuctionItem[]) sellerAuctionItems;
    // 拍卖品id -> 拍卖品信息
    mapping(uint256 itemId => AuctionItem) public auctionItems;
    mapping(address nftAddress => mapping(uint256 tokenId => uint256)) public tokenIdToItemIds;
    mapping(address seller => uint256) private sellerBalance;
    uint256 private profits;
    uint256 public feeRate;
    // nft可信白名单
    BitMaps.AddressBitMap private nftWhiteList;
    address public admin;

    constructor1() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "not authorized");
        _;
    }

    // 添加nft白名单
    function addNFTSupport(address _nftAddress) external onlyAdmin {
        require(_nftAddress != address(0), "invalid nft address");
        if (address(this) == _nftAddress) revert UnsupportedToken(_nftAddress);
        require(!nftWhiteList.get(_nftAddress),"already exists in whitelist");
        // 校验是否为ERC721
        require(IERC721(_nftAddress).supportsInterface(type(IERC721).interfaceId), "invalid nft type");
        // 拍卖品白名单
        nftWhiteList.set(_nftAddress);
        emit NFTSupportAdded(_nftAddress);
    }
    // 移除nft白名单
    function removeNFTSupport(address _nftAddress) external onlyAdmin {
        require(_nftAddress != address(0), "invalid nft");
        // 拍卖品白名单
        nftWhiteList.unset(_nftAddress);
        emit NFTSupportRemoved(_nftAddress);
    }
    function _addressTouint256(address _address) private pure returns (uint256) {
        return uint256(uint160(_address));
    }

    // 上架拍卖品: 需要提前将拍卖品转到拍卖合约中
    function createAuction(
        uint256 itemId,
        // 起拍价(最高价)
        uint256 _startPrice,
        // 结束价(最低价)
        uint256 _endPrice,
        // 拍卖开始时间
        uint256 _startTime,
        // 拍卖持续时间
        uint256 _duringTime,
        // 价格衰减间隔
        uint256 _dropInterval
    ) external {
        // checks
        if (_endPrice > _startPrice) {
            revert InvalidAuctionParameters("end price must not be greater than start price.");
        }
        address sellerAddress = auctionItems[itemId].seller;
        if (sellerAddress != msg.sender) {
            revert InvalidAuctionParameters("can not create auction, the nft not from yourself.");
        }
        // 检查未被拍走
        _checkItemNotSale(itemId);
        // effects
        auctionItems[itemId].startPrice = _startPrice;
        auctionItems[itemId].endPrice = _endPrice;
        auctionItems[itemId].startTime = _startTime;
        auctionItems[itemId].duringTime = _duringTime;
        auctionItems[itemId].dropInterval = _dropInterval;
        auctionItems[itemId].stepPrice = (_startPrice-_endPrice) / (_duringTime/_dropInterval);
    }

    // 接收拍卖品
    function onERC721Received(address operator, address from, uint256 _tokenId, bytes memory data) public virtual returns (bytes4) {
        address nftAddress = msg.sender;
        _checkNFTWhiteList(nftAddress);
        _checkOwner(nftAddress, _tokenId);
        // 加入拍卖
        nextItemId++;
        _addAuctionItem(nftAddress, _tokenId, operator, nextItemId);
        emit ERC721Received(operator, from, _tokenId, nextItemId, data);
        return IERC721Receiver.onERC721Received.selector;
    }

    // 检查是否在nft支持白名单
    function _checkNFTWhiteList(address nftAddress) private view {
        if (!nftWhiteList.get(nftAddress)) {
            // 不在白名单
            revert UnsupportedToken(nftAddress);
        }
    }

    // 校验nftAddress.tokenId是否已交易成功
    function _checkOwner(address nftAddress, uint256 tokenId) private view {
        if(IERC721(nftAddress).ownerOf(tokenId) != address(this)) {
            revert UnreceivedToken(nftAddress, tokenId);
        }
    }

    // 添加拍卖品数据
    function _addAuctionItem(address _nftAddress, uint256 _tokenId, address _seller, uint256 _itemId) private {
        // itemId -> AuctionItem数据
        auctionItems[nextItemId].nftContract = IERC721(_nftAddress);
        auctionItems[nextItemId].tokenId = _tokenId;
        auctionItems[nextItemId].seller = _seller;
        // nft.tokenId -> itemId数据
        tokenIdToItemIds[_nftAddress][_tokenId] = _itemId;
    }

    // 通过nft合约地址，tokenId查询itemId
    function getItemId(address nftAddress, uint256 tokenId) external returns (uint256) {
        if (tokenIdToItemIds[nftAddress][tokenId] != 0) {
            // 通过safeTransfer或safeTransferFrom交易，直接返回itemId
            return tokenIdToItemIds[nftAddress][tokenId];
        } else {
            // 通过transfer或transferFrom交易，先添加拍卖品item数据后返回
            return recoverAtuctionItem(nftAddress, tokenId);
        }
    }

    // 如果不是通过safeTransfer或safeTransferFrom交易nft，手动添加拍卖品信息, 返回itemId
    function recoverAtuctionItem(address nftAddress, uint256 tokenId) public returns (uint256) {
        // 有拍卖品信息
        if (tokenIdToItemIds[nftAddress][tokenId] != 0) {
            return tokenIdToItemIds[nftAddress][tokenId];
        }
        // checks
        _checkNFTWhiteList(nftAddress);
        _checkOwner(nftAddress, tokenId);
        // effects
        nextItemId++;
        _addAuctionItem(nftAddress, tokenId, msg.sender, nextItemId);
        return nextItemId;
    }
    // 通过nftAddress, tokenId查询当前拍卖itemId
    function auctionItemIdByTokenId(address nftAddress, uint256 tokenId) external view returns (uint256) {
        _checkNFTWhiteList(nftAddress);
        _checkOwner(nftAddress, tokenId);
        uint256 itemId = tokenIdToItemIds[nftAddress][tokenId];
        if (auctionItems[itemId].seller != msg.sender) {
            revert AuctionItemNotFound(0);
        }
        return itemId;
    }

    // 查询拍卖价格
    function getAuctionPrice(uint256 itemId) public view returns (uint256) {
        // 是否存在item
        _checkItemExists(itemId);
        // 是否已被拍走
        _checkItemNotSale(itemId);
        uint256 _startPrice = auctionItems[itemId].startPrice;
        uint256 _endPrice = auctionItems[itemId].endPrice;
        uint256 _startTime = auctionItems[itemId].startTime;
        uint256 _duringTime = auctionItems[itemId].duringTime;
        uint256 _dropInterval = auctionItems[itemId].dropInterval;
        uint256 _stepPrice = auctionItems[itemId].stepPrice;
        uint256 auctionPrice = 0;
        if (block.timestamp <= _startTime) {
            auctionPrice = _startPrice;
        }else if (block.timestamp >= (_startTime+_duringTime)) {
            auctionPrice = _endPrice;
        }else {
            uint256 steps = (block.timestamp-_startTime)/_dropInterval;
            auctionPrice = _startPrice-_stepPrice*steps;
        }
        return auctionPrice;
    }

    // 检查auctionItem是否存在
    function _checkItemExists(uint256 itemId) private view {
        if (auctionItems[itemId].seller == address(0)) {
            revert AuctionItemNotFound(itemId);
        }
    }
    // 检查item未被竞拍走
    function _checkItemNotSale(uint256 itemId) private view {
        if (auctionItems[itemId].bider != address(0)) {
            revert AuctionItemAlreadySale();
        }
    }

    // 竞拍
    function bidAuction(uint256 itemId) external payable {
        // checks
        _checkItemExists(itemId);
        // 检查是否开始
        if (block.timestamp < auctionItems[itemId].startTime) {
            revert InvalidAuctionParameters("auction not started yet");
        }
        // 检查未被拍走
        _checkItemNotSale(itemId);
        // 检查金额
        uint256 auctionPrice = getAuctionPrice(itemId);
        if (msg.value < auctionPrice) {
            revert AuctionPriceNotEnough(auctionPrice, msg.value);
        }
        // effects
        auctionItems[itemId].bider = msg.sender;
        auctionItems[itemId].auctionPrice = auctionPrice;
        IERC721 nftContract = auctionItems[itemId].nftContract;
        uint256 tokenId = auctionItems[itemId].tokenId;
        delete tokenIdToItemIds[address(nftContract)][tokenId];
        // 卖家收益
        address seller = auctionItems[itemId].seller;
        uint256 profit = calcProfit(auctionPrice);
        profits += profit;
        sellerBalance[seller] += (auctionPrice-profit);
        // interactions
        auctionItems[itemId].nftContract.safeTransferFrom(address(this), msg.sender, tokenId);
        // 退款
        if (msg.value > auctionPrice) {
            payable(msg.sender).transfer(msg.value - auctionPrice);
        }
    }

    // 根据拍卖价格计算抽成
    function calcProfit(uint256 price) internal view returns (uint256) {
        return (price * feeRate) / 10000;
    }
    // 设置抽成比例
    function setFeeRate(uint256 _feeRate) external onlyAdmin {
        require(_feeRate <= 2000, "fee rate too high"); // 限制最高 20%
        feeRate = _feeRate;
    }

    // 查询卖家账户余额
    function getBalance() external view returns (uint256) {
        return sellerBalance[msg.sender];
    }

    // 卖家取现
    function withdraw() external {
        address _sender = msg.sender;
        uint256 _balance = sellerBalance[msg.sender];
        // checks
        if (_balance == 0) {
            revert ("you have no balance");
        }
        // effects
        sellerBalance[_sender] = 0;
        // interactions
        (bool success, ) = payable(_sender).call{value: _balance}("");
        if (!success) {
            revert WithdrawCallFail(_sender, _balance);
        }
    }

    // 取回nft
    function getBackNft(address nftAddress, uint256 tokenId, address receiver) external {
        // checks
        _checkNFTWhiteList(nftAddress);
        _checkOwner(nftAddress, tokenId);
        // effects
        // 有两种情况：只接受到，未添加item；已添加item
        uint256 itemId = tokenIdToItemIds[nftAddress][tokenId];
        if (itemId != 0) {
            _checkItemNotSale(itemId);
            if (block.timestamp > (auctionItems[itemId].startTime + auctionItems[itemId].duringTime)) {
                delete auctionItems[itemId].seller;
                delete tokenIdToItemIds[nftAddress][tokenId];
            }else {
                revert ("can not cancel now");
            }
        }
        // interactions
        IERC721(nftAddress).safeTransferFrom(address(this), receiver, tokenId);
    }

    function getProfits() external view onlyAdmin returns (uint256) {
        return profits;
    }

    // 管理员收益
    function send() external onlyAdmin {
        uint256 amount = profits;
        profits = 0;
        payable(admin).transfer(amount);
    }

}

contract TestTimestamp {
    function getTimeStamp() external view returns (uint256 current, uint256 future) {
        current = block.timestamp;
        future = block.timestamp + 60;
    }
}

contract TestETH {
    function getETH() external pure returns (uint256) {
        return 1 ether;
    }
}
