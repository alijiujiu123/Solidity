# Solidity
## a generalized linked list structure
  ### Code Position
  #### contracts/structs/LinkedList.sol
  ### feature
  #### 1. supporting the storage of bytes32, uint256, and address types.
  #### 2. allows operations such as adding, removing, retrieving, and updating elements
  #### 3. implement efficient LIFO and FIFO queues.
  #### 4. Storage use is optimized, and all operations are O(1) constant time.This includes {clear} but excludes {values}.
## A self -implemented upgrade proxy contract(ERC1967)
  ### Code Position
  #### contracts/proxy/ERC1967/TransparentUpgradeableProxy.sol
  ### feature
  #### 1. Fallback forwards calls to the logic contract.
  #### 2. _fallback handles returned data using assembly.
  #### 3. The logic contract is upgradeable, with configurable admin management (adminAddress).
  #### 4. Ensures memory layout consistency (custom storage slot following ERC1967).
  #### 5. Calls initialization logic.
## Authorized contract with time limit
  ### Code Position
  #### contracts/utils/GrantPrivileges.sol
  ### feature
  #### 1. Access Control: Admin and Owner Permissions
  #### 2. Time-Based Authorization Management
  #### 3。 Admin Address Management (Upgradeable Admin Role)
