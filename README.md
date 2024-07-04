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
