// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IDeterministicDeploymentProxy {
    /**
     * @notice computes the expected deployment address of a contract
     * @param salt 32 byte salt used for avoiding collisions (can also be used to "mine" specific addresses)
     * @param initializationCode initialization code of the contract to deploy
     * @return deploymentAddress the expected deployment address
     */
    function getDeploymentAddress(bytes32 salt, bytes calldata initializationCode) external view returns (address deploymentAddress);

    /**
     * @notice deploys a new contract
     * @param salt 32 byte salt used for avoiding collisions (can also be used to "mine" specific addresses)
     * @param initializationCode initialization code of the contract to deploy
     * @return deploymentAddress the address of the newly deployed contract
     */
    function deploy(bytes32 salt, bytes calldata initializationCode) external payable returns (address deploymentAddress);
}