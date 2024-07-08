// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../contracts/OmniverseUKTransformerBeacon.sol";
import  "./utils/KeyUtils.sol";
contract DepositUTOXToAA is Script {
    
   address aa =  0xCFC12F78938aECd836A5cafE9a667aB5e8BC9ecc;
    bytes32 constant TOKEN_ASSET_ID =
        0x0000000000000000000000000000000000000000000000000000000000000000;
    bytes32 constant UTOX_TX = 0x361680d2979527e1fb9b8e451f34cf21f8e057ecf28e87557bbcfb40e8ef650a;
    uint64 constant  UTOX_INDEX  = 1;
    uint64 constant  UTOX_AMOUNT  = 10000000000000;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        VmSafe.Wallet memory  wallet = vm.createWallet(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);
        bytes memory pubKey = KeyUtils.getPubKey(wallet);
         Types.UTXO[] memory _utxos = new Types.UTXO[](1);
         _utxos[0]  = Types.UTXO({
            omniAddress: bytes32(wallet.publicKeyX),
            assetId: TOKEN_ASSET_ID,
            txid:  UTOX_TX,
            index:  1,
            amount: 10000000000000
        });
        OmniverseUKTransformerBeacon(aa).deposit(_utxos);
        vm.stopBroadcast();
    }
}