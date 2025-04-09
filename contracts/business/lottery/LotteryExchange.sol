// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import {VRFConsumerBaseV2Plus} from "https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
// 使用教程：
    //一、创建Subscription
    // (1)https://vrf.chain.link/sepolia "Create Subscritopn"按钮点击创建subscription
    // (2)"My Subscriptions"列表点击进入创建的subscription进入详情页, 
    //      点击"Fund subscription"按钮，对subscription进行充值(供fulfillRandomWords回调使用)
    //二、部署合约
    // (1) 将subscriptionId作为构造函数传入，deploy部署合约
    // (2) 在Subscription详情页，点击"Add consumere"，将合约地址添加为consumer
    // 三、执行合约
    // (1) 点击runLottery()发送随机数请求，返回requestId并记录到lotteryId2requestId映射
    // (2) (在Subscription余额充足条件下),回到本合约fulfillRandomWords()，将随机数返回，并记录到requestId2RandomWord映射
    // (3) 根据requestId查询随机数结果(requestId2RandomWord映射): 50210254316309316729299686571855794543081318722424180858639112548232924921230
// 彩票
contract LotteryExchange is VRFConsumerBaseV2Plus {
    // chainlink VRF不同连参数信息：https://docs.chain.link/vrf/v2/subscription/supported-networks
    // subscriptId (构造函数初始化): 订阅账户
    uint256 s_subscriptionId;
    //Chainlink VRF Coordinator contract 地址（Sepolia测试网）
    address public vrfCoordinator = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B;
    // 愿意支付的最大gas price
    bytes32 s_keyHash = 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;
    // 定义的chainlink回调函数(fullfailRandomWords)最多能使用多少gas
    // 默认40000，适合轻量级逻辑
    uint32 callbackGasLimit = 200000;
    // request请求发出后，ChainLink节点等待多少要个区块确认后再响应
    uint16 requestConfirmations = 3;
    // 请求随机数的个数
    uint32 numWords =  1;
    address private admin;

    event FillRandomWordsEvent(uint256 requestId, uint256 randomWord);
    // 彩票期数
    bytes32 public currentLotteryId;
    // 彩票期数 -> requestId
    mapping(bytes32 lotteryId => uint256) public lotteryId2requestId;
    // requestId -> 随机数结果
    mapping(uint256 requestId => uint256) public requestId2RandomWord;

    // 传入subscriptionId初始化
    constructor1(uint256 subscriptionId) VRFConsumerBaseV2Plus(vrfCoordinator) {
        s_subscriptionId = subscriptionId;
        admin = msg.sender;
        currentLotteryId = bytes32(block.timestamp);
    }
    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin can do");
        _;
    }
    // todo 购买彩票：需要在请求随机数之前（开奖之前）
    // 生成中奖号码
    function runLottery() external onlyAdmin returns (uint256 requestId) {
        require(lotteryId2requestId[currentLotteryId] == 0, "Already lottery");
        // 发起随机数请求
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: s_keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                // nativePayment：false(默认LINK支付)；true(ETH支付)
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
            })
        );
        // 保存requestId
        lotteryId2requestId[currentLotteryId] = requestId;
    }
    // 随机数生成结果回调
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        requestId2RandomWord[requestId] = randomWords[0];
        emit FillRandomWordsEvent(requestId, randomWords[0]);
        // 开启下一期
        currentLotteryId = bytes32(block.timestamp);
    }
    // todo 查询中奖号码

}
