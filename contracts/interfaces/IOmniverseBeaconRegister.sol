// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

interface IOmniverseBeaconRegister {
    function registerAATransformer(
        uint256 chainId,
        address srcAddress,
        bytes calldata publicKey,
        bytes calldata signature
    ) external;

}