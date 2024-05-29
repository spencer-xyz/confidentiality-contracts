// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "./Ownable.sol";

abstract contract DataPrivacyFramework is Ownable {
    // Needed for avoiding "stack too deep" error
    struct InputData {
        address caller;
        string operation;
        bool active;
        uint256 timestampBefore;
        uint256 timestampAfter;
        bool falseKey;
        bool trueKey;
        uint256 uintParameter;
        address addressParameter;
        string stringParameter;
    }

    struct Condition {
        uint256 id;
        address caller;
        string operation;
        bool active;
        uint256 timestampBefore;
        uint256 timestampAfter;
        bool falseKey;
        bool trueKey;
        uint256 uintParameter;
        address addressParameter;
        string stringParameter;
    }

    enum ParameterType {
        None,
        UintParam,
        AddressParam,
        StringParam
    }

    address public constant ADDRESS_ALL = address(1);

    string public constant STRING_ALL = "*";

    bool public addressDefaultPermission;

    bool public operationDefaultPermission;

    mapping(string => bool) public allowedOperations;

    mapping(string => bool) public restrictedOperations;

    mapping(address => uint256) public callerRows;

    mapping(address => mapping(string => uint256)) public permissions; // caller => operation => idx

    uint256 private _conditionsCount;

    mapping(uint256 => Condition) public conditions; // idx => conditions

    constructor(bool addressDefaultPermission_, bool operationDefaultPermission_) Ownable(msg.sender) {
        addressDefaultPermission = addressDefaultPermission_;
        operationDefaultPermission = operationDefaultPermission_;
    }

    // Start with startIdx=0 and increment by chunkSize until the size of the returned array is less than chunk size
    // The consumer is expected to filter out inactive permissions and permissions of irrelevant callers
    function getPermissions(
        uint256 startIdx,
        uint256 chunkSize
    )
        external
        view
        returns (Condition[] memory)
    {
        uint256 arrSize = startIdx + chunkSize - 1 <= _conditionsCount ? chunkSize : _conditionsCount - startIdx + 1;

        Condition[] memory permissions_ = new Condition[](arrSize);

        for (uint256 i = 0; i < startIdx + chunkSize; i++) {
            permissions_[i] = conditions[i];
        }

        return permissions_;
    }

    function getPermission(
        address caller,
        string calldata operation
    )
        external
        view
        returns (bool)
    {
        return _evaluateCondition(
            caller,
            operation,
            ParameterType.None,
            0,
            address(0),
            ""
        );
    }

    function getPermission(
        address caller,
        string calldata operation,
        uint256 uintParameter
    )
        external
        view
        returns (bool)
    {
        return _evaluateCondition(
            caller,
            operation,
            ParameterType.UintParam,
            uintParameter,
            address(0),
            ""
        );
    }

    function getPermission(
        address caller,
        string calldata operation,
        address addressParameter
    )
        external
        view
        returns (bool)
    {
        return _evaluateCondition(
            caller,
            operation,
            ParameterType.AddressParam,
            0,
            addressParameter,
            ""
        );
    }

    function getPermission(
        address caller,
        string calldata operation,
        string calldata stringParameter
    )
        external
        view
        returns (bool)
    {
        return _evaluateCondition(
            caller,
            operation,
            ParameterType.StringParam,
            0,
            address(0),
            stringParameter
        );
    }

    function setAddressDefaultPermission(bool defaultPermission) external onlyOwner returns (bool) {
        require(addressDefaultPermission != defaultPermission, "DPF: INVALID_PERMISSION_CHANGE");

        addressDefaultPermission = defaultPermission;
        
        return true;
    }

    function setOperationDefaultPermission(bool defaultPermission) external onlyOwner returns (bool) {
        require(operationDefaultPermission != defaultPermission, "DPF: INVALID_PERMISSION_CHANGE");

        operationDefaultPermission = defaultPermission;
        
        return true;
    }

    function addAllowedOperation(string calldata operation) external onlyOwner returns (bool) {
        require(!allowedOperations[operation], "DPF: OPERATION_ALREADY_ALLOWED");

        allowedOperations[operation] = true;
        
        return true;
    }

    function removeAllowedOperation(string calldata operation) external onlyOwner returns (bool) {
        require(allowedOperations[operation], "DPF: OPERATION_NOT_ALLOWED");

        allowedOperations[operation] = false;
        
        return true;
    }

    function addRestrictedOperation(string calldata operation) external onlyOwner returns (bool) {
        require(!restrictedOperations[operation], "DPF: OPERATION_ALREADY_RESTRICTED");

        restrictedOperations[operation] = true;
        
        return true;
    }

    function removeRestrictedOperation(string calldata operation) external onlyOwner returns (bool) {
        require(restrictedOperations[operation], "DPF: OPERATION_NOT_RESTRICTED");

        restrictedOperations[operation] = false;
        
        return true;
    }

    function setPermission(InputData memory inputData) external onlyOwner returns (bool) {
        if (permissions[inputData.caller][inputData.operation] == 0) {
            _conditionsCount++;

            callerRows[inputData.caller]++;
            permissions[inputData.caller][inputData.operation] = _conditionsCount;

            conditions[_conditionsCount] = Condition(
                _conditionsCount,
                inputData.caller,
                inputData.operation,
                inputData.active,
                inputData.timestampBefore,
                inputData.timestampAfter,
                inputData.falseKey,
                inputData.trueKey,
                inputData.uintParameter,
                inputData.addressParameter,
                inputData.stringParameter
            );
        } else {
            if (inputData.active && !conditions[permissions[inputData.caller][inputData.operation]].active) {
                callerRows[inputData.caller]++;
            }

            if (!inputData.active && conditions[permissions[inputData.caller][inputData.operation]].active) {
                callerRows[inputData.caller]--;
            }

            Condition storage condition = conditions[permissions[inputData.caller][inputData.operation]];

            condition.active = inputData.active;
            condition.timestampBefore = inputData.timestampBefore;
            condition.timestampAfter = inputData.timestampAfter;
            condition.falseKey = inputData.falseKey;
            condition.trueKey = inputData.trueKey;
            condition.uintParameter = inputData.uintParameter;
            condition.addressParameter = inputData.addressParameter;
            condition.stringParameter = inputData.stringParameter;
        }

        return true;
    }

    function _evaluateCondition(
        address caller,
        string calldata operation,
        ParameterType parameterType,
        uint256 uintParameter,
        address addressParameter,
        string memory stringParameter
    )
        internal
        view
        returns (bool)
    {
        if (restrictedOperations[operation]) return false;
        if (!allowedOperations[STRING_ALL] && !allowedOperations[operation]) return false;

        Condition memory condition;
        
        if (conditions[permissions[caller][operation]].active) {
            condition = conditions[permissions[caller][operation]];
        }

        if (conditions[permissions[caller][STRING_ALL]].active) {
            condition = conditions[permissions[caller][STRING_ALL]];
        }

        if (!condition.active && callerRows[caller] > 0) {
            return operationDefaultPermission;
        }

        if (conditions[permissions[ADDRESS_ALL][operation]].active) {
            condition = conditions[permissions[ADDRESS_ALL][operation]];
        }

        if (conditions[permissions[ADDRESS_ALL][STRING_ALL]].active) {
            condition = conditions[permissions[ADDRESS_ALL][STRING_ALL]];
        }

        if (!condition.active) {
            return addressDefaultPermission;
        }

        if (condition.falseKey) return false;

        if (condition.trueKey) return true;

        if (condition.timestampBefore > 0 && condition.timestampBefore > block.timestamp) return false;

        if (condition.timestampAfter > 0 && condition.timestampAfter < block.timestamp) return false;

        if (parameterType == ParameterType.UintParam && condition.uintParameter != uintParameter) {
            return false;
        } else if (parameterType == ParameterType.AddressParam && condition.addressParameter != addressParameter) {
            return false;
        } else if (parameterType == ParameterType.StringParam && keccak256(abi.encodePacked(condition.stringParameter)) != keccak256(abi.encodePacked(stringParameter))) {
            return false;
        }

        return true;
    }
}
