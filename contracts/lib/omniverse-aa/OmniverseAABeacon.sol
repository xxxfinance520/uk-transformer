// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./OmniverseAABase.sol";
import "./interfaces/IStateKeeperBeacon.sol";
import "./lib/Utils.sol";
import "./lib/Types.sol";

contract OmniverseAABeacon is OmniverseAABase {
    /**
     * @notice Throws when transaction not exists in state keeper
     * @param txid The transaction id
     */
    error TransactionNotExistsInStateKeeper(bytes32 txid);

    /**
     * @notice Throws when an Omniverse transaction already handled
     * @param txid Transaction id
     */
    error TransactionAlreadyHandled(bytes32 txid);

    constructor(bytes memory uncompressedPublicKey, Types.UTXO[] memory utxos, address _poseidon, address _eip712) OmniverseAABase(uncompressedPublicKey, utxos, _poseidon, _eip712) {
    }

    /**
     * @notice Handles an omniverse transaction sent from global exec server
     * @param omniTx The transaction data to be handled
     * @param merkleProof The merkle proof of omniverse transaction
     * @param signerPubkey The public key of the Omniverse transaction signer
     * @param customData Custom data submitted by user
     */
    function _handleOmniverseTx(OmniverseTx memory omniTx, bytes32[] memory merkleProof, bytes memory signerPubkey, bytes memory customData) internal {
        // verify signature
        (address ethAddr) = eip712.verifySignature(omniTx.txType, omniTx.txData, signerPubkey);
         
        // calculate the transaction id
        bytes32 txid;

        if (omniTx.txType == Types.TxType.Deploy) {
            Types.Deploy memory deployTx = abi.decode(omniTx.txData, (Types.Deploy));
            bytes memory txDataPacked = Utils.deployToBytes(deployTx);
            txid = Utils.calTxId(txDataPacked, poseidon);
            onDeploy(txid, ethAddr, deployTx, customData);
        }
        else if (omniTx.txType == Types.TxType.Mint) {
            Types.Mint memory mintTx = abi.decode(omniTx.txData, (Types.Mint));
            bytes memory txDataPacked = Utils.MintToBytes(mintTx);
            txid = Utils.calTxId(txDataPacked, poseidon);
            onMint(txid, ethAddr, mintTx, customData);
        }
        else if (omniTx.txType == Types.TxType.Transfer) {
            Types.Transfer memory transferTx = abi.decode(omniTx.txData, (Types.Transfer));
            bytes memory txDataPacked = Utils.TransferToBytes(transferTx);
            txid = Utils.calTxId(txDataPacked, poseidon);
            onTransfer(txid, ethAddr, transferTx, customData);
        }

        bool txExist = IStateKeeperBeacon(sysConfig.stateKeeper).containsTxID(txid);

        if (!txExist) {
            revert TransactionNotExistsInStateKeeper(txid);
        }

        if (handledTxs[txid] != address(0)) {
            revert TransactionAlreadyHandled(txid);
        }

        handledTxs[txid] = ethAddr;
    }
}
