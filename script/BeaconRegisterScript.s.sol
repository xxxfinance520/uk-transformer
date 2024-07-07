// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../contracts/OmniverseUKTransformerBeacon.sol";
import "../contracts/lib/omniverse-aa/LocalEntry.sol";
import  "./utils/KeyUtils.sol";
import  "../contracts/interfaces/IOmniverseBeaconRegister.sol";
contract BeaconRegisterScript is Script {
    
    address aa =  0x444B38466F9cd98D5936a59E36cA95851EbAB409;
    address beacon =  0x47C84c0B3c2452B6C22B9c07cac500fBA97f7Fa3;

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
        bytes memory pubKey = KeyUtils.getPubKey(wallet);
        console.logBytes(pubKey);
        IOmniverseBeaconRegister(beacon).registerAATransformer(block.chainid, aa, pubKey, signature);
        vm.stopBroadcast();
    }
}