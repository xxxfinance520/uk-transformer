import {
    time,
    loadFixture
} from '@nomicfoundation/hardhat-toolbox/network-helpers';
import { anyValue } from '@nomicfoundation/hardhat-chai-matchers/withArgs';
import { expect } from 'chai';
import hre from 'hardhat';
import * as utils from './utils';
import ecdsa from 'secp256k1';

enum TX_TYPE {
    DEPLOY,
    MINT,
    TRANSFER
}

const TX_ID =
    '0x1122334455667788112233445566778811223344556677881122334455667788';
const GAS_PER_UTXO = 1000;

const UTXO_INDEX = '287454020';
const UTXO_NUM = 10;
const TOKEN_NUM = '1000';
const GAS_ASSET_ID =
    '0x0000000000000000000000000000000000000000000000000000000000000000';
const TOKEN_ASSET_ID =
    '0x0000000000000000000000000000000000000000000000000000000000000001';
const NOT_EXISTING_TOKEN_ASSET_ID =
    '0x0000000000000000000000000000000000000000000000000000000000000009';

const DOMAIN = {
    name: 'Omniverse Transaction',
    version: '1',
    chainId: 1,
    verifyingContract: '0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC'
};

function getWallets() {
    let accounts = hre.config.networks.hardhat.accounts;
    let wallets = [];
    for (let index = 0; index < 10; index++) {
        const wallet = hre.ethers.HDNodeWallet.fromPhrase(
            accounts.mnemonic,
            accounts.password,
            `${accounts.path}/${index}`
        );
        var pubKey = ecdsa.publicKeyCreate(
            Buffer.from(wallet.privateKey.substring(2), 'hex'),
            false
        );
        wallets.push({
            privateKey: wallet.privateKey,
            publicKey: '0x' + Buffer.from(pubKey).toString('hex').substring(2),
            compressed: '0x' + wallet.publicKey.substring(4)
        });
    }
    return wallets;
}

function generateUTXOs(assetId: string, pubkey: string) {
    let UTXOs = [];
    for (let i = 0; i < UTXO_NUM; i++) {
        let txid = `0x${i.toString().padStart(64, '0')}`;
        let UTXO: {
            omniAddress: string;
            assetId: string;
            txid: string;
            index: string;
            amount: string;
        } = {
            txid,
            omniAddress: pubkey,
            assetId: assetId,
            index: i.toString(),
            amount: ((i + 1) * GAS_PER_UTXO).toString()
        };
        UTXOs.push(UTXO);
    }
    return UTXOs;
}

function getTransferTx(sender: string, receiver: string): utils.Transfer {
    return {
        assetId: TOKEN_ASSET_ID,
        signature: '',
        inputs: [
            {
                txid: TX_ID,
                index: UTXO_INDEX,
                amount: TOKEN_NUM,
                omniAddress: sender
            }
        ],
        outputs: [
            {
                omniAddress: receiver,
                amount: TOKEN_NUM
            }
        ],
        feeInputs: [
            {
                txid: TX_ID,
                index: UTXO_INDEX,
                amount: TOKEN_NUM,
                omniAddress: sender
            }
        ],
        feeOutputs: [
            {
                omniAddress: receiver,
                amount: TOKEN_NUM
            }
        ]
    };
}

describe('GetWallets', function () {


    describe('private to publick key', function () {
     
        it('test ', async function () {
            const privateKey = "0x0000000000000000000000000000000000000000000000000000000000000001"
            var pubKey = ecdsa.publicKeyCreate(
                Buffer.from(privateKey.substring(2), 'hex'),
                false
            );
            var pubKeyStr = '0x' + Buffer.from(pubKey).toString('hex').substring(2);
            //console.info(privateKey)
            console.info(Buffer.from(pubKey).toString('hex'))
            console.info(pubKeyStr)

            let accounts =  hre.config.networks.hardhat.accounts;
            const wallet = hre.ethers.HDNodeWallet.fromPhrase(
                accounts.mnemonic,
                accounts.password,
                `${accounts.path}/${0}`
            );
            console.info("------------")
            var pubKey1 = ecdsa.publicKeyCreate(
                Buffer.from(wallet.privateKey.substring(2), 'hex'),
                false
            );
            let publicKey = '0x' + Buffer.from(pubKey1).toString('hex').substring(2);
            let compressed = '0x' + wallet.publicKey.substring(4)
            console.info(publicKey)
            console.info(compressed)
            //console.info(wallet.publicKey)

        })
       
    });
    
});
