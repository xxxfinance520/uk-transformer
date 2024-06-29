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

    uint128 constant K_PRICE = 2;
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
     * @notice Throws when token in the transformer not enough
     * @param claimNum The token number the user want to claim
     * @param tokenNum How many tokens in the transformer
     */
    error NotEnoughLocalToken(uint256 claimNum, uint256 tokenNum);

    /**
     * @notice Throws when there is no Omniverse token is sent to the transformer
     */
    error NoOmniverseTokenReceived();

    /**
     * @notice Throws when the transaction submitted to convert Omniverse tokens to local erc20 tokens duplicates
     * @param txid The transaction id of the Omniverse transaction
     */
    error TransactionDuplicated(bytes32 txid);

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
        ToLocalRecord memory record = omniToLocalRecords[signer].get(txid);

        uint256 tokenNum = IERC20(localTokenAddress).balanceOf(address(this));

        uint256 receivedAmount = record.amount * getKprice();

        if (receivedAmount > tokenNum) {
            revert NotEnoughLocalToken(receivedAmount, tokenNum);
        }
        
        IERC20(localTokenAddress).transfer(signer, receivedAmount);
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
        uint128 u_amount = amount * getKprice();
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
     * @notice See {IOmniverseUKTransformerBeacon - convertToLocal}
     * Claim the local token after the transaction has been confirmed on the chain
     * @param txid The transaction id of the Omniverse transaction sent to the contract
     */
    function claim(bytes32 txid) external {
        ToLocalRecord memory record = omniToLocalRecords[msg.sender].get(txid);
        OmniverseTx memory otx = OmniverseTx(
            Types.TxType.Transfer,
            record.txData
        );
        _handleOmniverseTx(otx, new bytes32[](0), record.publicKey, bytes(""));

        address addrPubkey = Utils.pubKeyToAddress(record.publicKey);
        omniToLocalCache[msg.sender].remove(txid);
        emit LocalTokenClaimed(addrPubkey, record.amount, txid);
    }

    /**
     * @notice See {IOmniverseUKTransformerBeacon - claimAll}
     * Claim all claimable local tokens
     */
    function claimAll() external {
        bytes32[] memory cache = new bytes32[](omniToLocalCache[msg.sender].length());
        for (uint i = 0; i < omniToLocalCache[msg.sender].length(); i++) {
            cache[i] = omniToLocalCache[msg.sender].at(i);
        }

        for (uint i = 0; i < cache.length; i++) {
            bytes32 txid = cache[i];
            (bool success, bytes memory data) = address(this).delegatecall(abi.encodeWithSignature("claim(bytes32)", txid));
            if (!success) {
                if (bytes4(data) == bytes4(keccak256(bytes("TransactionAlreadyHandled(bytes32)")))) {
                    omniToLocalCache[msg.sender].remove(txid);
                }
            }
        }
    }

    /**
     * @notice See {IOmniverseUKTransformerBeacon - convertToLocal}
     * Convert Omniverse assets to local tokens
     * @param transferData Omniverse transaction data with signature
     * @param uncompressedPublicKey The uncompressed public key corresponding to the signer of the omniverse transaction
     */
    function convertToLocal(Types.Transfer calldata transferData, bytes calldata uncompressedPublicKey) external {
        bytes32 _pubkey;
        assembly {
            _pubkey := calldataload(add(uncompressedPublicKey.offset, 0))
        }
        addrPubkey = Utils.pubKeyToAddress(uncompressedPublicKey);

        if (_pubkey != transferData.feeInputs[0].omniAddress) {
            revert PublicKeyNotMatch(_pubkey, transferData.feeInputs[0].omniAddress);
        }

        if (transferData.assetId != omniAssetId) {
            revert NotSupportedAsset(transferData.assetId);
        }

        uint256 receivedTokenNum = 0;
        if (transferData.assetId == sysConfig.feeConfig.assetId) {
            for (uint i = 0; i < transferData.feeOutputs.length; i++) {
                if (transferData.feeOutputs[i].omniAddress == pubkey) {
                    receivedTokenNum += transferData.feeOutputs[i].amount;
                }
            }
        }
        else {
            for (uint i = 0; i < transferData.outputs.length; i++) {
                if (transferData.outputs[i].omniAddress == pubkey) {
                    receivedTokenNum += transferData.outputs[i].amount;
                }
            }
        }

        if (receivedTokenNum == 0) {
            revert NoOmniverseTokenReceived();
        }

        // calculate the transaction id
        bytes memory txDataPacked = Utils.TransferToBytes(transferData);
        bytes32 txid = Utils.calTxId(txDataPacked, poseidon);

        if (omniToLocalRecords[addrPubkey].contains(txid)) {
            revert TransactionDuplicated(txid);
        }

        omniToLocalRecords[addrPubkey].set(txid, ToLocalRecord(
            abi.encode(transferData),
            uncompressedPublicKey,
            receivedTokenNum,
            block.timestamp
        ));
        omniToLocalCache[addrPubkey].add(txid);
        emit OmniverseToLocal(addrPubkey, receivedTokenNum, txid);
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

    /**
     * @notice See {IOmniverseUKTransformerBeacon - geOmniverseToLocalTxNumber}
     * Returns the transaction number of converting Omniverse token to local token
     * @param account Which account to query
     * @return number The transaction number
     */
    function geOmniverseToLocalTxNumber(address account) external view returns (uint256 number) {
        number = omniToLocalRecords[account].length();
    }

    /**
     * @notice See {IOmniverseUKTransformerBeacon - getOmniverseToLocalRecords}
     * Returns some records of transactions converting Omniverse token to local token starting at a specified index
     * @param account Which account to query
     * @param index From which index to query
     * @return records The converting records
     */
    function getOmniverseToLocalRecords(address account, uint256 index) external view returns (ToLocalRecord[] memory records) {
        uint256 number = omniToLocalRecords[account].length();
        if (number == 0) {
            return new ToLocalRecord[](0);
        }

        uint end = index;
        if (end > number - 1) {
            end = number - 1;
        }

        uint start = 0;
        if (start >= PAGE_NUM - 1) {
            start = end - PAGE_NUM + 1;
        }

        records = new ToLocalRecord[](end - start + 1);
        for (uint i = start; i <= end; i++) {
            (, ToLocalRecord memory value) = omniToLocalRecords[account].at(i);
            records[end - i] = value;
        }
    }
}
