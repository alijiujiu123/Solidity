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
    constructor1() ERC721(_name, _symbol) {
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
    function addAirdropClaimed(bytes32 _merkleRoot_) public onlyOwner {
        require(_merkleRoot_ != bytes32(0), "mint: merkle root must not be zero");
        // 设置 Merkle Root
        _merkleRoot = _merkleRoot_;
    }

    // admin派发nft
    function claimToken(address to) external onlyOwner returns (uint256){
        require(!dropAddresses.get(to),"already claimed");
        // 返回空投tokenId
        uint256 tokenId = tokenCounter++;
        _safeMint(to, tokenId);
        dropAddresses.set(to);
        return tokenId;
    }

    // 空投
    function airdrop(bytes32[] calldata merkleProofs) external returns (uint256) {
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
}
