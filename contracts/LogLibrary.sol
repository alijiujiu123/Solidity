// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
library LogLibrary {
    // 定义日志打印事件
    event PrintUint256ArrayLog(string desc, uint256[] data);
    event PrintBoolLog(string desc, bool data);
    event PrintUint256Log(string desc, uint256 data);
    event PrintUint256KeyValueLog(string desc, uint256 key, uint256 value);
    event PrintStringLog(string desc, string value);
    event PrintAddressLog(string desc, address value);
    event PrintBytes32Log(string desc, bytes32 data);
    event PrintBytes32ArrayLog(string desc, bytes32[] data);
    // 输出uint256[]日志
    function printUint256ArrayLog(string memory desc, uint256[] memory data) internal {
        emit PrintUint256ArrayLog(desc, data);
    }
    // 输出bool日志
    function printBoolLog(string memory desc, bool data) internal {
        emit PrintBoolLog(desc, data);
    }
    // 输出uint256日志
    function printUint256Log(string memory desc, uint256 data) internal {
        emit PrintUint256Log(desc, data);
    }
    // 输出uint256KeyValue日志
    function printUint256KeyValueLog(string memory desc, uint256 key, uint256 value) internal {
        emit PrintUint256KeyValueLog(desc, key, value);
    }
    // 输出bytes日志
    function printBytesLog(string memory desc, bytes memory bytesLog) internal {
        emit PrintStringLog(desc, string(bytesLog));
    }
    // 输出string日志
    function printStringLog(string memory desc, string memory log) internal {
        emit PrintStringLog(desc, log);
    }
    // 输出address日志
    function printAddressLog(string memory desc, address data) internal {
        emit PrintAddressLog(desc, data);
    }
    function printBytes32Log(string memory desc, bytes32 data) internal {
        emit PrintBytes32Log(desc, data);
    }
    function printBytes32ArrayLog(string memory desc, bytes32[] memory data) internal {
        emit PrintBytes32ArrayLog(desc, data);
    }
}
