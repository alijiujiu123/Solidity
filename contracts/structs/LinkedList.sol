// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
// linked list implements：O(1)insert and delete; do not change the sequence of collect
/**
 * @dev The library provides a generalized linked list structure, 
 * supporting the storage of bytes32, uint256, and address types. 
 * It allows operations such as adding, removing, retrieving, and updating elements, 
 * while maintaining references to adjacent nodes for sequential navigation.

 * A sequence of items with the ability to efficiently push and pop items (i.e. insert and remove) on both ends of
 * the sequence (called front and back). Among other access patterns, it can be used to implement efficient LIFO and
 * FIFO queues. Storage use is optimized, and all operations are O(1) constant time. This includes {clear}, given that
 * the existing queue contents are left in storage.
 *
 * Lists have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). Guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using LinkedList for LinkedList.AddressList;
 *
 *     // Declare a set state variable
 *     LinkedList.AddressList private myList;
 * }
 * ```
 *
 * Type `bytes32` (`Bytes32List`), `uint256` (`UintList`)
 * and `address` (`AddressList`) are supported.
 *
 * [WARNING]
 * ====
 * Most operations, such as linking and unlinking, 
 * have constant or linear time complexity depending on the operation’s nature.
 *
 * Traversing the list to retrieve all values (_values) can be costly in terms of gas, 
 * so use it cautiously in gas-constrained contexts.
 * ====
 */
library LinkedList {
    // 
    enum LinkedType {LinkFirst, LinkLast, Link, Set}
    enum UnlinkedType {UnlinkFirst, UnlinkLast, Unlink, Set}
    // link事件
    event LinkedNode(uint256 indexed version, uint256 indexed nodeId, bytes32 indexed value, LinkedType linkedType);
    // unlink事件
    event UnlinkedNode(uint256 indexed version, uint256 indexed nodeId, bytes32 indexed value, UnlinkedType unlinkedType);
    // 异常
    // 元素不存在异常
    error LinkedListNonexistentElement();
    // 下标越界异常
    error IndexOutOfBounds();
    // 基础结构体，底层使用bytes32作为基础存储
    // bytes32基础上扩展Bytes32LinkedList, AddressLinkedList, UintLinkedList
    // ***********************************************************************************************
    // 0.基础结构
    struct Node {
        // 编号
        uint256 _id;
        // 前一个node编号
        uint256 _preId;
        // 后一个node编号
        uint256 _nextId;
        // 数据
        bytes32 _value;
    }
    struct List {
        // 当前版本号，用于清空链表
        uint256 _currentVersion;
        // 1.基础变量
        // 集合大小
        mapping(uint256 => uint256) _size;
        // 数据编号（计数器）
        mapping(uint256 => uint256) _counter;
        // id->Nodes
        mapping(uint256 => mapping(uint256 => Node)) _idNodes;
        // val -> nodeCount
        mapping(uint256 => mapping(bytes32 => uint256)) _valExists;
        mapping(uint256 => uint256) _firstId;
        mapping(uint256 => uint256) _lastId;
    }

    // 2.底层基础方法
    //private linkFirst()
    function _linkFirst(List storage list, bytes32 value) private returns (bool) {
        // 编号（这里需要跳过编号）
        uint256 counter = ++list._counter[list._currentVersion];
        Node storage newNode = list._idNodes[list._currentVersion][counter];
        newNode._id = counter;
        newNode._value = value;
        if (isUint256Zero(list._size[list._currentVersion])) {
            // 空list，firstId和lastId都为新节点
            list._firstId[list._currentVersion] = newNode._id;
            list._lastId[list._currentVersion] = newNode._id;
        }else {
            // 非空list
            uint256 firstId = list._firstId[list._currentVersion];
            Node storage oldHead = _node(list, firstId);
            newNode._nextId = oldHead._id;
            oldHead._preId = newNode._id;
            // firstId更新
            list._firstId[list._currentVersion] = newNode._id;
        }
        // list._idNodes[list._currentVersion][newNode._id] = newNode;
        list._valExists[list._currentVersion][value]++;
        // 集合大小
        list._size[list._currentVersion]++;
        emit LinkedNode(list._currentVersion, newNode._id, newNode._value, LinkedType.LinkFirst);
        return true;
    }
    // unlink first node
    function _unlinkFirst(List storage list) private returns (bytes32) {
        // 检查链表是否为空
        require(!_isEmpty(list), "LinkedList: List is empty");
        uint256 firstId = list._firstId[list._currentVersion];
        Node storage headNode = _node(list, firstId);
        uint256 cacheId = headNode._id;
        bytes32 cacheValue = headNode._value;
        if (list._size[list._currentVersion]==uint256(1)) {
            delete list._firstId[list._currentVersion];
            delete list._lastId[list._currentVersion];
        }else {
            // 有多个节点
            Node storage nextNode = _node(list, headNode._nextId);
            delete nextNode._preId;
            list._firstId[list._currentVersion] = nextNode._id;
        }
        delete list._idNodes[list._currentVersion][firstId];
        if (list._valExists[list._currentVersion][cacheValue] > 0) {
            list._valExists[list._currentVersion][cacheValue]--;
        }
        list._size[list._currentVersion]--;
        emit UnlinkedNode(list._currentVersion, cacheId, cacheValue, UnlinkedType.UnlinkFirst);
        return cacheValue;
    }
    //linkLast()
    function _linkLast(List storage list, bytes32 value) private returns (bool) {
        uint256 counter = ++list._counter[list._currentVersion];
        Node storage newNode = list._idNodes[list._currentVersion][counter];
        newNode._id = counter;
        newNode._value = value;
        // 接入链表
        if (isUint256Zero(list._size[list._currentVersion])) {
            list._firstId[list._currentVersion] = newNode._id;
            list._lastId[list._currentVersion] = newNode._id;
        }else {
            uint256 lastId = list._lastId[list._currentVersion];
            Node storage oldTail = _node(list, lastId);
            oldTail._nextId = newNode._id;
            newNode._preId = oldTail._id;
            list._lastId[list._currentVersion] = newNode._id;
        }
        list._idNodes[list._currentVersion][newNode._id] = newNode;
        list._valExists[list._currentVersion][value]++;
        list._size[list._currentVersion]++;
        emit LinkedNode(list._currentVersion, newNode._id, newNode._value, LinkedType.LinkLast);
        return true;
    }
    //unlinkLast
    function _unlinkLast(List storage list) private returns (bytes32) {
        // 检查链表是否为空
        require(!_isEmpty(list), "LinkedList: List is empty");
        uint256 lastId = list._lastId[list._currentVersion];
        Node storage tailNode = _node(list, lastId);
        uint256 cacheId = tailNode._id;
        bytes32 cacheValue = tailNode._value;
        if (list._size[list._currentVersion]==uint256(1)) {
            // 只有一个节点
            delete list._firstId[list._currentVersion];
            delete list._lastId[list._currentVersion];
        }else {
            // 有多个节点
            Node storage preNode = _node(list, tailNode._preId);
            delete preNode._nextId;
            list._lastId[list._currentVersion] = preNode._id;
        }
        delete list._idNodes[list._currentVersion][lastId];
        // list._valExists是否未正确赋值
        if (list._valExists[list._currentVersion][cacheValue] > 0) {
            list._valExists[list._currentVersion][cacheValue]--;
        }
        list._size[list._currentVersion]--;
        emit UnlinkedNode(list._currentVersion, cacheId, cacheValue, UnlinkedType.UnlinkLast);
        return cacheValue;
    }
    // first element
    function _getFirst(List storage list) private view returns (bytes32) {
        uint256 firstId = list._firstId[list._currentVersion];
        Node storage firstNode = _node(list, firstId);
        return firstNode._value;
    }
    // last element
    function _getLast(List storage list) private view returns (bytes32) {
        uint256 lastId = list._lastId[list._currentVersion];
        Node storage lastNode = _node(list, lastId);
        return lastNode._value;
    }
    // list中是否存在value
    function _contains(List storage list, bytes32 value) private view returns (bool) {
        return !isUint256Zero(list._valExists[list._currentVersion][value]);
    }
    // _isEmpty
    function _isEmpty(List storage list) private view returns (bool) {
        return isUint256Zero(list._size[list._currentVersion]);
    }
    function _size(List storage list) private view returns (uint256) {
        return list._size[list._currentVersion];
    }
    // _at:return node by index, O(n)
    function _at(List storage list, uint256 index) private view returns (Node storage) {
        Node storage node;
        if (index < (list._size[list._currentVersion] >> 1)) {
            // left part
            node = _node(list, list._firstId[list._currentVersion]);
            for (uint256 i=0; i<index; i++) {
                node = _node(list, node._nextId);
            }
        }else {
            // right part
            node = _node(list, list._lastId[list._currentVersion]);
            for(uint256 i=list._size[list._currentVersion]-1; i>index; i--) {
                node = _node(list, node._preId);
            }
        }
        return node;
    }
    // return element node by nodeId： O(1)
    function _node(List storage list, uint256 nodeId) private view returns (Node storage) {
        return list._idNodes[list._currentVersion][nodeId];
    }
    // 中间操作
    // insert(右移)
    function _link(List storage list, uint256 index, bytes32 value) private returns (bool) {
        checkPositionIndex(list, index);
        if (isUint256Zero(index)) {
            _linkFirst(list, value);
        }else if (index == list._size[list._currentVersion]) {
            _linkLast(list, value);
        }else {
            Node storage node = _at(list, index);
            // node 数据
            uint256 counter = ++list._counter[list._currentVersion];
            Node memory newNode = Node(counter, node._preId, node._id, value);
            // 前后节点数据修改
            Node storage preNode = _node(list, node._preId);
            node._preId = newNode._id;
            preNode._nextId = newNode._id;
            // 链表数据
            list._idNodes[list._currentVersion][newNode._id] = newNode;
            list._valExists[list._currentVersion][value]++;
            list._size[list._currentVersion]++;
        }
        return true;
    }
    // unlink(index)
    function _unlink(List storage list, uint256 index) private returns (bytes32) {
        checkElementIndex(list, index);
        bytes32 result;
        if (isUint256Zero(index)) {
            result = _unlinkFirst(list);
        }else if (index == list._size[list._currentVersion]-1) {
            result = _unlinkLast(list);
        }else {
            Node storage node = _at(list, index);
            uint256 cacheId = node._id;
            bytes32 cacheValue = node._value;
            // 前后节点数据修改
            Node storage preNode = _node(list, node._preId);
            Node storage nextNode = _node(list, node._nextId);
            preNode._nextId = nextNode._id;
            nextNode._preId = preNode._id;
            // 链表数据
            delete list._idNodes[list._currentVersion][cacheId];
            if (list._valExists[list._currentVersion][cacheValue] > 0) {
                list._valExists[list._currentVersion][cacheValue]--;
            }
            list._size[list._currentVersion]--;
            result = cacheValue;
        }
        return result;
    }
    // update
    function _set(List storage list, uint256 index, bytes32 value) private returns (bool) {
        checkElementIndex(list, index);
        Node storage node = _at(list, index);
        bytes32 oldVal = node._value;
        list._valExists[list._currentVersion][oldVal]--;
        node._value = value;
        list._valExists[list._currentVersion][value]++;
        return true;
    }
    // get element value by index
    function _get(List storage list, uint256 index) private view returns (bytes32) {
        checkElementIndex(list, index);
        Node storage node = _at(list, index);
        return node._value;
    }
    // _hasNext
    function _hasNext(Node storage node) private view returns (bool) {
        if (isUint256Zero(node._id)) {
            revert LinkedListNonexistentElement();
        }
        return !isUint256Zero(node._nextId);
    }
    // _next
    function _next(Node storage node, List storage list) private view returns (Node storage) {
        if (!_hasNext(node)) {
            revert LinkedListNonexistentElement();
        }
        return _node(list, node._nextId);
    }
    // _hasPrevious
    function _hasPrevious(Node storage node) private view returns (bool) {
        if (isUint256Zero(node._id)) {
            revert LinkedListNonexistentElement();
        }
        return !isUint256Zero(node._preId);
    }
    // _previous
    function _previous(Node storage node, List storage list) private view returns (Node storage) {
        if (!_hasPrevious(node)) {
            revert LinkedListNonexistentElement();
        }
        return _node(list, node._preId);
    }
    // _values：O(n),遍历，消耗大量gas，慎用
    function _values(List storage list) private view returns (bytes32[] memory) {
        // memory类型必须初始化时确定大小，否则无法分配内存空间
        bytes32[] memory dataVals = new bytes32[](_size(list));
        if (_isEmpty(list)) {
            return dataVals;
        }
        uint256 cursor = uint256(0);
        uint256 firstNodeId = list._firstId[list._currentVersion];
        Node storage node = _node(list, firstNodeId);
        dataVals[cursor++] = node._value;
        while(_hasNext(node)) {
            node = _next(node, list);
            dataVals[cursor++] = node._value;
        }
        return dataVals;
    }
    // clear
    function _clear(List storage list) private {
        list._currentVersion++;
    }

    // Bytes32List
    struct Bytes32List {
        List _inner;
    }
    // 1.队列操作
    // addFirst(data)
    function addFirst(Bytes32List storage list, bytes32 value) internal returns (bool) {
        return _linkFirst(list._inner, value);
    }
    // removeFirst()
    function removeFirst(Bytes32List storage list) internal returns (bytes32) {
        return _unlinkFirst(list._inner);
    }
    // addLast(data)
    function addLast(Bytes32List storage list, bytes32 value) internal returns (bool) {
        return _linkLast(list._inner, value);
    }
    // removeLast()
    function removeLast(Bytes32List storage list) internal returns (bytes32) {
        return _unlinkLast(list._inner);
    }
    // getFirst()
    function getFirst(Bytes32List storage list) internal view returns (bytes32) {
        return _getFirst(list._inner);
    }
    // getLast()
    function getLast(Bytes32List storage list) internal view returns (bytes32) {
        return _getLast(list._inner);
    }
    // list中是否存在value
    function contains(Bytes32List storage list, bytes32 value) internal view returns (bool) {
        return _contains(list._inner, value);
    }
    // isEmpty
    function isEmpty(Bytes32List storage list) internal view returns (bool) {
        return _isEmpty(list._inner);
    }
    function size(Bytes32List storage list) internal view returns (uint256) {
        return _size(list._inner);
    }
    // at: O(n)
    function at(Bytes32List storage list, uint256 index) internal view returns (Node storage) {
        return _at(list._inner, index);
    }

    function add(Bytes32List storage list, uint256 index, bytes32 value) internal returns (bool) {
        return _link(list._inner, index, value);
    }

    function remove(Bytes32List storage list, uint256 index) internal returns (bytes32) {
        return _unlink(list._inner, index);
    }

    function set(Bytes32List storage list, uint256 index, bytes32 value) internal returns (bool) {
        return _set(list._inner, index, value);
    }

    function get(Bytes32List storage list, uint256 index) internal view returns (bytes32) {
        return _get(list._inner, index);
    }

    // // hasNext
    // function hasNext(Node storage node) internal view returns (bool) {
    //     return _hasNext(node);
    // }
    // // next
    // function next(Node storage node, Bytes32List storage list) internal view returns (Node storage) {
    //     return _next(node, list._inner);
    // }
    // // hasPrevious
    // function hasPrevious(Node storage node) internal view returns (bool) {
    //     return _hasPrevious(node);
    // }
    // // previous
    // function previous(Node storage node, Bytes32List storage list) internal view returns (Node storage) {
    //     return _previous(node, list._inner);
    // }
    // values：O(n),遍历，消耗大量gas，慎用
    function values(Bytes32List storage list) internal view returns (bytes32[] memory) {
        return _values(list._inner);
    }
    // clear
    function clear(Bytes32List storage list) internal {
        _clear(list._inner);
    }

    // Bytes32List
    struct UintList {
        List _inner;
    }
    // 1.队列操作
    // addFirst(data)
    function addFirst(UintList storage list, uint256 value) internal returns (bool) {
        return _linkFirst(list._inner, bytes32(value));
    }
    // removeFirst()
    function removeFirst(UintList storage list) internal returns (uint256) {
        return uint256(_unlinkFirst(list._inner));
    }
    // addLast(data)
    function addLast(UintList storage list, uint256 value) internal returns (bool) {
        return _linkLast(list._inner, bytes32(value));
    }
    // removeLast()
    function removeLast(UintList storage list) internal returns (uint256) {
        return uint256(_unlinkLast(list._inner));
    }
    // getFirst()
    function getFirst(UintList storage list) internal view returns (uint256) {
        return uint256(_getFirst(list._inner));
    }
    // getLast()
    function getLast(UintList storage list) internal view returns (uint256) {
        return uint256(_getLast(list._inner));
    }
    // list中是否存在value
    function contains(UintList storage list, uint256 value) internal view returns (bool) {
        return _contains(list._inner, bytes32(value));
    }
    // isEmpty
    function isEmpty(UintList storage list) internal view returns (bool) {
        return _isEmpty(list._inner);
    }
    function size(UintList storage list) internal view returns (uint256) {
        return _size(list._inner);
    }
    // at: O(n)
    // function at(UintList storage list, uint256 index) internal view returns (Node storage) {
    //     return _at(list._inner, index);
    // }

    function add(UintList storage list, uint256 index, uint256 value) internal returns (bool) {
        return _link(list._inner, index, bytes32(value));
    }

    function remove(UintList storage list, uint256 index) internal returns (uint256) {
        return uint256(_unlink(list._inner, index));
    }

    function set(UintList storage list, uint256 index, uint256 value) internal returns (bool) {
        return _set(list._inner, index, bytes32(value));
    }

    function get(UintList storage list, uint256 index) internal view returns (uint256) {
        return uint256(_get(list._inner, index));
    }
    // values：O(n),遍历，消耗大量gas，慎用
    function values(UintList storage list) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(list._inner);
        uint256[] memory result;

        assembly ("memory-safe") {
            result := store
        }

        return result;
    }
    // clear
    function clear(UintList storage list) internal {
        _clear(list._inner);
    }

    // AddressList
    struct AddressList {
        List _inner;
    }
    // 1.队列操作
    // addFirst(data)
    function addFirst(AddressList storage list, address value) internal returns (bool) {
        return _linkFirst(list._inner, addressToBytes32(value));
    }
    // removeFirst()
    function removeFirst(AddressList storage list) internal returns (address) {
        return bytes32ToAddress(_unlinkFirst(list._inner));
    }
    // addLast(data)
    function addLast(AddressList storage list, address value) internal returns (bool) {
        return _linkLast(list._inner, addressToBytes32(value));
    }
    // removeLast()
    function removeLast(AddressList storage list) internal returns (address) {
        return bytes32ToAddress(_unlinkLast(list._inner));
    }
    // getFirst()
    function getFirst(AddressList storage list) internal view returns (address) {
        return bytes32ToAddress(_getFirst(list._inner));
    }
    // getLast()
    function getLast(AddressList storage list) internal view returns (address) {
        return bytes32ToAddress(_getLast(list._inner));
    }
    // list中是否存在value
    function contains(AddressList storage list, address value) internal view returns (bool) {
        return _contains(list._inner, addressToBytes32(value));
    }
    // isEmpty
    function isEmpty(AddressList storage list) internal view returns (bool) {
        return _isEmpty(list._inner);
    }
    function size(AddressList storage list) internal view returns (uint256) {
        return _size(list._inner);
    }
    // at: O(n)
    // function at(UintList storage list, uint256 index) internal view returns (Node storage) {
    //     return _at(list._inner, index);
    // }

    function add(AddressList storage list, uint256 index, address value) internal returns (bool) {
        return _link(list._inner, index, addressToBytes32(value));
    }

    function remove(AddressList storage list, uint256 index) internal returns (address) {
        return bytes32ToAddress(_unlink(list._inner, index));
    }

    function set(AddressList storage list, uint256 index, address value) internal returns (bool) {
        return _set(list._inner, index, addressToBytes32(value));
    }

    function get(AddressList storage list, uint256 index) internal view returns (address) {
        return bytes32ToAddress(_get(list._inner, index));
    }
    // values：O(n),遍历，消耗大量gas，慎用
    function values(AddressList storage list) internal view returns (address[] memory) {
        bytes32[] memory store = _values(list._inner);
        address[] memory result;

        assembly ("memory-safe") {
            result := store
        }

        return result;
    }
    // clear
    function clear(AddressList storage list) internal {
        _clear(list._inner);
    }



    // utils
    // add position index check
    function checkPositionIndex(List storage list, uint256 index) private view {
        if (index < 0 || index > list._size[list._currentVersion]) {
            revert IndexOutOfBounds();
        }
    }
    // element index check
    function checkElementIndex(List storage list, uint256 index) private view {
        if (index < 0 || index >= list._size[list._currentVersion]) {
            revert IndexOutOfBounds();
        }
    }
    // 是否为bytes32(0)
    function isBytes32Zero(bytes32 data) internal pure returns (bool) {
        return data==bytes32(0);
    }
    // 是否为uint256(0)
    function isUint256Zero(uint256 num) internal pure returns (bool) {
        return num==uint256(0);
    }
    function addressToBytes32(address value) internal pure returns (bytes32) {
        return  bytes32(uint256(uint160(value)));
    }
    function bytes32ToAddress(bytes32 value) internal pure returns (address) {
        return address(uint160(uint256(value)));
    }
}
