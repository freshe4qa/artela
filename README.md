<p align="center">
  <img height="100" height="auto" src="https://github.com/freshe4qa/artela/assets/85982863/5b2551b8-3d4c-45f5-96cc-d38c9ccb0547">
</p>

# Artela Testnet — artela_11822-1

Official documentation:
>- [Validator setup instructions](https://docs.artela.network/develop/node/run-full-node)

Explorer:
>- [https://betanet-scan.artela.network](https://betanet-scan.artela.network)

### Minimum Hardware Requirements
 - 4x CPUs; the faster clock speed the better
 - 8GB RAM
 - 100GB of storage (SSD or NVME)

### Recommended Hardware Requirements 
 - 8x CPUs; the faster clock speed the better
 - 16GB RAM
 - 1TB of storage (SSD or NVME)

## Set up your artela fullnode
```
wget https://raw.githubusercontent.com/freshe4qa/artela/main/artela.sh && chmod +x artela.sh && ./artela.sh
```

## Post installation

When installation is finished please load variables into system
```
source $HOME/.bash_profile
```

Synchronization status:
```
artelad status 2>&1 | jq .SyncInfo
```

### Create wallet
To create new wallet you can use command below. Don’t forget to save the mnemonic
```
artelad keys add $WALLET
```

Recover your wallet using seed phrase
```
artelad keys add $WALLET --recover
```

To get current list of wallets
```
artelad keys list
```

## Usefull commands
### Service management
Check logs
```
journalctl -fu artelad -o cat
```

Start service
```
sudo systemctl start artelad
```

Stop service
```
sudo systemctl stop artelad
```

Restart service
```
sudo systemctl restart artelad
```

### Node info
Synchronization info
```
artelad status 2>&1 | jq .SyncInfo
```

Validator info
```
artelad status 2>&1 | jq .ValidatorInfo
```

Node info
```
artelad status 2>&1 | jq .NodeInfo
```

Show node id
```
artelad tendermint show-node-id
```

### Wallet operations
List of wallets
```
artelad keys list
```

Recover wallet
```
artelad keys add $WALLET --recover
```

Delete wallet
```
artelad keys delete $WALLET
```

Get wallet balance
```
artelad query bank balances $ARTELA_WALLET_ADDRESS
```

Transfer funds
```
artelad tx bank send $ARTELA_WALLET_ADDRESS <TO_ARTELA_WALLET_ADDRESS> 10000000uart
```

### Voting
```
artelad tx gov vote 1 yes --from $WALLET --chain-id=$ARTELA_CHAIN_ID
```

### Staking, Delegation and Rewards
Delegate stake
```
artelad tx staking delegate $ARTELA_VALOPER_ADDRESS 10000000uart --from=$WALLET --chain-id=$ARTELA_CHAIN_ID --gas=auto
```

Redelegate stake from validator to another validator
```
artelad tx staking redelegate <srcValidatorAddress> <destValidatorAddress> 10000000uart --from=$WALLET --chain-id=$ARTELA_CHAIN_ID --gas=auto
```

Withdraw all rewards
```
artelad tx distribution withdraw-all-rewards --from=$WALLET --chain-id=$ARTELA_CHAIN_ID --gas=auto
```

Withdraw rewards with commision
```
artelad tx distribution withdraw-rewards $ARTELA_VALOPER_ADDRESS --from=$WALLET --commission --chain-id=$ARTELA_CHAIN_ID
```

Unjail validator
```
artelad tx slashing unjail \
  --broadcast-mode=block \
  --from=$WALLET \
  --chain-id=$ARTELA_CHAIN_ID \
  --gas=auto
```
