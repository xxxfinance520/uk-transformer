# uk-transformer
## 需求
用户消耗USDT以固定价格升级为Omniverse上的KARANA资产。有如下规则，
1. 通过合约升级KARANA价格不可更改
2. 升级为KARANA后不可通过合约降级为USDT
3. KARANA/USDT价格精度低于0.000000001
## 问题
1. LocalEntry在相同的链只有一个合约地址，需要localEntry的地址？
2. 需要Local网络的rpc和gas费用
3. 还需要一个服务器
## test
```bash
forge test -vvv
```
## rpc地址和合约信息
-  rpcd地址 $rpc
- KARANA: 0x0000000000000000000000000000000000000000000000000000000000000000
- LocalEntry: 0x6840E8fC9C1e0dDad460cD908DB471be34972bb7
- poseidon: 0x1640C65b24180b43F5493c9c3C3caCC1870CD726
- config: 0x46B4F41700b5e864Da26489c2bD3ec5b8244c5bb
- eip712: 0x95bc8AAEa8f70390BacA24EB634975bB24547716,0xd03A47C67F69880eA27Fd48da4600b2e35D349aC
-  usdt token: 0x701224564cB13Cb55AB4bfd64a0bBc4b7F756a51
- aa: 0x8e0aDE478d772ed00C88E6a42e6EC4e1414AEbaC,0x4b76D491FF0DeA9a30aC1A5f1cA59b0FD59A3e5F

##  部署命令
设置部署用到的账户
```bash
    export act=dep
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
cast call 0x701224564cB13Cb55AB4bfd64a0bBc4b7F756a51 "balanceOf(address)(uint256)"  0xF5Be48f1258aa6164a54dF21FFF5Fe42eEb76fDB --rpc-url $rpc 
```
授权
```bash
cast send 0x701224564cB13Cb55AB4bfd64a0bBc4b7F756a51 "approve(address,uint256)(bool)"  0x4b76D491FF0DeA9a30aC1A5f1cA59b0FD59A3e5F 1000000 --rpc-url $rpc  --account eth1
```
铸造代币
```bash
cast send 0x701224564cB13Cb55AB4bfd64a0bBc4b7F756a51 "mint(address,uint256)" 0xF5Be48f1258aa6164a54dF21FFF5Fe42eEb76fDB 10000000000 --rpc-url $rpc --account eth1
```
查看交易
```bash
cast tx 0x20592b0be616c0e4f46e25d25a5109479a2086baebb6ba4bf0ee0c701af183cc --rpc-url $rpc 
```
本地转om
```bash
cast send 0x4b76D491FF0DeA9a30aC1A5f1cA59b0FD59A3e5F "convertToOmniverse(bytes32,uint128)" 0xd25d3f4f5c5875baa8448e2f46f3dc698fe72a9352598a16dd7b48f561624b77 1000000 --rpc-url $rpc --account eth1
```

aa合约注册
```bash
forge script script/AAScript.s.sol:AAScript  --rpc-url $rpc --broadcast -vvvv
```