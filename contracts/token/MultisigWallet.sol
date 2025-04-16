// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
// 多签钱包
contract MultisigWallet {
    // 事件
    // 钱包创建
    event WalletCreated(address[] owners, uint256 threshold, uint256 balance, bytes32 indexed walletId);
    // 钱包充值
    event WalletRecharged(bytes32 indexed walletId, uint256 amount);
    // 多签转账成功
    event TransferExecutedSuccess(bytes32 indexed walletId, bytes32 indexed txHash);
    // 多签转账失败
    event TransferExecutedFailure(bytes32 indexed walletId, bytes32 indexed txHash);
    // 钱包定义
    struct WalletInfo{
        address[] owners;   // 多签持有人数组
        mapping(address ownerAddress => bool) isOwner;  // 是否为多签持有人
        uint256 threshold;  // 签名个数阈值：至少threshold个地址签名才能被执行
        uint256 nonce;      // nonce，防止签名重放攻击
        uint256 balance;     // 钱包余额
    }
    // walletId -> 钱包数据
    mapping(bytes32 walletId => WalletInfo) private walletInfos;
    // 查询钱包信息
    function walletInfo(bytes32 walletId) public view returns (address[] memory owners, uint256 threshold, uint256 nonce ,uint256 balance) {
        require(_walletExists(walletId), "walletInfo: wallet not exists");
        owners = walletInfos[walletId].owners;
        threshold = walletInfos[walletId].threshold;
        nonce = walletInfos[walletId].nonce;
        balance = walletInfos[walletId].balance;
    }
    // 查询钱包余额
    function walletBalance(bytes32 walletId) public view returns (uint256) {
        require(_walletExists(walletId), "walletBalance: wallet not exists");
        return walletInfos[walletId].balance;
    }
    // 钱包充值
    function walletRecharge(bytes32 walletId) external payable{
        // checks
        require(_walletExists(walletId), "walletRecharge: wallet not exists");
        require(msg.value > 0, "walletRecharge: payment required");
        // effects
        walletInfos[walletId].balance += msg.value;
        emit WalletRecharged(walletId, msg.value);
    }
    // 钱包是否存在: 不存在false；存在true
    function _walletExists(bytes32 walletId) private view returns (bool) {
        if (walletInfos[walletId].threshold == 0) {
            return false;
        }
        return true;
    }
    // 创建多签钱包，初始化
    function createWallet(address[] memory _owners, uint256 _threshold) public payable returns (bytes32) {
        // checks
        uint256 length = _owners.length;
        require(length > 0, "createWallet: empty address");
        require(_threshold > 0, "createWallet: threshold must positive");
        require(_threshold <= length, "createWallet: threshold more than owners length");
        bytes32 walletId = remeberWalletAddress(_owners);
        // 检查钱包id是否存在
        require(!_walletExists(walletId), "createWallet: wallet exist!");
        // effects
        for (uint256 i=0; i< length; i++) {
            address currentOwner = _owners[i];
            require(currentOwner != address(0) 
                && currentOwner != address(this) 
                && !walletInfos[walletId].isOwner[currentOwner], 
                "createWallet: duplicated address");
            walletInfos[walletId].owners.push(currentOwner);
            walletInfos[walletId].isOwner[currentOwner] = true;
        }
        walletInfos[walletId].threshold = _threshold;
        walletInfos[walletId].balance = msg.value;
        emit WalletCreated(_owners, _threshold, msg.value, walletId);
        return walletId;
    }
    // 查询钱包地址
    function remeberWalletAddress(address[] memory _owners) public pure returns (bytes32) {
        uint256 length = _owners.length;
        require(length > 0, "createWallet: empty address");
        // 排序_owners
        _owners = sortOwners(_owners);
        // 判断是否有重复
        for (uint256 i = 0; i < length - 1; i++) {
            if (_owners[i] == _owners[i + 1]) {
                // 重复
                revert("remeberWalletAddress: duplicated address");
            }
        }
        // 计算hash
        return keccak256(abi.encodePacked(_owners));
    }
    // owner排序
    function sortOwners(address[] memory _owners) public pure returns (address[] memory) {
        uint256 length = _owners.length;
        // 排序_owners
        for (uint256 i = 0; i < length; i++) {
            for (uint256 j = 0; j < length - 1; j++) {
                if (_owners[j] > _owners[j + 1]) {
                    address temp = _owners[j];
                    _owners[j] = _owners[j + 1];
                    _owners[j + 1] = temp;
                }
            }
        }
        return _owners;
    }
    // 执行转账交易
    function executeTransaction(
        bytes32 walletId,
        // 转账接收地址
        address to,
        // eth转账金额
        uint256 value,
        // 转账calldata
        bytes memory data,
        // 签名：{bytes32 sig1_r}{bytes32 sig1_s}{uint8 sig1_v}{bytes32 sig2_r}{bytes32 sig2_s}{uint8 sig2_v}
        bytes memory signatures
    ) public returns (bool) {
        // checks
        require(_walletExists(walletId), "executeTransaction: wallet not exists");
        require(walletInfos[walletId].balance >= value, "insufficient balance");
        // 编码交易数据
        bytes32 txHash = encodeTransactionData(walletId, to, value, data, walletInfos[walletId].nonce, block.chainid);
        // effects
        walletInfos[walletId].nonce++;
        walletInfos[walletId].balance -= value;
        // 签名检查
        checkSignatures(walletId, txHash, signatures);
        // interactions
        (bool success, ) = to.call{value: value}(data);
        require(success, "executeTransaction: call fail");
        if (success) {
            emit TransferExecutedSuccess(walletId, txHash);
        }else {
            emit TransferExecutedFailure(walletId, txHash);
        }
        return success;
    }
    // 计算交易hash
    function encodeTransactionData(
        // 钱包id
        bytes32 walletId, 
        // 转账接收方地址
        address to, 
        // 转账金额
        uint256 value, 
        // callData
        bytes memory data, 
        // 防止重放攻击nonce值
        uint256 nonce,
        // 防止跨链重放攻击
        uint chainId
    ) public pure returns (bytes32){
        return keccak256(
            abi.encode(
                walletId,
                to,
                value,
                data,
                nonce,
                chainId
            )
        );
    }
    // 签名检查：检查失败revert
    function checkSignatures(bytes32 walletId, bytes32 txHash, bytes memory signatures) public view {
        uint256 _threshold = walletInfos[walletId].threshold;
        require(_threshold > 0, "checkSignatures: threshold must positive");
        require(signatures.length >= _threshold*65, "checkSignatures: signatures length not enough");
        // 循环检查每一个签名是否有效
        // 1. ecdsa验证签名,解析签名地址
        // 2. 多签签名地址递增，保证来自多个地址签名
        // 3. 保证每个签名都为钱包合法owner
        address lastOwner = address(0);
        bytes32 r;
        bytes32 s;
        uint8 v;
        // 只需要验证满足需要的签名个数就够了
        for (uint256 i=0; i<_threshold; i++) {
            // 解析签名地址
            (r, s, v) = sigSplit(signatures, i);
            address currentOwner = ecrecover(
                keccak256(
                    abi.encodePacked("\x19Ethereum Signed Message:\n32", txHash)
                ), 
                v, r, s);
                require(currentOwner > lastOwner && walletInfos[walletId].isOwner[currentOwner], "checkSignatures: ecrecover address error");
                lastOwner = currentOwner;
        }
    }
    // 签名分解
    function sigSplit(
        // 打包多个签名
        bytes memory _signatures, 
        // 取第pos个签名
        uint256 pos
    ) public pure returns (
        // 签名解析结果
        bytes32 r, 
        bytes32 s, 
        uint8 v
    ){
        assembly {
            // signatures(bytes)内存布局:[0x20 length| sig1_r bytes32 | sig1_s bytes32 | sig1_v uint8 | sig2_r | sig2_s | sig2+v...]
            // 计算第pos个签名的相对地址，每个signature的长度为65字节(0x41), 布局:[r bytes32 | s bytes32 | v uint8]
            let sigPos := mul(0x41, pos)
            // 取signatures[pos]前32个字节: signatures + 0x20(length) + sigpos
            r := mload(add(_signatures, add(sigPos, 0x20)))
            // 取signatures[pos]中间32个字节: signatures + 0x20(length) + sigpos + 0x20(signatures[pos]的前32个字节)
            s := mload(add(_signatures, add(sigPos, 0x40)))
            // v占1个字节，后31位为字节填充；
            // mload()为获取32个字节，and(data, 0xff)：按位与取最低8位(000....xxxx xxxx) & (1111 1111) = xxxx xxxx
            v := and(mload(add(_signatures, add(sigPos, 0x41))), 0xff)

            // 完全等价于
            // let sigPosOff := add(add(_signatures, 0x20), mul(0x41, pos))
            // r := mload(sigPosOff)
            // s := mload(add(sigPosOff, 0x20))
            // v := and(mload(add(sigPosOff, 0x40)), 0xff)
        }
    }
}
/*
// 测试用例
// 1.创建钱包：createWallet(同时msg.value=5 eth)
["0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB","0x617F2E2fD72FD9D5503197092aC168c91465E7f2","0x17F6AD8Ef982297579C203069C1DbfFE4348c372","0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678","0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7"], 3
// 钱包地址
0xe2b98d128f224aecebd1109af939fdc353c8ea030d64d1f7a40be28c56c610ba
// 2. 查询钱包信息：walletInfo
0xe2b98d128f224aecebd1109af939fdc353c8ea030d64d1f7a40be28c56c610ba
// 返回
	owners: [x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7,0x17F6AD8Ef982297579C203069C1DbfFE4348c372,0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678,0x617F2E2fD72FD9D5503197092aC168c91465E7f2,0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB]
	threshold: 3
	nonce: 0
	balance: 5000000000000000000

// 3.钱包充值：walletRecharge
 0xe2b98d128f224aecebd1109af939fdc353c8ea030d64d1f7a40be28c56c610ba
 msg.vaue: 3 ETH
// 4. 余额查询：walletBalance
0xe2b98d128f224aecebd1109af939fdc353c8ea030d64d1f7a40be28c56c610ba
// 返回
8000000000000000000
// 5. 多签转账：executeTransaction
// 参数：
	walletId: 0xe2b98d128f224aecebd1109af939fdc353c8ea030d64d1f7a40be28c56c610ba
	to: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
	value: 2000000000000000000
	data: 0x
	signatures: 
	// 多签生成：
	// 1. 根据交易参数生成交易hash：encodeTransactionData(), 返回：
	0x7d69292cfe704dd9b17fa5fdbbae1ffb05ea7b324ab24e1a85db4f4b60fd2818
	// 2.将加密hash按owners地址顺序签名（可通过sortOwners排序地址）
		0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7,
		0x17F6AD8Ef982297579C203069C1DbfFE4348c372,
		0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678,
		0x617F2E2fD72FD9D5503197092aC168c91465E7f2,
		0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
	// 如何签名：
		REMIX "ACCOUNT" -> "Sign using this account";
		输入交易hash，-> "sign" -> "SIGNATURE"得到签名结果
	// 签名结果：
		0x17F6AD8Ef982297579C203069C1DbfFE4348c372: 
			0xd01c43b189b19ef234555dd3312682705929cd707bbf87ba9c293c4cde94f5732e63dcdcbf4b86b6ab9d895be04c5dd35f38241adcf86581cf05ca98ef4182e61b
		0x617F2E2fD72FD9D5503197092aC168c91465E7f2:
			0x0ad6479d88fece103622dcb9691ec22d09e84bee9e71a09982ded54c3b25b7a27968bacff9515500e354a7467c4bd1cbae181ed3f546f198439154f49a2b9a7c1b
		0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB:
			0x02460d79ce223e88ffb345273771234314a971c6ac244f6723e6cef0b008c2e43a3b10a3bbc39e6bc6d71426cb105dd592669bfa225b92766f817153da77bf1f1b
		合并：
			0xd01c43b189b19ef234555dd3312682705929cd707bbf87ba9c293c4cde94f5732e63dcdcbf4b86b6ab9d895be04c5dd35f38241adcf86581cf05ca98ef4182e61b0ad6479d88fece103622dcb9691ec22d09e84bee9e71a09982ded54c3b25b7a27968bacff9515500e354a7467c4bd1cbae181ed3f546f198439154f49a2b9a7c1b02460d79ce223e88ffb345273771234314a971c6ac244f6723e6cef0b008c2e43a3b10a3bbc39e6bc6d71426cb105dd592669bfa225b92766f817153da77bf1f1b

// 结果验证：
	// 1. to地址余额
	0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
	balance: 84.9 eth -> 86.9 eth
	// 2. walletInfo
		nonce: 1
		balance: 6000000000000000000
// 6. 找回钱包地址：remeberWalletAddress
// ["0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB","0x617F2E2fD72FD9D5503197092aC168c91465E7f2","0x17F6AD8Ef982297579C203069C1DbfFE4348c372","0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678","0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7"]
// 返回：
	0xe2b98d128f224aecebd1109af939fdc353c8ea030d64d1f7a40be28c56c610ba
*/
