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

describe('Omniverse Transformer', function () {
    // We define a fixture to reuse the same setup in every test.
    // We use loadFixture to run this setup once, snapshot that state,
    // and reset Hardhat Network to that snapshot in every test.
    async function deployOmniverseTransformer() {
        // Contracts are deployed using the first signer/account by default
        const wallets = getWallets();
        const signers = await hre.ethers.getSigners();

        // EIP712
        const OmniverseEIP712 =
            await hre.ethers.getContractFactory('OmniverseEIP712');
        const eip712 = await OmniverseEIP712.deploy(
            DOMAIN.name,
            DOMAIN.version,
            DOMAIN.chainId,
            DOMAIN.verifyingContract
        );

        // Poseidon
        const Poseidon = await hre.ethers.getContractFactory('Poseidon');
        const poseidon = await Poseidon.deploy();

        // ERC20 token
        const Token = await hre.ethers.getContractFactory('Token');
        const token = await Token.deploy();

        // Omniverse transformer
        const OmniverseTransformerBeacon = await hre.ethers.getContractFactory(
            'OmniverseTransformerBeaconTest'
        );
        const gasUTXOs = generateUTXOs(GAS_ASSET_ID, wallets[0].compressed);
        const tokenUTXOs = generateUTXOs(TOKEN_ASSET_ID, wallets[0].compressed);
        const omniverseTransformer = await OmniverseTransformerBeacon.deploy(
            TOKEN_ASSET_ID,
            token.target,
            wallets[0].publicKey,
            gasUTXOs.concat(tokenUTXOs),
            poseidon.target,
            eip712.target
        );

        // State keeper
        const MockStateKeeper = await hre.ethers.getContractFactory(
            'MockStateKeeperBeacon'
        );
        const stateKeeper = await MockStateKeeper.deploy();

        // Local entry
        const MockLocalEntry =
            await hre.ethers.getContractFactory('MockLocalEntry');
        const localEntry = await MockLocalEntry.deploy();

        await omniverseTransformer.setLocalEntry(localEntry.target);
        await omniverseTransformer.setStateKeeper(stateKeeper.target);

        return {
            stateKeeper,
            localEntry,
            eip712,
            poseidon,
            omniverseTransformer,
            token,
            transformer: { signer: signers[0], wallet: wallets[0] },
            user: { signer: signers[1], wallet: wallets[1] }
        };
    }

    async function deployOmniverseTransformerWithConvertingToLocalTxSubmitted() {
        const {
            omniverseTransformer,
            token,
            transformer,
            stateKeeper,
            user
        } = await deployOmniverseTransformer();

        await stateKeeper.setIsIncluded(true);

            let transfer: utils.Transfer = getTransferTx(
                user.wallet.compressed,
                transformer.wallet.compressed
            );
            const signature = await utils.typedSignTransfer(
                user.signer,
                transfer
            );
            transfer.signature = signature;

        return {
            omniverseTransformer,
            token,
            transformer,
            stateKeeper,
            user
        }
    }

    describe('Deployment', function () {
        it('Should set the right parameters', async function () {
            const { omniverseTransformer, token } = await loadFixture(
                deployOmniverseTransformer
            );

            expect(await omniverseTransformer.getAssetId()).to.equal(
                TOKEN_ASSET_ID
            );
            expect(await omniverseTransformer.getLocalTokenAddress()).to.equal(
                token.target
            );
        });
    });

    describe('Convert to Omniverse', function () {
        it('Should revert with not enough tokens approved', async function () {
            const { omniverseTransformer, token, transformer, user } =
                await loadFixture(deployOmniverseTransformer);
            const kprice = hre.ethers.toBigInt(await omniverseTransformer.getKprice())
            const PRICE_DECIMAL_NUM = hre.ethers.toBigInt(1e8)
            const uAmount = kprice * hre.ethers.toBigInt(TOKEN_NUM)/PRICE_DECIMAL_NUM

            await expect(
                omniverseTransformer
                    .connect(user.signer)
                    .convertToOmniverse(user.wallet.compressed, TOKEN_NUM)
            )
                .to.be.revertedWithCustomError(
                    token,
                    'ERC20InsufficientAllowance'
                )
                .withArgs(
                    omniverseTransformer.target,
                    await token.allowance(
                        transformer.signer.address,
                        omniverseTransformer.target
                    ),
                    uAmount
                );
        });

        it('Should revert with sender does not have enough token to convert', async function () {
            const { omniverseTransformer, token, transformer, user } =
                await loadFixture(deployOmniverseTransformer);
                const kprice = hre.ethers.toBigInt(await omniverseTransformer.getKprice())
                const PRICE_DECIMAL_NUM = hre.ethers.toBigInt(1e8)
                const uAmount = kprice * hre.ethers.toBigInt(TOKEN_NUM)/PRICE_DECIMAL_NUM
            console.info("uAmount",uAmount)
          
            await token
                .connect(user.signer)
                .approve(omniverseTransformer.target, uAmount);
            await expect(
                omniverseTransformer
                    .connect(user.signer)
                    .convertToOmniverse(user.wallet.compressed, TOKEN_NUM)
            )
                .to.be.revertedWithCustomError(
                    token,
                    'ERC20InsufficientBalance'
                )
                .withArgs(
                    user.signer.address,
                    await token.balanceOf(user.signer.address),
                    uAmount
                );
        });

        it('Should pass if the sender has enough tokens, approves enough tokens, and the transformer has enough UTXOs to transfer', async function () {
            
            const { omniverseTransformer, token, user } = await loadFixture(
                deployOmniverseTransformer
            );
            const kprice = hre.ethers.toBigInt(await omniverseTransformer.getKprice())
            const PRICE_DECIMAL_NUM = hre.ethers.toBigInt(1e8)
            const uAmount = kprice * hre.ethers.toBigInt(TOKEN_NUM)/PRICE_DECIMAL_NUM
            await token.mint(user.signer.address, uAmount);
            await token
                .connect(user.signer)
                .approve(omniverseTransformer.target, uAmount);
            await expect(omniverseTransformer
                .connect(user.signer)
                .convertToOmniverse(user.wallet.compressed, TOKEN_NUM)).to.emit(omniverseTransformer, "LocalToOmniverse");;
            const tx = await omniverseTransformer.getUnsignedTx();
            expect(tx.txIndex).to.equal('0');
            expect(tx.unsignedTx.txid).not.to.equal(
                '0x0000000000000000000000000000000000000000000000000000000000000000'
            );
            expect(await omniverseTransformer.getLocalToOmniverseTxNumber(user.signer.address)).to.equal(1);
            expect((await omniverseTransformer.getLocalToOmniverseRecords(user.signer.address, 0)).length).to.equal(1);
            expect((await omniverseTransformer.getLocalToOmniverseRecords(user.signer.address, 1)).length).to.equal(1);
            expect((await omniverseTransformer.getLocalToOmniverseRecords(user.signer.address, 10)).length).to.equal(1);
        });
    });
    
});
