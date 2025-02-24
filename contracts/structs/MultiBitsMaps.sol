// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title MultiBitsMaps Library
 * @dev A Solidity library for efficiently managing bitmaps with different bit-width elements (2-bit, 4-bit, and 8-bit).
 *      This library provides storage-efficient mappings where each element takes a specific number of bits.
 */
library MultiBitsMaps {
    // Error when the provided value exceeds the range {0,1,2,3}
    error OutOfTwoBitValueRange(uint8 value);
    // Error when the provided value exceeds the range {0,1,2,...,15}
    error OutOfFourBitValueRange(uint8 value);
    // Error when the provided value exceeds the range {0,1,2,...,255}
    error OutOfByteValueRange(uint8 value);

    /**
     * @dev A storage-efficient bitmap where each element occupies 2 bits (values range: {0,1,2,3}).
     */
    struct TwoBitsMap {
        mapping(uint256 => uint256) _data; // Internal mapping to store packed data.
    }

    /**
     * @dev Retrieves the 2-bit value stored at the given index.
     * @param bitmap The TwoBitsMap storage reference.
     * @param data The index of the element.
     * @return The 2-bit value at the specified index.
     */
    function _get(TwoBitsMap storage bitmap, uint256 data) private view returns (uint8) {
        (uint256 bucket, uint256 mask, uint8 bitOffset) = _calcTwoBitBucketAndMask(data);
        return uint8((bitmap._data[bucket] & mask) >> bitOffset);
    }

    /**
     * @dev Sets the 2-bit value at the specified index.
     * @param bitmap The TwoBitsMap storage reference.
     * @param data The index of the element.
     * @param value The value to set (must be within range {0,1,2,3}).
     */
    function _set(TwoBitsMap storage bitmap, uint256 data, uint8 value) private {
        if (value > 0x03) {
            revert OutOfTwoBitValueRange(value);
        }
        (uint256 bucket, uint256 mask, uint8 bitOffset) = _calcTwoBitBucketAndMask(data);
        // Clear the previous value and set the new one
        bitmap._data[bucket] = (bitmap._data[bucket] & ~mask) | (uint256(value) << bitOffset);
    }

    /**
     * @dev Computes the bucket index, mask, and bit offset for a given 2-bit element.
     * @param data The index of the element.
     * @return bucket The storage slot in the mapping.
     * @return mask The bitmask used to isolate the value.
     * @return bitOffset The bit shift required to access the value.
     */
    function _calcTwoBitBucketAndMask(uint256 data)
        private
        pure
        returns (uint256 bucket, uint256 mask, uint8 bitOffset)
    {
        bucket = data >> 7; // Each 256-bit slot can store 128 values (2 bits each)
        bitOffset = uint8(2 * (data & 0x7f)); // Extracts the last 7 bits for the position within the bucket
        mask = 0x03 << bitOffset; // Mask to isolate the 2-bit value
    }

    /**
     * @dev A wrapper structure for a TwoBitsMap indexed by uint256.
     */
    struct Uint256TwoBitsMap {
        TwoBitsMap _inner;
    }

    /**
     * @dev Retrieves the value at the given uint256 index.
     */
    function get(Uint256TwoBitsMap storage bitmap, uint256 data) internal view returns (uint8) {
        return _get(bitmap._inner, data);
    }

    /**
     * @dev Sets the value at the given uint256 index.
     */
    function set(Uint256TwoBitsMap storage bitmap, uint256 data, uint8 value) internal {
        _set(bitmap._inner, data, value);
    }

    /**
     * @dev A wrapper structure for a TwoBitsMap indexed by address.
     */
    struct AddressTwoBitsMap {
        TwoBitsMap _inner;
    }

    /**
     * @dev Retrieves the value at the given address index.
     */
    function get(AddressTwoBitsMap storage bitmap, address data) internal view returns (uint8) {
        return _get(bitmap._inner, _addressToUint256(data));
    }

    /**
     * @dev Sets the value at the given address index.
     */
    function set(AddressTwoBitsMap storage bitmap, address data, uint8 value) internal {
        _set(bitmap._inner, _addressToUint256(data), value);
    }

    /**
     * @dev Converts an address to uint256 for storage mapping.
     */
    function _addressToUint256(address data) private pure returns (uint256) {
        return uint256(uint160(data));
    }

    /**
     * @dev A wrapper structure for a TwoBitsMap indexed by bytes32.
     */
    struct Bytes32TwoBitsMap {
        TwoBitsMap _inner;
    }

    /**
     * @dev Retrieves the value at the given bytes32 index.
     */
    function get(Bytes32TwoBitsMap storage bitmap, bytes32 data) internal view returns (uint8) {
        return _get(bitmap._inner, _bytes32ToUint256(data));
    }

    /**
     * @dev Sets the value at the given bytes32 index.
     */
    function set(Bytes32TwoBitsMap storage bitmap, bytes32 data, uint8 value) internal {
        _set(bitmap._inner, _bytes32ToUint256(data), value);
    }

    /**
     * @dev Converts bytes32 to uint256 for storage mapping.
     */
    function _bytes32ToUint256(bytes32 data) private pure returns (uint256) {
        return uint256(data);
    }

        /**
     * @dev A storage-efficient bitmap where each element occupies 4 bits (values range: {0,1,...,15}).
     */
    struct FourBitsMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Retrieves the 4-bit value stored at the given index.
     */
    function _get(FourBitsMap storage bitmap, uint256 data) private view returns (uint8) {
        (uint256 bucket, uint256 mask, uint8 bitOffset) = _calcFourBitBucketAndMask(data);
        return uint8((bitmap._data[bucket] & mask) >> bitOffset);
    }

    /**
     * @dev Sets the 4-bit value at the specified index.
     */
    function _set(FourBitsMap storage bitmap, uint256 data, uint8 value) private {
        if (value > 0x0F) {
            revert OutOfFourBitValueRange(value);
        }
        (uint256 bucket, uint256 mask, uint8 bitOffset) = _calcFourBitBucketAndMask(data);
        bitmap._data[bucket] = (bitmap._data[bucket] & ~mask) | (uint256(value) << bitOffset);
    }

    /**
     * @dev Computes storage bucket, mask, and bit offset for a 4-bit element.
     */
    function _calcFourBitBucketAndMask(uint256 data)
        private
        pure
        returns (uint256 bucket, uint256 mask, uint8 bitOffset)
    {
        bucket = data >> 6; // 64 values per 256-bit slot
        bitOffset = uint8(4 * (data & 0x3F));
        mask = 0x0F << bitOffset;
    }

    struct Uint256FourBitsMap {
        FourBitsMap _inner;
    }

    function get(Uint256FourBitsMap storage bitmap, uint256 data) internal view returns (uint8) {
        return _get(bitmap._inner, data);
    }

    function set(Uint256FourBitsMap storage bitmap, uint256 data, uint8 value) internal {
        _set(bitmap._inner, data, value);
    }

    struct AddressFourBitsMap {
        FourBitsMap _inner;
    }

    function get(AddressFourBitsMap storage bitmap, address data) internal view returns (uint8) {
        return _get(bitmap._inner, _addressToUint256(data));
    }

    function set(AddressFourBitsMap storage bitmap, address data, uint8 value) internal {
        _set(bitmap._inner, _addressToUint256(data), value);
    }

    struct Bytes32FourBitsMap {
        FourBitsMap _inner;
    }

    function get(Bytes32FourBitsMap storage bitmap, bytes32 data) internal view returns (uint8) {
        return _get(bitmap._inner, _bytes32ToUint256(data));
    }

    function set(Bytes32FourBitsMap storage bitmap, bytes32 data, uint8 value) internal {
        _set(bitmap._inner, _bytes32ToUint256(data), value);
    }

    /**
     * @dev A storage-efficient bitmap where each element occupies 8 bits (values range: {0,1,...,255}).
     */
    struct ByteMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Retrieves the 8-bit value stored at the given index.
     */
    function _get(ByteMap storage bitmap, uint256 data) private view returns (uint8) {
        (uint256 bucket, uint256 mask, uint8 bitOffset) = _calcByteBucketAndMask(data);
        return uint8((bitmap._data[bucket] & mask) >> bitOffset);
    }

    /**
     * @dev Sets the 8-bit value at the specified index.
     */
    function _set(ByteMap storage bitmap, uint256 data, uint8 value) private {
        if (value > 0xFF) {
            revert OutOfByteValueRange(value);
        }
        (uint256 bucket, uint256 mask, uint8 bitOffset) = _calcByteBucketAndMask(data);
        bitmap._data[bucket] = (bitmap._data[bucket] & ~mask) | (uint256(value) << bitOffset);
    }

    /**
     * @dev Computes storage bucket, mask, and bit offset for an 8-bit element.
     */
    function _calcByteBucketAndMask(uint256 data)
        private
        pure
        returns (uint256 bucket, uint256 mask, uint8 bitOffset)
    {
        bucket = data >> 5; // 32 values per 256-bit slot
        bitOffset = uint8(8 * (data & 0x1F));
        mask = 0xFF << bitOffset;
    }

    struct Uint256ByteMap {
        ByteMap _inner;
    }

    function get(Uint256ByteMap storage bitmap, uint256 data) internal view returns (uint8) {
        return _get(bitmap._inner, data);
    }

    function set(Uint256ByteMap storage bitmap, uint256 data, uint8 value) internal {
        _set(bitmap._inner, data, value);
    }

    struct AddressByteMap {
        ByteMap _inner;
    }

    function get(AddressByteMap storage bitmap, address data) internal view returns (uint8) {
        return _get(bitmap._inner, _addressToUint256(data));
    }

    function set(AddressByteMap storage bitmap, address data, uint8 value) internal {
        _set(bitmap._inner, _addressToUint256(data), value);
    }

    struct Bytes32ByteMap {
        ByteMap _inner;
    }

    function get(Bytes32ByteMap storage bitmap, bytes32 data) internal view returns (uint8) {
        return _get(bitmap._inner, _bytes32ToUint256(data));
    }

    function set(Bytes32ByteMap storage bitmap, bytes32 data, uint8 value) internal {
        _set(bitmap._inner, _bytes32ToUint256(data), value);
    }
}
