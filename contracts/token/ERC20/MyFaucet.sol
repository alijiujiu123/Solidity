// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract MyFaucet {
    error RequestMultipleTimes(address requester);
    error FaucetEmpty();

    event SendTokens(address requester, uint256 amount);

    // IERC20合约地址
    IERC20 private immutable tokenContract;
    // 每次发放的token数量
    uint256 public constant amountAllowed = 100;
    // 领取的人
    mapping(address => bool) requestedAddress;

    // token代币合约
    constructor1(IERC20 _tokenContract) {
        tokenContract = _tokenContract;
    }

    // 用户领取代币
    function requestTokens() external {
        // checks
        if (requestedAddress[msg.sender]) {
            revert RequestMultipleTimes(msg.sender);
        }
        if (tokenContract.balanceOf(address(this)) < amountAllowed) {
            revert FaucetEmpty();
        }
        // effects
        requestedAddress[msg.sender] = true;
        // interactions
        tokenContract.transfer(msg.sender, amountAllowed);
        emit SendTokens(msg.sender, amountAllowed);
    }

    function balanceOf() external view returns (uint256) {
        return tokenContract.balanceOf(address(this));
    }
}
