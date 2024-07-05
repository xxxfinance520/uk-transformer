// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../contracts/OmniverseUKTransformerBeacon.sol";
contract DeployAA is Script {
    
    address config = 0x46B4F41700b5e864Da26489c2bD3ec5b8244c5bb;
    address localToken = 0x701224564cB13Cb55AB4bfd64a0bBc4b7F756a51;
    address poseidon = 0x1640C65b24180b43F5493c9c3C3caCC1870CD726;
    address eip712 = 0xd03A47C67F69880eA27Fd48da4600b2e35D349aC;
    bytes32 constant TOKEN_ASSET_ID =
        0x0000000000000000000000000000000000000000000000000000000000000000;
    bytes32 constant UTOX_TX = 0xa1e9ad3812b3510a4c36b1892902a985b57f081e9ac511469c8262dcec9d2b35;
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
            amount: 100000000000000
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