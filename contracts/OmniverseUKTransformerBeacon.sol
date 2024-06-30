// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./lib/omniverse-aa/lib/Types.sol";
import "./lib/omniverse-aa/OmniverseAABeacon.sol";
import "./lib/omniverse-aa/lib/Utils.sol";
import "./interfaces/IOmniverseUKTransformerBeacon.sol";
import "./EnumerableTxRecord.sol";

uint256 constant PAGE_NUM = 10;


contract OmniverseUKTransformerBeacon is OmniverseAABeacon, IOmniverseUKTransformerBeacon {
    using EnumerableTxRecord for EnumerableTxRecord.Bytes32ToOmniToLocalRecord;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    uint128 constant K_PRICE = 2e8;
    uint128 constant PRICE_DECIMAL_NUM = 1e8;
    // Omniverse asset id
    bytes32 omniAssetId;
    // ERC20 token address
    address localTokenAddress;
    // Records of local converting to omniverse
    mapping(address => ToOmniverseRecord[]) localToOmniRecords;
    // Records of omniverse converting to local
    mapping(address => EnumerableTxRecord.Bytes32ToOmniToLocalRecord) omniToLocalRecords;
    // Cache of omniverse converting to local
    mapping(address => EnumerableSet.Bytes32Set) omniToLocalCache;

    /**
     * @notice Throws when an Omniverse transaction already handled
     * @param assetId The asset id of the omniverse token
     */
    error NotSupportedAsset(bytes32 assetId);

    /**
     * @notice Throws when uncompressed public key does not match the public key in inputs
     * @param pubKey The public key computed from uncompressed public key
     * @param signer The omniverse account in inputs
     */
    error PublicKeyNotMatch(bytes32 pubKey, bytes32 signer);

    constructor(bytes32 assetId, address localToken, bytes memory uncompressedPublicKey, Types.UTXO[] memory utxos,
        address _poseidon, address _eip712) OmniverseAABeacon(uncompressedPublicKey, utxos, _poseidon, _eip712) {
            omniAssetId = assetId;
            localTokenAddress = localToken;
    }

    /**
     * @notice See {OmniverseAABeacon - onTransfer}
     * Called when an omniverse transaction is Transfer
     * @param txid The Omniverse transaction id
     * @param signer The corresponding ETH address of the Omniverse signer
     * @param data Transfer data
     * @param customData Custom data submitted by user
     */
    function onTransfer(bytes32 txid, address signer, Types.Transfer memory data, bytes memory customData) internal virtual override {
    }

     /**
     * @notice See {IOmniverseUKTransformerBeacon - getKprice}
     * Returns the price of kToken 
     * @return kprice price of kToken 
     */
    function getKprice() public view returns( uint128) {
        return K_PRICE;
    }

    /**
     * @notice See {IOmniverseUKTransformerBeacon - getKprice}
     * Returns the price of kToken 
     * @return kprice price of kToken 
     */
    function getKprieDecimalVal() public view returns( uint128) {
        return K_PRICE;
    }

    /**
     * @notice See {IOmniverseUKTransformerBeacon - getAssetId}
     * Returns the Omniverse token asset id supported by the transformer
     * @return assetId Omniverse token asset id
     */
    function getAssetId() external view returns (bytes32 assetId) {
        assetId = omniAssetId;
    }

    /**
     * @notice See {IOmniverseUKTransformerBeacon - getLocalTokenAddress}
     * Returns the local token address supported by the transformer
     * @param localToken Local erc20 token address. 0 for ETH
     */
    function getLocalTokenAddress() external view returns (address localToken) {
        localToken = localTokenAddress;
    }

    /**
     * @notice See {IOmniverseUKTransformerBeacon - convertToOmniverse}
     * Convert local tokens to Omniverse assets
     * @param recipient Who will receive Omniverse assets
     * @param amount How many tokens will be converted to Omniverse assets
     */
    function convertToOmniverse(bytes32 recipient, uint128 amount) external {
        uint128 u_amount = amount * getKprice()/PRICE_DECIMAL_NUM;
        IERC20(localTokenAddress).transferFrom(msg.sender, address(this), u_amount);
        Types.Output[] memory outputs = new Types.Output[](1);
        outputs[0] = Types.Output(
            recipient,
            amount
        );
        (bytes32 txid, ) = _constructTransfer(omniAssetId, outputs);
        localToOmniRecords[msg.sender].push(ToOmniverseRecord (
            txid,
            amount,
            recipient,
            block.timestamp
        ));
        emit LocalToOmniverse(recipient, amount, txid);
    }

  
    /**
     * @notice See {IOmniverseUKTransformerBeacon - getLocalToOmniverseTxNumber}
     * Returns the transaction number of converting local token to Omniverse token
     * @param account Which account to query
     * @return number The transaction number
     */
    function getLocalToOmniverseTxNumber(address account) external view returns (uint256 number) {
        number = localToOmniRecords[account].length;
    }

    /**
     * @notice See {IOmniverseUKTransformerBeacon - getLocalToOmniverseRecords}
     * Returns some records of transactions converting local token to Omniverse token starting at a specified index
     * @param account Which account to query
     * @param index From which index to query
     * @return records The converting records
     */
    function getLocalToOmniverseRecords(address account, uint256 index) external view returns (ToOmniverseRecord[] memory records) {
        uint256 number = localToOmniRecords[account].length;
        if (number == 0) {
            return new ToOmniverseRecord[](0);
        }

        uint end = index;
        if (end > number - 1) {
            end = number - 1;
        }

        uint start = 0;
        if (start >= PAGE_NUM - 1) {
            start = end - PAGE_NUM + 1;
        }

        records = new ToOmniverseRecord[](end - start + 1);
        for (uint i = start; i <= end; i++) {
            records[end - i] = localToOmniRecords[account][i];
        }
    }
}
