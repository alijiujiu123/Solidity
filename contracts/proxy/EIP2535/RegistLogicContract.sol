// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "contracts/proxy/EIP2535/IDiamondCut.sol";
import "contracts/proxy/EIP2535/LogicOneFacet.sol";
import "contracts/proxy/EIP2535/LogicTwoFacet.sol";
import "contracts/proxy/EIP2535/LogicOneV2Facet.sol";
import "contracts/proxy/EIP2535/LogicTwoV2Facet.sol";
import "contracts/proxy/EIP2535/LogicTwoV3Facet.sol";

contract RegistLogicContract {
    event InitCalldataExecute(address indexed diamondCutAddress, IDiamondCut.FacetCut[] _diamondCut, bool ok, bytes resultData);
    function registLogicOneContract(address _diamondProxyAddress, address _facetAddress) external {
        // 准备 FacetCut 结构数据
        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = LogicOneFacet.getMyCounter.selector;
        selectors[1] = LogicOneFacet.setMyCounter.selector;
        selectors[2] = LogicOneFacet.increMyCounter.selector;
        
        IDiamondCut.FacetCut[] memory _diamondCut = new IDiamondCut.FacetCut[](1);
        _diamondCut[0] = IDiamond.FacetCut({
            facetAddress: _facetAddress,
            action: IDiamond.FacetCutAction.Add,  // 0 = Add
            functionSelectors: selectors
        });
        _registFacet(_diamondProxyAddress, _diamondCut, address(0), bytes(""));
    }

    function registLogicOneAddSelector(address _diamondProxyAddress, address _facetAddress) external {
        // 准备 FacetCut 结构数据
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = LogicOneFacet.decreMyCounter.selector;
        
        IDiamondCut.FacetCut[] memory _diamondCut = new IDiamondCut.FacetCut[](1);
        _diamondCut[0] = IDiamond.FacetCut({
            facetAddress: _facetAddress,
            action: IDiamond.FacetCutAction.Add,  // 0 = Add
            functionSelectors: selectors
        });
        _registFacet(_diamondProxyAddress, _diamondCut, address(0), bytes(""));
    }

    function registLogicOneRemoveSelector(address _diamondProxyAddress, address _facetAddress) external {
        // 准备 FacetCut 结构数据
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = LogicOneFacet.decreMyCounter.selector;
        
        IDiamondCut.FacetCut[] memory _diamondCut = new IDiamondCut.FacetCut[](1);
        _diamondCut[0] = IDiamond.FacetCut({
            facetAddress: _facetAddress,
            action: IDiamond.FacetCutAction.Remove,  // 0 = Add
            functionSelectors: selectors
        });
        _registFacet(_diamondProxyAddress, _diamondCut, address(0), bytes(""));
    }

    function registLogicTwoContract(address _diamondProxyAddress, address _facetAddress) external {
        // 准备 FacetCut 结构数据
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = LogicTwoFacet.getMyContent.selector;
        selectors[1] = LogicTwoFacet.setMyCounter.selector;
        
        IDiamondCut.FacetCut[] memory _diamondCut = new IDiamondCut.FacetCut[](1);
        _diamondCut[0] = IDiamond.FacetCut({
            facetAddress: _facetAddress,
            action: IDiamond.FacetCutAction.Add,  // 0 = Add
            functionSelectors: selectors
        });
        _registFacet(_diamondProxyAddress, _diamondCut, address(0), bytes(""));
    }

    function registLogicTwoRemoveAllSelector(address _diamondProxyAddress, address _facetAddress) external {
        // 准备 FacetCut 结构数据
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = LogicTwoFacet.getMyContent.selector;
        selectors[1] = LogicTwoFacet.setMyCounter.selector;
        
        IDiamondCut.FacetCut[] memory _diamondCut = new IDiamondCut.FacetCut[](1);
        _diamondCut[0] = IDiamond.FacetCut({
            facetAddress: _facetAddress,
            action: IDiamond.FacetCutAction.Remove,
            functionSelectors: selectors
        });
        _registFacet(_diamondProxyAddress, _diamondCut, address(0), bytes(""));
    }

    // LogicOneV2 selector changes: 1. add: increByMyCounter     decreByMyCounter;  2. replace:  decreMyCounter
    function registLogicOneV2Change(address _diamondProxyAddress, address _facetAddress) external {
        // 准备 FacetCut 结构数据
        IDiamondCut.FacetCut[] memory _diamondCut = new IDiamondCut.FacetCut[](2);
        // 1. add: increByMyCounter     decreByMyCounter
        bytes4[] memory addSelectors = new bytes4[](2);
        addSelectors[0] = LogicOneV2Facet.increByMyCounter.selector;
        addSelectors[1] = LogicOneV2Facet.decreByMyCounter.selector;
        
        _diamondCut[0] = IDiamond.FacetCut({
            facetAddress: _facetAddress,
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: addSelectors
        });
        // 2. replace:  decreMyCounter
        bytes4[] memory replaceSelectors = new bytes4[](1);
        replaceSelectors[0] = LogicOneV2Facet.decreMyCounter.selector;
        
        _diamondCut[1] = IDiamond.FacetCut({
            facetAddress: _facetAddress,
            action: IDiamond.FacetCutAction.Replace,
            functionSelectors: replaceSelectors
        });
        _registFacet(_diamondProxyAddress, _diamondCut, address(0), bytes(""));
    }

    function registLogicOneV2Replace(address _diamondProxyAddress, address _facetAddress) external {
        // 准备 FacetCut 结构数据
        IDiamondCut.FacetCut[] memory _diamondCut = new IDiamondCut.FacetCut[](1);
        // 1. replace:  decreMyCounter
        bytes4[] memory replaceSelectors = new bytes4[](1);
        replaceSelectors[0] = LogicOneV2Facet.decreMyCounter.selector;
        
        _diamondCut[0] = IDiamond.FacetCut({
            facetAddress: _facetAddress,
            action: IDiamond.FacetCutAction.Replace,
            functionSelectors: replaceSelectors
        });
        _registFacet(_diamondProxyAddress, _diamondCut, address(0), bytes(""));
    }

    // LogicTwoV2 selector changes
    function registLogicTwoV2Change(address _diamondProxyAddress, address _facetAddress) external {
        // 准备 FacetCut 结构数据
        IDiamondCut.FacetCut[] memory _diamondCut = new IDiamondCut.FacetCut[](1);
        // 1. add: increByMyCounter     decreByMyCounter
        bytes4[] memory addSelectors = new bytes4[](2);
        addSelectors[0] = LogicTwoV2Facet.beforeMyCounter.selector;
        addSelectors[1] = LogicTwoV2Facet.afterMyCounter.selector;
        
        _diamondCut[0] = IDiamond.FacetCut({
            facetAddress: _facetAddress,
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: addSelectors
        });
        _registFacet(_diamondProxyAddress, _diamondCut, address(0), bytes(""));
    }

    function registLogicTwoV3Change(address _diamondProxyAddress, address _facetAddress) external {
        // 准备 FacetCut 结构数据
        IDiamondCut.FacetCut[] memory _diamondCut = new IDiamondCut.FacetCut[](1);
        // 1. add: increByMyCounter     decreByMyCounter
        bytes4[] memory addSelectors = new bytes4[](1);
        addSelectors[0] = LogicTwoV3Facet.getSlot.selector;
        
        _diamondCut[0] = IDiamond.FacetCut({
            facetAddress: _facetAddress,
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: addSelectors
        });
        // 初始化调用LogicTwoV3Facet.init()
        _registFacet(_diamondProxyAddress, _diamondCut, _facetAddress, abi.encodeWithSelector(LogicTwoV3Facet.init.selector));
    }

    function registLogicTwoV3Remove(address _diamondProxyAddress, address _facetAddress) external {
        // 准备 FacetCut 结构数据
        IDiamondCut.FacetCut[] memory _diamondCut = new IDiamondCut.FacetCut[](1);
        // 1. add: increByMyCounter     decreByMyCounter
        bytes4[] memory addSelectors = new bytes4[](1);
        addSelectors[0] = LogicTwoV3Facet.getSlot.selector;
        
        _diamondCut[0] = IDiamond.FacetCut({
            facetAddress: _facetAddress,
            action: IDiamond.FacetCutAction.Remove,
            functionSelectors: addSelectors
        });
        // 初始化调用LogicTwoV3Facet.init()
        _registFacet(_diamondProxyAddress, _diamondCut, address(0), bytes(""));
    }

    function _registFacet(address _diamondProxyAddress, IDiamondCut.FacetCut[] memory _diamondCut, address _init, bytes memory _calldata) private {
        // ABI 编码参数
        // bytes memory encodedData = abi.encodeWithSelector(
        //     IDiamondCut.diamondCut.selector,  // 获取 diamondCut 的 function selector
        //     _diamondCut,
        //     _init,
        //     _calldata  // 初始化时调用的 calldata，可以为空
        // );
        // (bool ok, bytes memory resultDta) = _diamondProxyAddress.call(encodedData);
        IDiamondCut(_diamondProxyAddress).diamondCut(_diamondCut, _init, _calldata);
        // emit InitCalldataExecute(_diamondProxyAddress, _diamondCut, ok, resultDta);
    }
}
