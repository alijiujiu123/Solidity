// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

library ArrayUtils {
    /**
     * @dev Checks if an array contains a specific element.
     * @param array The array to search.
     * @param element The element to find in the array.
     * @return bool Returns true if the element exists in the array, false otherwise.
     */
    function contains(bytes4[] memory array, bytes4 element) internal pure returns (bool) {
        uint len = array.length;
        if (len == 0) {
            return false;
        }
        for (uint i = 0; i < len; i++) {
            if (array[i] == element) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Removes specific elements from the main array.
     * @param mainArray The original array from which elements will be removed.
     * @param removeArray The array containing elements to be removed from the main array.
     * @return bytes4[] A new array with the specified elements removed.
     */
    function removeElements(bytes4[] memory mainArray, bytes4[] memory removeArray) internal pure returns (bytes4[] memory) {
        uint mainLen = mainArray.length;
        uint removeLen = removeArray.length;

        if (mainLen == 0 || removeLen == 0) {
            return mainArray; // Return original array if either is empty
        }

        uint counter = 0;
        // Store indices of elements to be retained
        uint[] memory retentionIndices = new uint[](mainLen);

        for (uint i = 0; i < mainLen; i++) {
            if (!contains(removeArray, mainArray[i])) {
                // If the element is not in removeArray, retain it
                retentionIndices[counter++] = i;
            }
        }

        // Create a new array for the result with the retained elements
        bytes4[] memory result = new bytes4[](counter);
        for (uint i = 0; i < counter; i++) {
            result[i] = mainArray[retentionIndices[i]];
        }

        return result;
    }
}
