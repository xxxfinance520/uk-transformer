// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
library KeyUtils {

    function getPubKey(VmSafe.Wallet memory wallet) internal returns(bytes memory pubKey) {
        bytes memory  b1 = toBytes0(wallet.publicKeyX);
        bytes memory  b2 = toBytes0(wallet.publicKeyY);
        pubKey = new bytes(64);
        for (uint i =0;i<32;i++) {
            pubKey[i] = b1[i];
            pubKey[i+32] = b2[i];
        }
    }

    function toBytes0(uint _num) internal returns (bytes memory _ret) {
        _ret = new bytes(32);
        assembly { mstore(add(_ret, 32), _num) }
        return _ret;
    }
}