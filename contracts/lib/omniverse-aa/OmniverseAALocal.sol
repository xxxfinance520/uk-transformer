// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./OmniverseAABase.sol";

contract OmniverseAALocal is OmniverseAABase {
    constructor(address _sysConfig, bytes memory  _AASigner, Types.UTXO[] memory _utxos, address _poseidon, address _eip712)
        OmniverseAABase(_sysConfig, _AASigner, _utxos, _poseidon, _eip712) {
    }
}
