// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title BitMaps Library
 * @dev A library for managing bitmaps using a mapping-based storage structure.
 *      Each element in the bitmap is represented by a single bit with values {0,1}.
 */
library BitMaps {
    /**
     * @dev BitMap struct storing bit data using a mapping.
     *      Each `uint256` key (bucket) stores 256 bits, acting as a compressed storage format.
     */
    struct BitMap {
        mapping(uint256 => uint256) _data; // Mapping from bucket index to bit storage
    }

    /**
     * @dev Returns whether the bit at `data` index is set.
     */
    function _get(BitMap storage bitmap, uint256 data) private view returns (bool) {
        (uint256 bucket, uint256 mask) = _calcBucketAndMask(data);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `data` index to the specified boolean `value`.
     */
    function _setTo(BitMap storage bitmap, uint256 data, bool value) private {
        if (value) {
            _set(bitmap, data);
        } else {
            _unset(bitmap, data);
        }
    }

    /**
     * @dev Sets (enables) the bit at `data` index.
     */
    function _set(BitMap storage bitmap, uint256 data) private {
        (uint256 bucket, uint256 mask) = _calcBucketAndMask(data);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets (disables) the bit at `data` index.
     */
    function _unset(BitMap storage bitmap, uint256 data) private {
        (uint256 bucket, uint256 mask) = _calcBucketAndMask(data);
        bitmap._data[bucket] &= ~mask;
    }

    /**
     * @dev Computes the bucket index and bit mask for a given `data` index.
     *      - Each bucket (uint256) stores 256 bits.
     *      - Uses bitwise operations to efficiently determine storage location.
     */
    function _calcBucketAndMask(uint256 data) private pure returns (uint256 bucket, uint256 mask) {
        bucket = data >> 8; // Equivalent to data / 256
        mask = 1 << (data & 0xff); // Selects the bit within the bucket
    }

    /**
     * @dev Uint256-based BitMap wrapper for external usage.
     */
    struct Uint256BitMap {
        BitMap _inner;
    }

    function get(Uint256BitMap storage bitmap, uint256 data) internal view returns (bool) {
        return _get(bitmap._inner, data);
    }

    function setTo(Uint256BitMap storage bitmap, uint256 data, bool value) internal {
        _setTo(bitmap._inner, data, value);
    }

    function set(Uint256BitMap storage bitmap, uint256 data) internal {
        _set(bitmap._inner, data);
    }

    function unset(Uint256BitMap storage bitmap, uint256 data) internal {
        _unset(bitmap._inner, data);
    }

    /**
     * @dev Address-based BitMap wrapper, allowing `address` as the key.
     */
    struct AddressBitMap {
        BitMap _inner;
    }

    function get(AddressBitMap storage bitmap, address data) internal view returns (bool) {
        return _get(bitmap._inner, _addressToUint256(data));
    }

    function setTo(AddressBitMap storage bitmap, address data, bool value) internal {
        _setTo(bitmap._inner, _addressToUint256(data), value);
    }

    function set(AddressBitMap storage bitmap, address data) internal {
        _set(bitmap._inner, _addressToUint256(data));
    }

    function unset(AddressBitMap storage bitmap, address data) internal {
        _unset(bitmap._inner, _addressToUint256(data));
    }

    function _addressToUint256(address data) private pure returns (uint256) {
        return uint256(uint160(data));
    }

    /**
     * @dev Bytes32-based BitMap wrapper, allowing `bytes32` as the key.
     */
    struct Bytes32BitMap {
        BitMap _inner;
    }

    function get(Bytes32BitMap storage bitmap, bytes32 data) internal view returns (bool) {
        return _get(bitmap._inner, _bytes32ToUint256(data));
    }

    function setTo(Bytes32BitMap storage bitmap, bytes32 data, bool value) internal {
        _setTo(bitmap._inner, _bytes32ToUint256(data), value);
    }

    function set(Bytes32BitMap storage bitmap, bytes32 data) internal {
        _set(bitmap._inner, _bytes32ToUint256(data));
    }

    function unset(Bytes32BitMap storage bitmap, bytes32 data) internal {
        _unset(bitmap._inner, _bytes32ToUint256(data));
    }

    function _bytes32ToUint256(bytes32 data) private pure returns (uint256) {
        return uint256(data);
    }
}
