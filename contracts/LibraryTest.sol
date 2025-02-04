// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Arrays.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol";
import "contracts/LogLibrary.sol";
import "contracts/structs/LinkedList.sol";
contract LibraryTest {
    // 日志
    using LogLibrary for *;
    // 1. Strings
    // 返回uint256的字符串
    function getString(uint256 value) external pure returns (string memory) {
        // 两种库函数使用方式
        // a. 直接使用库合约名显式调用
        return Strings.toString(value);
    }
    // 2. Address
    // b. 使用using for将库合约函数指定到指定变量类型上
    using Address for address;
    function staticcall(uint256 tokenId) external view returns (address) {
        //Address库函数 对view/pure方法进行调用（内部封装<address>.staticcall） function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory)
        // 1. 构建参数
        // nft合约地址
        address nftAddress = address(0x176d1aB02Adf27C0c1478ca731C68252D2B6a762);
        // 根据tokenId获取拥有者地址: function ownerOf(uint256 tokenId) public view virtual returns (address)
        // 构建参数
        bytes memory data = abi.encodeWithSignature("ownerOf(uint256)", tokenId);
        // 2. 执行库函数调用：执行ownerOf方法调用，只有success为true，functionStaticCall才会不revert，正常返回returnData
        // 相当于Address.functionStaticCall(nftAddress, data)
        bytes memory returnData = nftAddress.functionStaticCall(data);
        // 3. 解析返回数据
        address ownerAddress = abi.decode(returnData, (address));
        return ownerAddress;
    }
    // 3. Arrays
    // c.使用using xxx for * :将库合约内所有函数声明的第一个参数类型，加上库函数
    using Arrays for *;
    function sort(uint256[] memory nums) external pure returns (uint256[] memory) {
        // 排序，归并排序，原地排序：function sort(uint256[] memory array) internal pure returns (uint256[] memory)
        return nums.sort();
    }
    // 4. EnumerableSet 可枚举集合（支持AddressSet、Bytes32Set、UintSet）（内部为自定义结构体：（1）保存实际值的动态数组；（2）保存值 -> index的映射）
    using EnumerableSet for *;
    // enumerableSet状态变量（storage存储）
    EnumerableSet.UintSet uintSet;
    function enumerableSetTest() external {
        // function add(UintSet storage set, uint256 value) internal returns (bool)
        uintSet.add(1);
        uintSet.add(3);
        uintSet.add(2);
        uintSet.add(4);
        // function values(UintSet storage set) internal view returns (uint256[] memory)
        "add(1,3,2,4)".printUint256ArrayLog(uintSet.values());
        // function remove(UintSet storage set, uint256 value) internal returns (bool)
        uintSet.remove(1);
        // 这里根据源码显示，会变成[4,3,2]: （1）先找到1的index；（2）交换1和最后一个元素；（3）移除最后一个元素pop()
        "remove(1)".printUint256ArrayLog(uintSet.values());
        // function contains(UintSet storage set, uint256 value) internal view returns (bool)
        "contains(3): ".printBoolLog(uintSet.contains(3));
        // function length(UintSet storage set) internal view returns (uint256)
        "length(): ".printUint256Log(uintSet.length());
        // function at(UintSet storage set, uint256 index) internal view returns (uint256)
        "at(2): ".printUint256Log(uintSet.at(2));
    }
    // 5. EnumerableMap
    using EnumerableMap for *;
    // 5.1 支持的类型如下
    // UintToAddressMap, AddressToUintMap, Bytes32ToBytes32Map, UintToUintMap, Bytes32ToUintMap, UintToBytes32Map, AddressToAddressMap, AddressToBytes32Map, Bytes32ToAddressMap
    // enumerableMap状态变量（storage存储）(内部自定义结构体：（1）EnumerableSet保存key；（2）mapping保存key->value的关系)
    EnumerableMap.UintToUintMap uint2uintMap;
    function enumerableMapTest() external {
        // function set(UintToUintMap storage map, uint256 key, uint256 value) internal returns (bool)
        uint2uintMap.set(1, 101);
        uint2uintMap.set(2, 102);
        uint2uintMap.set(3, 103);
        uint2uintMap.set(4, 104);
        // function keys(UintToUintMap storage map) internal view returns (uint256[] memory)
        "set(1:101,2:102,3:103,4:103),keys:".printUint256ArrayLog(uint2uintMap.keys());
        // function remove(UintToUintMap storage map, uint256 key) internal returns (bool)
        uint2uintMap.remove(2);
        // 这里应该是1,4,3 
        "remove(2),keys:".printUint256ArrayLog(uint2uintMap.keys());
        // function contains(UintToUintMap storage map, uint256 key) internal view returns (bool)
        "contains(1)".printBoolLog(uint2uintMap.contains(1));
        "contains(2)".printBoolLog(uint2uintMap.contains(2));
        // function length(UintToUintMap storage map) internal view returns (uint256)
        "length(): ".printUint256Log(uint2uintMap.length());
        // function at(UintToUintMap storage map, uint256 index) internal view returns (uint256 key, uint256 value)
        // 应该返回4：:104 ？
        (uint256 key, uint256 atValue) = uint2uintMap.at(1);
        "at(1)".printUint256KeyValueLog(key, atValue);
        // function tryGet(UintToUintMap storage map, uint256 key) internal view returns (bool exists, uint256 value)
        // 这个方法如果没有key，不revert异常,返回0
        (bool exists, uint256 tryGetValue) = uint2uintMap.tryGet(2);
        "tryGet(2), exists:".printBoolLog(exists);
        "tryGet(2), tryGetValue:".printUint256Log(tryGetValue);
    }
    // function get(UintToUintMap storage map, uint256 key) internal view returns (uint256)
    function getEnumerableMapValue(uint256 key) external view returns (uint256) {
        return uint2uintMap.get(key);
    }
    // 6.BytesLib 字节数组（bytes）的拼接、切片、比较
    using BytesLib for *;
    function bytesLibTest() external {
        bytes memory myBytes = new bytes(33);
        myBytes[32] = 0x61;
        bytes memory anotherBytes = new bytes(1);
        anotherBytes[0] = 0x01;
        // (内存)拼接字节数组
        bytes memory concatBytes = myBytes.concat(anotherBytes);
        "concatBytes: ".printBytesLog(concatBytes);
        // 这里应该是34
        "concatBytes.length(): ".printUint256Log(concatBytes.length);
        // 截取字节数组
        bytes memory sliceBytes = concatBytes.slice(32, 1);
        // 这里是a(0x61)
        "sliceBytes: ".printBytesLog(sliceBytes);
        // 转换address
        address toAddress = concatBytes.toAddress(14);
        // 这里是0x000...6101
         "toAddress: ".printAddressLog(toAddress);
        // 转换uint256
        uint256 toUint256 = myBytes.toUint256(1);
        // 这里应该是97
        "toUint256: ".printUint256Log(toUint256);
        // 转换bytes32
        bytes32 toBytes32 = myBytes.toBytes32(1);
        // 0x00 0x00 0x00 .....0x61
        "toBytes32".printBytes32Log(toBytes32);
        // equal
        bytes memory compareBytes = new bytes(34);
        // 显式初始化
        for(uint i=0; i<34; i++) {
            compareBytes[i] = 0x00;
        }
        compareBytes[32] = 0x61;
        compareBytes[33] = 0x01;
        "compareBytes: ".printBytesLog(compareBytes);
        "concatBytes: ".printBytesLog(concatBytes);
        "concatBytes.equal(compareBytes): ".printBoolLog(concatBytes.equal(compareBytes));
        "concatBytes.equal_nonAligned(compareBytes): ".printBoolLog(concatBytes.equal_nonAligned(compareBytes));
        bytes memory fillBytes = new bytes(30);
        bytes memory concatFillBytes = concatBytes.concat(fillBytes);
        bytes memory compareFillBytes = concatBytes.concat(fillBytes);
        "concatFillBytes.equal(compareFillBytes): ".printBoolLog(concatFillBytes.equal(compareFillBytes));
    }


    // 7. 自定义链表库合约（库合约如果不能存储数，那么EnumerableSet和EnumerableMap如何实现？）
    // 定义结构体，外部合约引用库函数内结构体，进行数据存储（库函数传参使用）；
    // LinkedList
    using LinkedList for *;
    LinkedList.Bytes32List bytes32List;
    function linkedListTest() external {
        // adFirst
        bytes32List.addFirst(bytes32("1"));
        bytes32List.addFirst(bytes32("2"));
        bytes32List.addFirst(bytes32("3"));
        // size:3   ok
        "afterAddLast() bytes32List.size():".printUint256Log(bytes32List.size());
        // getFirst: 0x3300..   ok
        "bytes32List.getFirst():".printBytes32Log(bytes32List.getFirst());
        // getLast: 0x3100..
        "bytes32List.getLast():".printBytes32Log(bytes32List.getLast()); 
        // values: 0x3300..,0x3200..,0x3100..
        "afterAddLast() bytes32List.values():".printBytes32ArrayLog(bytes32List.values());
        // removeFirst: 0x3300..
        "bytes32List.removeFirst():".printBytes32Log(bytes32List.removeFirst());
        // （0x3200..,0x3100..）
        "afterAddLast() bytes32List.values():".printBytes32ArrayLog(bytes32List.values());
        // addLast: true （0x3200..,0x3100..,0x3400..）
        "addLast(bytes32(4)):".printBoolLog(bytes32List.addLast(bytes32("4")));
        // addLast: true （0x3200..,0x3100..,0x3400..,0x3500..）
        "addLast(bytes32(5)):".printBoolLog(bytes32List.addLast(bytes32("5")));
        // removeLast: four  （0x3200..,0x3100..,0x3400..）
        "bytes32List.removeLast():".printBytes32Log(bytes32List.removeLast());
        // contains: false
        "contains(bytes32(3)):".printBoolLog(bytes32List.contains(bytes32("3")));
        // （0x3200..,0x3100..,0x3400..）
        "bytes32List.values():".printBytes32ArrayLog(bytes32List.values());
        // isEmpty(): false
        "isEmpty():".printBoolLog(bytes32List.isEmpty());
        // 0x3100..
        "bytes32List.at(1):".printBytes32Log(bytes32List.at(1)._value);
        "bytes32List.add(1, 6):".printBoolLog(bytes32List.add(1, bytes32("6")));
        // （0x3200..,0x3600..,0x3100..,0x3400..）
        "bytes32List.values():".printBytes32ArrayLog(bytes32List.values());
        // 0x3100..
        "bytes32List.at(1):".printBytes32Log(bytes32List.remove(2));
        // （0x3200..,0x3600..,0x3400..）
        "bytes32List.set(0, 7):".printBoolLog(bytes32List.set(0, bytes32("7")));
        // （0x3700..,0x3600..,0x3400..）
        "bytes32List.values():".printBytes32ArrayLog(bytes32List.values());
        // 0x3600..
        "bytes32List.get(1):".printBytes32Log(bytes32List.get(1));
        // 遍历
        // LinkedList.Node storage node = bytes32List.at(0);
        // do {
        //     "bytes32List.node:".printBytes32Log(node._value);
        //     node = node.next(bytes32List);
        // }while (node.hasNext());
        // "bytes32List.node:".printBytes32Log(node._value);
        "beforeClear bytes32List.size():".printUint256Log(bytes32List.size());
        bytes32List.clear();
        // （0x3700..,0x3600..,0x3400..）
        "afterClear bytes32List.values():".printBytes32ArrayLog(bytes32List.values());
        // 测试极值
        bytes32List.addLast(bytes32("1"));
        bytes32List.addLast(bytes32("2"));
        bytes32List.addLast(bytes32("3"));
        bytes32List.addFirst(bytes32("4"));
        bytes32List.addFirst(bytes32("5"));
        bytes32List.addFirst(bytes32("6"));
        // （0x3600..,0x3500..,0x3400..,0x3100..,0x3200..,0x3300..）
        "bytes32List.values():".printBytes32ArrayLog(bytes32List.values());
        // 0x3600..
        "bytes32List.removeFirst():".printBytes32Log(bytes32List.removeFirst());
        // 0x3300..
        "bytes32List.removeLast():".printBytes32Log(bytes32List.removeLast());
        // 0x3100..
        "bytes32List.removeFirst():".printBytes32Log(bytes32List.remove(2));
        // （0x3500..,0x3400..,0x3200..）
        "bytes32List.values():".printBytes32ArrayLog(bytes32List.values());
        // 0x3200..
        "bytes32List.removeLast():".printBytes32Log(bytes32List.removeLast());
        // 0x3400..
        "bytes32List.removeLast():".printBytes32Log(bytes32List.removeLast());
        // 0x3500..
        "bytes32List.removeLast():".printBytes32Log(bytes32List.removeLast());
        "finally bytes32List.size():".printUint256Log(bytes32List.size());
        "bytes32List.removeLast():".printBytes32Log(bytes32List.removeLast());

    }
    LinkedList.UintList uintList;
    function uintListTest() external {
        uintList.addLast(1);
        uintList.addLast(2);
        uintList.addLast(1);
        uintList.addLast(3);
        "uintList.values()".printUint256ArrayLog(uintList.values());
        "uintList.size():".printUint256Log(uintList.size());
        "uintList.removeFirst():".printUint256Log(uintList.removeFirst());
        "uintList.removeLast():".printUint256Log(uintList.removeLast());
        "uintList.values()".printUint256ArrayLog(uintList.values());
        uintList.clear();
        "uintList.values()".printUint256ArrayLog(uintList.values());
    }
    LinkedList.AddressList addressList;
    function addressListTest() external returns (bool){
        addressList.addLast(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
        addressList.addLast(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2);
        addressList.addLast(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
        addressList.addLast(0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db);
        return addressList.contains(msg.sender);
    }
}
