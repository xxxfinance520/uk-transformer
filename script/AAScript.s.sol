// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../contracts/OmniverseUKTransformerBeacon.sol";
import "../contracts/lib/omniverse-aa/LocalEntry.sol";
contract AAScript is Script {
    
    address aa =  0x47C84c0B3c2452B6C22B9c07cac500fBA97f7Fa3;

    function getSignature(uint priKey, address ukTransformer) internal returns (bytes memory signature) {
         bytes memory rawData = abi.encodePacked(OMNIVERSE_AA_SC_PREFIX, "0x", Utils.bytesToHexString(abi.encodePacked(ukTransformer)), ", chain id: ", Strings.toString(block.chainid));
        bytes32 hash = keccak256(abi.encodePacked(PERSONAL_SIGN_PREFIX, bytes(Strings.toString(rawData.length)), rawData));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(priKey, hash);
        signature = abi.encodePacked(r, s, v);
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        VmSafe.Wallet memory  wallet = vm.createWallet(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);
        bytes memory signature = getSignature(deployerPrivateKey, address(aa));
        bytes memory pubKey = getPubKey(wallet);
        OmniverseUKTransformerBeacon(aa).register(pubKey, signature);
        vm.stopBroadcast();
    }

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