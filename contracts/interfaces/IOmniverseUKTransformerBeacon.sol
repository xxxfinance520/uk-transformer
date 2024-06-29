// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "../lib/omniverse-aa/lib/Types.sol";

struct ToOmniverseRecord {
    bytes32 txid;
    uint256 amount;
    bytes32 recipient;
    uint256 timestamp;
}

struct ToLocalRecord {
    bytes txData;
    bytes publicKey;
    uint256 amount;
    uint256 timestamp;
}

/**
 * @notice Interface of Omniverse usdt uktransformer
 */
interface IOmniverseUKTransformerBeacon {
    /**
     * @notice Emits when a user request to convert local token to Omniverse token
     * @param recipient Who will receive the Omniverse token
     * @param amount Token number requested to convert
     * @param txid The Omniverse transaction id which sends Omniverse token to the `recipient`
     */
    event LocalToOmniverse(bytes32 recipient, uint amount, bytes32 txid);

    /**
     * @notice Emits when a user request to convert Omniverse token to local token
     * @param recipient Who can claim the Local token
     * @param amount Token number requested to convert
     * @param txid The Omniverse transaction id which sends Omniverse token to the transformer contract
     */
    event OmniverseToLocal(address recipient, uint amount, bytes32 txid);

    /**
     * @notice Emits when the local token is claimed by the user
     * @param recipient Who claimed the token
     * @param amount Token number claimed
     * @param txid The Omniverse transaction id corresponding to the claim
     */
    event LocalTokenClaimed(address recipient, uint amount, bytes32 txid);

    /**
     * @notice Returns the price of kToken 
     * @return kprice price of kToken 
     */
    function getKprice() external view returns (uint128 kprice);

    /**
     * @notice Returns the Omniverse token asset id supported by the transformer
     * @return assetId Omniverse token asset id
     */
    function getAssetId() external view returns (bytes32 assetId);

    /**
     * @notice Returns the local token address supported by the transformer
     * @param localToken Local erc20 token address. 0 for ETH
     */
    function getLocalTokenAddress() external view returns (address localToken);

    /**
     * @notice Convert local tokens to Omniverse assets
     * @param recipient Who will receive Omniverse assets
     * @param amount How many tokens will be converted to Omniverse assets
     */
    function convertToOmniverse(bytes32 recipient, uint128 amount) external;

    // /**
    //  * @notice Convert Omniverse assets to local tokens
    //  * @param amount How many tokens will be converted to local tokens
    //  * @param txData Omniverse transaction data encoded with `abi.encode`
    //  * @param merkleProof The merkle proof of omniverse transaction
    //  * @param signerPubkey The public key of the Omniverse transaction signer
    //  */
     /**
     * @notice Convert Omniverse assets to local tokens
     * @param transferData Omniverse transaction data with signature
     * @param uncompressedPublicKey The uncompressed public key corresponding to the signer of the omniverse transaction
     */
    function convertToLocal(Types.Transfer calldata transferData, bytes calldata uncompressedPublicKey) external;

    /**
     * @notice Claim the local token after the transaction has been confirmed on the chain
     * @param txid The transaction id of the Omniverse transaction sent to the contract
     */
    function claim(bytes32 txid) external;

    /**
     * @notice Claim all claimable local tokens
     */
    function claimAll() external;

    /**
     * @notice Returns the transaction number of converting local token to Omniverse token
     * @param account Which account to query
     * @return number The transaction number
     */
    function getLocalToOmniverseTxNumber(address account) external view returns (uint256 number);

    /**
     * @notice Returns some records of transactions converting local token to Omniverse token starting at a specified index
     * @param account Which account to query
     * @param index From which index to query
     * @return records The converting records
     */
    function getLocalToOmniverseRecords(address account, uint256 index) external view returns (ToOmniverseRecord[] memory records);

    /**
     * @notice Returns the transaction number of converting Omniverse token to local token
     * @param account Which account to query
     * @return number The transaction number
     */
    function geOmniverseToLocalTxNumber(address account) external view returns (uint256 number);

    /**
     * @notice Returns some records of transactions converting Omniverse token to local token starting at a specified index
     * @param account Which account to query
     * @param index From which index to query
     * @return records The converting records
     */
    function getOmniverseToLocalRecords(address account, uint256 index) external view returns (ToLocalRecord[] memory records);
}
