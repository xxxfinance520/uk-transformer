# uk-transformer
## 需求
用户消耗USDT以固定价格升级为Omniverse上的KARANA资产。有如下规则，
1. 通过合约升级KARANA价格不可更改
2. 升级为KARANA后不可通过合约降级为USDT
3. KARANA/USDT价格精度低于0.000000001
## 问题
1. 如何给aa合约增加Omniverse token
2. 前端如何从metamask获取公钥
3. 部署aa合约传入的utxo资产何时会同步到 Omniverse 
4. 部署aa合约后，有如下操作：
    1. aa合约注册到LocalEntry
    2. aa合约注册到Beacon
    3. 调用aa合约方法convertToOmniverse构建omni-tx
    4. ts程序链下签名后调用submitTx
       
我从前端看Omniverse没有变化，这是什么原因
## test
```bash
forge test -vvv
```
## rpc地址和合约信息
-  rpcd地址 http://3.236.195.117:8998/
-  前端地址：http://47.251.55.43
- KARANA: 0x0000000000000000000000000000000000000000000000000000000000000000
- gasfeeReceiver: 0x7947cf497935a5f3be881187710fbe139be9d80aa63df4f59c93ca320465e4bd
- stateKepper: 0x47C84c0B3c2452B6C22B9c07cac500fBA97f7Fa3
- LocalEntry: 0x6840E8fC9C1e0dDad460cD908DB471be34972bb7
- eip712: 0x8a2Ac632A9FE20DD193C87E3d899190C817f93D1
- poseidon: 0xEFF03fAD6e237193c0af5c5Fc8A9c8ddCE624327
- config(self): 0x16113DfDF7b4F26e94786AdA9e5FFca8A42b33C6
- config: 0x9BEBB619B7aab059410f433154B92b3EC6C47C08
- usdt : 0x701224564cB13Cb55AB4bfd64a0bBc4b7F756a51
- Beacon: 0x47C84c0B3c2452B6C22B9c07cac500fBA97f7Fa3
- aa: 0x444B38466F9cd98D5936a59E36cA95851EbAB409
- ktoken: 0x0FAcC6881432D648e5BaBd1Cb42B3BBc5EbF6b91

## 获取代币
http://3.236.195.117:7788/get_token/?address=oxcaccad836b58aa051db850917d6f423234b7dc63b01e5190c950a029ae5323fd

##  部署命令
设置部署用到的账户
```bash
    export act=om2
    export rpc=http://3.236.195.117:8998/
```
部署token
```bash
    forge create --rpc-url $rpc --account $act contracts/tests/Token.sol:Token
```
部署Poseidon
```bash
    forge create --rpc-url $rpc --account $act contracts/lib/omniverse-aa/lib/Poseidon.sol:Poseidon
```
部署OmniverseEIP712
```bash
    forge create --rpc-url $rpc  \
--constructor-args "Omniverse Transaction" "1" 1337 "0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC" \
--account $act contracts/lib/omniverse-aa/lib/OmniverseEIP712.sol:OmniverseEIP712
```
部署OmniverseSysConfigAA
```bash
export GAS_ASSET_ID=0x0000000000000000000000000000000000000000000000000000000000000000
export GAS_RECEIVER=0x7947cf497935a5f3be881187710fbe139be9d80aa63df4f59c93ca320465e4bd
export GAS_FEE=1
export UTXO_NUM=20
export DECIMALS=12
export TOKEN_NAME_LIMIT=24
export STATE_KEEPER=0x0000000000000000000000000000000000000000
export LOCAL_ENTRY=0x6840E8fC9C1e0dDad460cD908DB471be34972bb7
forge create --rpc-url $rpc \
--constructor-args $GAS_ASSET_ID $GAS_RECEIVER $GAS_FEE $UTXO_NUM $DECIMALS $TOKEN_NAME_LIMIT $STATE_KEEPER $LOCAL_ENTRY \
--account $act contracts/lib/omniverse-aa/OmniverseSysConfig.sol:OmniverseSysConfigAA
```
部署AA合约
```bash
   forge script script/DeployAA.s.sol:DeployAA  --rpc-url $rpc --broadcast
```
## forge  测试命令
查询代币总数
```bash
cast call 0x701224564cB13Cb55AB4bfd64a0bBc4b7F756a51 "totalSupply()(uint256)" --rpc-url $rpc 
```
查询余额
```bash
cast call 0x701224564cB13Cb55AB4bfd64a0bBc4b7F756a51 "balanceOf(address)(uint256)"  0xb1E26F3E7BD8ac1d01bA03b0AB7c1a3B9BF0d6E6 --rpc-url $rpc 
```
查看aa pub
```bash
cast call 0x47C84c0B3c2452B6C22B9c07cac500fBA97f7Fa3 "getPubkey()(bytes32)" --rpc-url $rpc 
```

授权
```bash
cast send 0x701224564cB13Cb55AB4bfd64a0bBc4b7F756a51 "approve(address,uint256)(bool)"  0x444B38466F9cd98D5936a59E36cA95851EbAB409 1000000 --rpc-url $rpc  --account $act
```
铸造代币
```bash
cast send 0x0FAcC6881432D648e5BaBd1Cb42B3BBc5EbF6b91 "mint(address,uint256)" 0xb1E26F3E7BD8ac1d01bA03b0AB7c1a3B9BF0d6E6 1000000 --rpc-url $rpc --account $act
```
查看交易
```bash
cast tx 0x20592b0be616c0e4f46e25d25a5109479a2086baebb6ba4bf0ee0c701af183cc --rpc-url $rpc 
```
本地转om
```bash
cast send 0x444B38466F9cd98D5936a59E36cA95851EbAB409 "convertToOmniverse(bytes32,uint128)" 0xd25d3f4f5c5875baa8448e2f46f3dc698fe72a9352598a16dd7b48f561624b77 1000000000000 --rpc-url $rpc --account $act
```

aa合约注册
```bash
forge script script/AARegsiterScript.s.sol:AARegsiterScript  --rpc-url $rpc --broadcast -vvvv
```
aa合约注册到Beacon
```bash
forge script script/BeaconRegisterScript.s.sol:BeaconRegisterScript  --rpc-url $rpc --broadcast -vvvv
```

abi
```bash
jq '.abi' ./out/OmniverseUKTransformerBeacon.sol/OmniverseUKTransformerBeacon.json
```
