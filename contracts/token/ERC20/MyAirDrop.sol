// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// 空投合约实现: 
// 1.批量空投: owner权限
// 2.可领取空投: a.设置用户额度，owner权限; b.查询空投额度; c.领取空投额度
contract MyAirDrop {
    // 批量空投owner
    address public owner;
    // 空投代币合约
    IERC20 public immutable tokenContract;
    // 可领取空投总额度
    uint256 private claimSum;
    // 可领取空投账户额度
    mapping(address => uint256) private airdropAmounts;
    // 构造方法传入token合约
    constructor1(IERC20 _tokenContract) {
        owner = msg.sender;
        tokenContract = _tokenContract;
    }

    // onlyOwner modifier
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert("Only owner can access");
        }
        _;
    }

    // 批量转账
    function airdropTokens(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
        // checks
        if (recipients.length != amounts.length) {
            revert("Mismatched array lenths");
        }
        for(uint256 i=0; i<recipients.length; i++) {
            if (!tokenContract.transfer(recipients[i], amounts[i])) {
                revert("Transfer failed");
            }
        }
    }

    // 设置可领取额度
    function airdropAmount(address user, uint256 amount) external onlyOwner {
        // check balance
        if (amount > airdropAmounts[user]) {
            // 增加额度：判定总额度是否超过持有代币数
            uint256 newClaimSum = claimSum + (amount - airdropAmounts[user]);
            if (newClaimSum > tokenContract.balanceOf(address(this))) {
                revert("Token balance insufficient");
            }
            claimSum = newClaimSum;
        }else {
            // 减少额度
            claimSum -= (airdropAmounts[user]-amount);
        }
        // effects
        airdropAmounts[user] = amount;
    }
    // 可领取空投额度
    function claimAmount() external view returns (uint256) {
        return airdropAmounts[msg.sender];
    }
    // 领取空投
    function claim() external returns (uint256) {
        uint256 amount = airdropAmounts[msg.sender];
        // checks
        if (amount > 0) {
            // effects
            airdropAmounts[msg.sender] = 0;
            // interactions
            tokenContract.transfer(msg.sender, amount);
        }
        return amount;
    }
}
