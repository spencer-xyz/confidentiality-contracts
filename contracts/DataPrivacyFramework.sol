// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "./Ownable.sol";

abstract contract DataPrivacyFramework is Ownable {
    struct ConditionValue {
        uint256 temp;
    }

    address public constant ADDRESS_ALL = address(1);

    string public constant STRING_ALL = "*";

    bool public address_default_permission = true;

    bool public operation_default_permission = true;

    mapping(string => bool) public allowed_operations;

    mapping(string => bool) public restricted_operations;

    mapping(address => mapping(string => mapping(string => ConditionValue))) public permissions; // caller => operation => condition

    constructor() Ownable(msg.sender) {}

    function getPermission() public view returns (bool) {
        return false;
    }

    function setPermission() public onlyOwner returns (bool) {
        return false;
    }
}
