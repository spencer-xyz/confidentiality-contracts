// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "../DataPrivacyFramework.sol";

contract MockDataPrivacyFramework is DataPrivacyFramework {
    constructor() DataPrivacyFramework(true, true) {}
}