// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "./interfaces/IDeterministicDeploymentProxy.sol";

contract DeterministicDeploymentProxy is IDeterministicDeploymentProxy {
    event ContractCreated(address contractAddress);

    mapping(address => bool) private _deployed;

    /// @inheritdoc IDeterministicDeploymentProxy
    function getDeploymentAddress(
        bytes32 salt,
        bytes calldata initializationCode
    )
        public
        view
        returns (address deploymentAddress)
    {
        deploymentAddress = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            address(this),
                            salt,
                            keccak256(
                                abi.encodePacked(
                                    initializationCode
                                )
                            )
                        )
                    )
                )
            )
        );
    }

    /// @inheritdoc IDeterministicDeploymentProxy
    function deploy(
        bytes32 salt,
        bytes calldata initializationCode
    )
        external
        payable
        returns (address deploymentAddress)
    {
        // move the initialization code from calldata to memory.
        bytes memory initCode = initializationCode;

        address targetDeploymentAddress = getDeploymentAddress(salt, initializationCode);

        require(!_deployed[targetDeploymentAddress], "ADDRESS_ALREADY_IN_USE");

        // using inline assembly: load data and length of data, then call CREATE2.
        assembly {                                  // solhint-disable-line
            let encoded_data := add(0x20, initCode) // load initialization code.
            let encoded_size := mload(initCode)     // load the init code's length.
            
            deploymentAddress := create2(           // call CREATE2 with 4 arguments.
                callvalue(),                        // forward any attached value.
                encoded_data,                       // pass in initialization code.
                encoded_size,                       // pass in init code's length.
                salt                                // pass in the salt value.
            )
        }

        require(deploymentAddress == targetDeploymentAddress, "INCORRECT_DEPLOYMENT_ADDRESS");

        _deployed[deploymentAddress] = true;

        emit ContractCreated(deploymentAddress);
    }
}