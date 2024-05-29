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

    struct Conditions {
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

    uint256 private _permissionsCount;

    mapping(uint256 => Conditions) private _permissions; // idx => conditions

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
        returns (Conditions[] memory)
    {
        uint256 arrSize = startIdx + chunkSize - 1 <= _permissionsCount ? chunkSize : _permissionsCount - startIdx + 1;

        Conditions[] memory permissions_ = new Conditions[](arrSize);

        for (uint256 i = 0; i < startIdx + chunkSize; i++) {
            permissions_[i] = _permissions[i];
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
        return _evaluateConditions(
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
        return _evaluateConditions(
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
        return _evaluateConditions(
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
        return _evaluateConditions(
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
            _permissionsCount++;

            callerRows[inputData.caller]++;
            permissions[inputData.caller][inputData.operation] = _permissionsCount;

            _permissions[_permissionsCount] = Conditions(
                _permissionsCount,
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
            if (inputData.active && !_permissions[permissions[inputData.caller][inputData.operation]].active) {
                callerRows[inputData.caller]++;
            }

            if (!inputData.active && _permissions[permissions[inputData.caller][inputData.operation]].active) {
                callerRows[inputData.caller]--;
            }

            Conditions storage conditions = _permissions[permissions[inputData.caller][inputData.operation]];

            conditions.active = inputData.active;
            conditions.timestampBefore = inputData.timestampBefore;
            conditions.timestampAfter = inputData.timestampAfter;
            conditions.falseKey = inputData.falseKey;
            conditions.trueKey = inputData.trueKey;
            conditions.uintParameter = inputData.uintParameter;
            conditions.addressParameter = inputData.addressParameter;
            conditions.stringParameter = inputData.stringParameter;
        }

        return true;
    }

    function _evaluateConditions(
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

        Conditions memory conditions;
        
        if (_permissions[permissions[caller][operation]].active) {
            conditions = _permissions[permissions[caller][operation]];
        }

        if (_permissions[permissions[caller][STRING_ALL]].active) {
            conditions = _permissions[permissions[caller][STRING_ALL]];
        }

        if (!conditions.active && callerRows[caller] > 0) {
            return operationDefaultPermission;
        }

        if (_permissions[permissions[ADDRESS_ALL][operation]].active) {
            conditions = _permissions[permissions[ADDRESS_ALL][operation]];
        }

        if (_permissions[permissions[ADDRESS_ALL][STRING_ALL]].active) {
            conditions = _permissions[permissions[ADDRESS_ALL][STRING_ALL]];
        }

        if (!conditions.active) {
            return addressDefaultPermission;
        }

        if (conditions.falseKey) return false;

        if (conditions.trueKey) return true;

        if (conditions.timestampBefore > 0 && conditions.timestampBefore > block.timestamp) return false;

        if (conditions.timestampAfter > 0 && conditions.timestampAfter < block.timestamp) return false;

        if (parameterType == ParameterType.UintParam && conditions.uintParameter != uintParameter) {
            return false;
        } else if (parameterType == ParameterType.AddressParam && conditions.addressParameter != addressParameter) {
            return false;
        } else if (parameterType == ParameterType.StringParam && keccak256(abi.encodePacked(conditions.stringParameter)) != keccak256(abi.encodePacked(stringParameter))) {
            return false;
        }

        return true;
    }
}
