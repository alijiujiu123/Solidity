// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "contracts/structs/BitMaps.sol";
// 1. 可枚举: 可以根据index获取用户下的nft，或全局的ft。tokenOfOwnerByIndex()根据index获取具体地址下的tokenId；tokenByIndex()根据全局index获取tokenId
// 2. 可销毁
// 3. 可暂停：admin调用pause()，使所有nft转移操作（铸币，销毁，转账）停止执行
// 4. Merkle Proof空投（mint）: （1）leaft是作为keccak256的哈希值计算（2）merkleProofs的先后顺序问题，先leaf兄弟，后叔父
contract ERC721Airdrop is ERC721Enumerable,Pausable {
    using BitMaps for BitMaps.AddressBitMap;

    string private constant _name = "ERC721AirDropToken";
    string private constant _symbol = "EAT";
    bytes32 public _merkleRoot;
    address public admin;
    uint256 public tokenCounter;
    BitMaps.AddressBitMap private dropAddresses;

    error AirdropMerkleProofFailure();
    constructor() ERC721(_name, _symbol) {
        admin = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == admin, "only admin can access");
        _;
    }

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        // Setting an "auth" arguments enables the `_isAuthorized` check which verifies that the token exists
        // (from != 0). Therefore, it is not needed to verify that the return value is not 0 here.
        _update(address(0), tokenId, _msgSender());
    }

    /**
     * @dev See {ERC721-_update}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal virtual override whenNotPaused returns (address) {
        return super._update(to, tokenId, auth);
    }

    // 设置暂停状态
    function pause() external onlyOwner {
        super._pause();
    }

    // 取消暂停状态
    function unpause() external onlyOwner {
        super._unpause();
    }

    // 设置空投merkle root
    function addAirdropWithMerkleRoot(bytes32 _merkleRoot_) public onlyOwner {
        require(_merkleRoot_ != bytes32(0), "mint: merkle root must not be zero");
        // 设置 Merkle Root
        _merkleRoot = _merkleRoot_;
    }

    // admin派发nft
    function specificAirdropToken(address to) external onlyOwner returns (uint256){
        require(!dropAddresses.get(to),"already claimed");
        // 返回空投tokenId
        uint256 tokenId = tokenCounter++;
        _safeMint(to, tokenId);
        dropAddresses.set(to);
        return tokenId;
    }

    // 空投: 通过merkleProof领取
    // merkleProof空投发放
    // (一)设置merkleRoot
    // 1.生成merkle tree: 将发放名单地址列表通过https://lab.miguelmota.com/merkletreejs/example/ 生成merkle tree。（keccak-256, hashLeaves, sortPairs）
            //发放名单     ["0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2", "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db","0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB","0x617F2E2fD72FD9D5503197092aC168c91465E7f2"]
            // Tree
            // └─ fbaa96a1f7806c1ab06f957c8fc6e60875b6880254f77b71439c7854a6b47755              merkleRoot
            //    ├─ 39a01635c6a38f8beb0adde454f205fffbb2157797bf1980f8f93a5f70c9f8e6               parant1
            //    │  ├─ 999bf57501565dbd2fdcea36efa2b9aef8340a8901e3459f4a4c926275d36cdb                leaf1
            //    │  └─ 04a10bfd00977f54cc3450c9b25c9b3a502a089eba0097ba35fc33c4ea5fcb54                leaf2
            //    └─ da2a605bdf59a3b18e24cd0b2d9110b6ffa2340f6f67bc48214ac70e49d12770               parant2
            //       ├─ dfbe3e504ac4e35541bebad4d0e7574668e16fefa26cd4172f93e18b59ce9486                leaf3
            //       └─ f6d82c545c22b72034803633d3dda2b28e89fb704f3c111355ac43e10612aedc                leaf4
    // 2.保存merkleRoot: 调用addAirdropWithMerkleRoot(fbaa96a1f7806c1ab06f957c8fc6e60875b6880254f77b71439c7854a6b47755)
    // (二) 验证并领取merkleProof空投
    // 1. 生成merkleProofs: 如果要领取leaf4的nft空投，则merkleProofs为[leaf3, parant1]
    // 2. 切换leaf4账户，调用claimWithMerkleProof()
    // 3. 根据msg.sender(即leaf4账户)，keccak哈希计算出leaf4'
    // 4. leaf4通过和merkleProofs中的值，依次hash：
    //     hash(leaf4', merkleProofs[0]) -> parant2';   // merkleProofs[0] 即为leaf3
    //     hash(parant2', merkleProofs[1]) -> root'     // merkleProofs[1] 即为parant1
    // 5. 验证root': 如果通过还原出的root' == root, 验证通过并铸币给msg.sender
    function claimWithMerkleProof(bytes32[] calldata merkleProofs) external returns (uint256) {
        require(_merkleRoot != bytes32(0), "mint: must set merkle root");
        require(!dropAddresses.get(msg.sender),"already claimed");
        bytes32 leaf = bytes32(keccak256(abi.encodePacked(msg.sender)));
        if (!_verify(merkleProofs, _merkleRoot, leaf)) {
            revert AirdropMerkleProofFailure();
        }
        uint256 tokenId = tokenCounter++;
        _safeMint(msg.sender, tokenId);
        dropAddresses.set(msg.sender);
        return tokenId;
    }

    // 验证proof与leaf计算出的根值是否与root一致
    function _verify(bytes32[] calldata proof, bytes32 root, bytes32 leaf) private pure returns (bool) {
        return _processProof(proof, leaf) == root;
    }

    // 返回计算得出的root
    function _processProof(bytes32[] calldata proof, bytes32 leaf) private pure returns (bytes32) {
        bytes32 computeHash = leaf;
        for (uint i=0; i<proof.length; i++) {
            computeHash = commutativeKeccak256(computeHash, proof[i]);
        }
        return computeHash;
    }

    // 计算a,b的keccak256值
    function commutativeKeccak256(bytes32 a, bytes32 b) internal pure returns (bytes32 result) {
        return a<b ? efficientKeccak256(a, b) : efficientKeccak256(b, a);
    }

    function efficientKeccak256(bytes32 a, bytes32 b) internal pure returns (bytes32 value) {
        assembly ("memory-safe") {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }

    error SignatureVerificationFailure(string reason,address signer);

    // 签名验证空投发放
    // (一) 签名生成步骤：
    // 1.打包消息：调用getMessageHash(toAddress),根据待发放地址toAddress生成messageHash
    // 2.remix生成签名：通过admin账户生成messageHash的签名signature
    // 3.领取空投：切换领取地址toAddress, 调用claimWithSignature(signature)领取成功
    // (二)签名验证
    // 1.打包消息：将msg.sender打包为messageHash'
    // 2.生成以太坊签名: messageHash' -> ethMessageHash
    // 3.解析签名者地址：通过ethMessageHash和签名signature，解析还原签名者公钥signer
    // 4.验证signer：签名生成者为admin，铸币给msg.sender
    function claimWithSignature(bytes memory signature) external returns (uint256) {
        require(signature.length == 65, "Invalid signature length");
        require(!dropAddresses.get(msg.sender),"already claimed");
        // 生成以太坊签名
        bytes32 messageHash = getMessageHash(msg.sender);
        bytes32 ethMessageHash = getETHMessageHash(messageHash);
        // 还原签名
        address signer = _recoverSigner(ethMessageHash, signature);
        if (signer != admin) {
            revert SignatureVerificationFailure("signature must sign by admin", signer);
        }
        // mint
        uint256 tokenId = tokenCounter++;
        _safeMint(msg.sender, tokenId);
        dropAddresses.set(msg.sender);
        return tokenId;
    }

    function getMessageHash(address _address) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_address));
    }

    // 获取address的ethHash
    function getETHMessageHash(bytes32 hash) public pure returns (bytes32) {
        // 计算hash
        // bytes32 hash = keccak256(abi.encode(_address));
        // 计算ethHash
        bytes32 ethHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        return ethHash;
    }

    // 从签名中还原公钥
    function _recoverSigner(bytes32 messageHash, bytes memory signature) private pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            // mload(pos)     读取从pos开始的，后边的32byte
            // add(sig, 0x20)   返回sig向后移动0x20(即32)个字节的位置pos
            // signature的存储结构: 
            //      前32个字节[0, 31]存储bytes长度: 65; 
            //      第二个32个字节[32,63]存储r; 
            //      第三个32字节[64, 95]存储s; 
            //      最后一个32字节[96, 127]，仅96字节有效, 存储v, 其余字节([97,127])无效填充0x00
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            // byte(0, data)    取data中字节index为0的数据
            v := byte(0, mload(add(signature, 0x60)))
        }
        if (v < 27) {
            v += 27;
        }
        return ecrecover(messageHash, v, r, s);
    }
}
