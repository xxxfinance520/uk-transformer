// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./lib/omniverse-aa/lib/Types.sol";
import "./lib/omniverse-aa/OmniverseAABeacon.sol";
import "./lib/omniverse-aa/lib/Utils.sol";
import "./interfaces/IOmniverseUKTransformerBeacon.sol";
import "./EnumerableTxRecord.sol";

uint256 constant PAGE_NUM = 10;

contract OmniverseUKTransformerBeacon is Ownable,OmniverseAABeacon, IOmniverseUKTransformerBeacon {
    using EnumerableTxRecord for EnumerableTxRecord.Bytes32ToOmniToLocalRecord;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    // price of k
    uint128 private kPrice = 1000;
    // the denominator of price
    uint128 private denominatorOfPrice = 1e10;
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

    constructor(address _sysConfig, bytes memory _AASignerPubkey,
        bytes32 _assetId, address _localToken, Types.UTXO[] memory _utxos, address _poseidon, address _eip712)
       Ownable(msg.sender) OmniverseAABeacon(_sysConfig, _AASignerPubkey, _utxos, _poseidon, _eip712) {
            omniAssetId = _assetId;
            localTokenAddress = _localToken;
    }
    
    /**
     * @notice See {IOmniverseUKTransformerBeacon - getKprice}
     * Returns the price of kToken 
     * @return kprice price of kToken 
     */
    function getKprice() public view returns( uint128) {
        return kPrice;
    }

     /**
     * @notice See {IOmniverseUKTransformerBeacon - setKprice}
     * set the price of kToken 
     * @param _kPrice new price of kToken 
     */
    function setKprice(uint128 _kPrice)  external onlyOwner {
       kPrice  = _kPrice;
    }

    /**
     * @notice See {IOmniverseUKTransformerBeacon - getDenominatorOfPrice}
     * Returns the denominator of price
     * @return denominatorOfPrice 
     */
    function getDenominatorOfPrice() public view returns( uint128) {
        return denominatorOfPrice;
    }
    
    /**
     * @notice See {IOmniverseUKTransformerBeacon - setKprice}
     * Set the new denominator of price 
     * @param _denominatorOfPrice new denominator of price 
     */
    function setDenominatorOfPrice(uint128 _denominatorOfPrice) external onlyOwner  {
       denominatorOfPrice  = _denominatorOfPrice;
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
        uint128 uAmount =  amount * kPrice /denominatorOfPrice; 
        amount = uAmount * denominatorOfPrice / kPrice;
        if (amount == 0) {
            return ;
        }
        IERC20(localTokenAddress).transferFrom(msg.sender, address(this), uAmount);
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
