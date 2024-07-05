pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "../contracts/lib/omniverse-aa/lib/OmniverseEIP712.sol";
import "../contracts/lib/omniverse-aa/lib/Poseidon.sol";
import "../contracts/lib/omniverse-aa/lib/Utils.sol";
import "../contracts/lib/omniverse-aa/LocalEntry.sol";
import "../contracts/lib/omniverse-aa/OmniverseSysConfig.sol";
import "../contracts/OmniverseUKTransformerBeacon.sol";
import "../contracts/tests/Token.sol";
contract UKTransformerTest is Test {
    bytes constant   TX_ID =
        '0x1122334455667788112233445566778811223344556677881122334455667788';
    uint256 constant GAS_PER_UTXO = 1000;
    bytes constant UTXO_INDEX = '287454020';
    bytes constant TOKEN_NUM = '1000';
    bytes32 constant TOKEN_ASSET_ID =
        0x0000000000000000000000000000000000000000000000000000000000000001;
    bytes constant NOT_EXISTING_TOKEN_ASSET_ID =
        '0x0000000000000000000000000000000000000000000000000000000000000009';
    bytes constant SIGNATURE =
        '0x3a42c95c375c019bb6dfdac8bc15bb06de455ce88edb211756d3edea69dbdc526d4f8b99ad86f33b07137649d6c8ef78b398e95d6a21748ae00db750e3814f7b1c';

    // gas config
    bytes32 constant GAS_ASSET_ID =0x0000000000000000000000000000000000000000000000000000000000000000;
    bytes32 constant GAS_RECEIVER =0x1234567812345678123456781234567812345678123456781234567812345678;
    uint128 constant GAS_FEE = 10;

    // sys config
    uint256 constant UTXO_NUM = 20;
    uint8 constant DECIMALS = 8;
    uint8 constant TOKEN_NAME_LIMIT = 24;
    address constant STATE_KEEPER = address(0x0000000000000000000000000000000000000000);
    uint256 constant PRI_KEY = 1;
    Poseidon poseidon;
    OmniverseEIP712 eip712;
    Token localToken;
    LocalEntry localEntry;
    OmniverseSysConfigAA config;
    OmniverseUKTransformerBeacon  ukTransformer;
    VmSafe.Wallet  wallet;
    
    function setUp() public {
        //create wallet
        wallet = vm.createWallet(PRI_KEY);
        bytes memory pubKey = getPubKey(wallet);
        console.logBytes(pubKey);
        vm.startPrank(wallet.addr);
        poseidon  = new Poseidon();
        localEntry = new LocalEntry();
        //create config
        config = new OmniverseSysConfigAA(
            GAS_ASSET_ID,
            GAS_RECEIVER,
            GAS_FEE,
            UTXO_NUM,
            DECIMALS,
            TOKEN_NAME_LIMIT,
            STATE_KEEPER,
            address(localEntry));
        eip712 = new OmniverseEIP712("Omniverse Transaction", "1", 1, 0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC);
        localToken = new Token();
       
        Types.UTXO[] memory _utxos = new Types.UTXO[](2);
        //    bytes32 omniAddress;
        // bytes32 assetId;
        // bytes32 txid;
        // uint64 index;
        // uint128 amount;
        _utxos[0]  = Types.UTXO({
            omniAddress: bytes32(wallet.publicKeyX),
            assetId: GAS_ASSET_ID,
            txid:  bytes32(0),
            index:  0,
            amount: 10**18
        });
        _utxos[1]  = Types.UTXO({
            omniAddress: bytes32(wallet.publicKeyX),
            assetId: TOKEN_ASSET_ID,
            txid:  bytes32(0),
            index:  0,
            amount: 10**18
        });
      
        ukTransformer = new OmniverseUKTransformerBeacon(
            address(config),
            pubKey,
            TOKEN_ASSET_ID,
            address(localToken),
            _utxos,
            address(poseidon),
            address(eip712)
        );
        bytes memory signature = getSignature(PRI_KEY, address(ukTransformer));
        ukTransformer.register(pubKey, signature);
    }

    function getSignature(uint priKey, address ukTransformer) internal returns (bytes memory signature) {
         bytes memory rawData = abi.encodePacked(OMNIVERSE_AA_SC_PREFIX, "0x", Utils.bytesToHexString(abi.encodePacked(ukTransformer)), ", chain id: ", Strings.toString(block.chainid));
        bytes32 hash = keccak256(abi.encodePacked(PERSONAL_SIGN_PREFIX, bytes(Strings.toString(rawData.length)), rawData));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(priKey, hash);
        signature = abi.encodePacked(r, s, v);
    }

    function toBytes0(uint _num) internal returns (bytes memory _ret) {
        _ret = new bytes(32);
        assembly { mstore(add(_ret, 32), _num) }
        return _ret;
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

    function test_convertToOmniverse() public {
       uint128 amount = 1000;
       uint128 uAmount = amount * ukTransformer.getKprice() / ukTransformer.getDenominatorOfPrice();
       localToken.mint(wallet.addr, uAmount);
       localToken.approve(address(ukTransformer), uAmount);
       ukTransformer.convertToOmniverse( bytes32(wallet.publicKeyX), amount);
       (uint256 txIndex, OmniverseTxWithTxid memory unsignedTx)  = ukTransformer.getUnsignedTx();
       assert(txIndex == 0);
       assert(unsignedTx.txid != bytes32(0));
       uint256 txNumber = ukTransformer.getLocalToOmniverseTxNumber(wallet.addr);
       assert(txNumber == 1);
       ToOmniverseRecord[] memory records = ukTransformer.getLocalToOmniverseRecords( wallet.addr, 0);
       assert(records.length == 1);
    }

    function test_setPrice() public {
        ukTransformer.setKprice(1e9);
        assert(ukTransformer.getKprice() == 1e9);
    }
    function testFail_Subtract43() public {
        require(1==0, "");
    }
}