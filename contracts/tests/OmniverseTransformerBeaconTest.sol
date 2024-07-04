// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "../OmniverseUKTransformerBeacon.sol";
import "../lib/omniverse-aa/lib/Types.sol";

contract OmniverseTransformerBeaconTest is OmniverseUKTransformerBeacon {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    constructor(address _sysConfig, bytes memory _AASignerPubkey,
        bytes32 _assetId, address _localToken, Types.UTXO[] memory _utxos, address _poseidon, address _eip712)
        OmniverseUKTransformerBeacon(_sysConfig, _AASignerPubkey, _assetId, _localToken, _utxos, _poseidon, _eip712) {
    }


    function setLocalEntry(address _localEntry) public {
        sysConfig.localEntry = _localEntry;
    }

    function setStateKeeper(address _stateKeeper) public {
        sysConfig.stateKeeper = _stateKeeper;
    }

    function getTxid(bytes calldata txData) public view returns (bytes32) {
        (Types.Transfer memory transferData) = abi.decode(txData, (Types.Transfer));
        bytes memory txDataPacked = Utils.TransferToBytes(transferData);
        bytes32 txid = Utils.calTxId(txDataPacked, poseidon);
        return txid;
    }

    function getOmniToLocalCache(address account) public view returns (bytes32[] memory cache) {
        cache = new bytes32[](omniToLocalCache[account].length());
        for (uint i = 0; i < omniToLocalCache[account].length(); i++) {
            cache[i] = omniToLocalCache[account].at(i);
        }
    }
}
