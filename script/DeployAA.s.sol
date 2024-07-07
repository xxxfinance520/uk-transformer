// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../contracts/OmniverseUKTransformerBeacon.sol";
contract DeployAA is Script {
    
    address config = 0x9BEBB619B7aab059410f433154B92b3EC6C47C08;
    address localToken = 0x701224564cB13Cb55AB4bfd64a0bBc4b7F756a51;
    address poseidon = 0xEFF03fAD6e237193c0af5c5Fc8A9c8ddCE624327;
    address eip712 = 0x8a2Ac632A9FE20DD193C87E3d899190C817f93D1;
    bytes32 constant TOKEN_ASSET_ID =
        0x0000000000000000000000000000000000000000000000000000000000000000;
    bytes32 constant UTOX_TX = 0x08322656be5edad0fda7e79fe757891b1b74e9e264f2c9a1a53e9a19500f1226;
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        VmSafe.Wallet memory  wallet = vm.createWallet(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);
        bytes memory pubKey = getPubKey(wallet);
         Types.UTXO[] memory _utxos = new Types.UTXO[](1);
         _utxos[0]  = Types.UTXO({
            omniAddress: bytes32(wallet.publicKeyX),
            assetId: TOKEN_ASSET_ID,
            txid:  UTOX_TX,
            index:  1,
            amount: 5000000000000
        });
        OmniverseUKTransformerBeacon aa = new OmniverseUKTransformerBeacon(
            config,
            pubKey,
        TOKEN_ASSET_ID,
            localToken,
            _utxos,
            poseidon,
            eip712);
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