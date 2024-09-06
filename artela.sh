#!/bin/bash

while true
do

# Logo

echo -e '\e[40m\e[91m'
echo -e '  ____                  _                    '
echo -e ' / ___|_ __ _   _ _ __ | |_ ___  _ __        '
echo -e '| |   |  __| | | |  _ \| __/ _ \|  _ \       '
echo -e '| |___| |  | |_| | |_) | || (_) | | | |      '
echo -e ' \____|_|   \__  |  __/ \__\___/|_| |_|      '
echo -e '            |___/|_|                         '
echo -e '\e[0m'

sleep 2

# Menu

PS3='Select an action: '
options=(
"Install"
"Create Wallet"
"Create Validator"
"Exit")
select opt in "${options[@]}"
do
case $opt in

"Install")
echo "============================================================"
echo "Install start"
echo "============================================================"

# set vars
if [ ! $NODENAME ]; then
	read -p "Enter node name: " NODENAME
	echo 'export NODENAME='$NODENAME >> $HOME/.bash_profile
fi
if [ ! $WALLET ]; then
	echo "export WALLET=wallet" >> $HOME/.bash_profile
fi
echo "export ARTELA_CHAIN_ID=artela_11822-1" >> $HOME/.bash_profile
source $HOME/.bash_profile

# update
sudo apt update && sudo apt upgrade -y

# packages
apt install curl iptables build-essential git wget jq make gcc nano tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev lz4 -y

# install go
sudo rm -rf /usr/local/go
curl -L https://go.dev/dl/go1.21.6.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile
source .bash_profile

# download binary
cd $HOME && rm -rf artela
git clone https://github.com/artela-network/artela
cd artela
git checkout v0.4.9-rc9
make install

#update lib
cd $HOME
wget https://github.com/artela-network/artela/releases/download/v0.4.7-rc7-fix-execution/artelad_0.4.7_rc7_fix_execution_Linux_amd64.tar.gz
tar -xvf artelad_0.4.7_rc7_fix_execution_Linux_amd64.tar.gz
sudo mv $HOME/libaspect_wasm_instrument.so /usr/lib/

# config
artelad config chain-id $ARTELA_CHAIN_ID
artelad config keyring-backend test

# init
artelad init $NODENAME --chain-id $ARTELA_CHAIN_ID

# download genesis and addrbook
wget -qO $HOME/.artelad/config/genesis.json https://public-snapshot-storage-develop.s3.ap-southeast-1.amazonaws.com/artela/artela_11822-1/genesis.json
wget -O $HOME/.artelad/config/addrbook.json https://testnet-files.bonynode.online/artela/addrbook.json

# set minimum gas price
sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"20000000000uart\"|" $HOME/.artelad/config/app.toml

# set peers and seeds
SEEDS=""
PEERS="5c9b1bc492aad27a0197a6d3ea3ec9296504e6fd@artela-testnet-peer.itrocket.net:30656,6fb1aa6a29475ebb4fe71270d124f2ffa2dd1bb4@162.19.234.110:36656,0c33c69cf6099d5f44a840dff08c02ee032191f1@94.16.31.30:3456,22533e3edfbeabec006591c3afae06fd970a3556@35.229.139.209:3456,7cc9992cdfb96a103f7ee9c34dd76076a0af98ff@80.190.82.45:3456,33a4eec53ff692a13d99901a296ba612f3586ac0@37.27.134.16:26656,fe55bcd1ee5c1425c1a8253e4bf745f9eab52cef@149.102.152.191:60656,8e1b7477ca2da4d246cab0cfd301dc1d17352215@65.109.62.39:11656,a94e93f8c072394f408180811ec2f76988da7a41@35.236.189.94:3456,da1b93e7bbf6f4bfa35486894ae0c3f035b42f28@35.201.233.155:3456,14fb77ff72e10aea7f307933a45e241ac29d993b@84.247.163.6:3456,d6034b52fe3c20764a7120c23e6a2eadc2caec2b@89.117.56.249:3456,811e56e1de32996f8ba83197065ea84b7b9a0a74@35.194.247.216:3456,23e30171028f5336cb1dc2b9d31dec0805ba7ea6@94.72.113.222:26656,3e1e63b2c93b722f37a7f3603b2d4563efbd3442@152.53.45.87:3456,0cabe01a4dfcef4f3105a575a5bea58b0310d7d2@185.252.234.24:3456,c4a372104340082d27a74f144c25d5ffc642d679@86.48.5.49:3456,e5427c90cdd49a2fa28677bdb345b586f0bcb77d@159.203.63.54:3456,5b77a3513fe0c64d71481465ea18584ee87492e4@173.212.220.218:25656,c4ad137b920899536d34f09eb37aaa314f739fe9@194.238.26.209:3456,d1d43cc7c7aef715957289fd96a114ecaa7ba756@65.21.198.100:23410"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.artelad/config/config.toml

# disable indexing
indexer="null"
sed -i -e "s/^indexer *=.*/indexer = \"$indexer\"/" $HOME/.artelad/config/config.toml

# config pruning
pruning="custom"
pruning_keep_recent="100"
pruning_keep_every="0"
pruning_interval="10"
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.artelad/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.artelad/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.artelad/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.artelad/config/app.toml
sed -i "s/snapshot-interval *=.*/snapshot-interval = 0/g" $HOME/.artelad/config/app.toml

#update
sed -i -e "s/iavl-disable-fastnode = false/iavl-disable-fastnode = true/" $HOME/.artelad/config/app.toml

# enable prometheus
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.artelad/config/config.toml

# create service
sudo tee /etc/systemd/system/artelad.service > /dev/null << EOF
[Unit]
Description=Artela node service
After=network-online.target
[Service]
User=$USER
ExecStart=$(which artelad) start
Environment="LD_LIBRARY_PATH=/root/libs"
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

# reset
artelad tendermint unsafe-reset-all --home $HOME/.artelad --keep-addr-book
curl https://testnet-files.itrocket.net/artela/snap_artela.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.artelad

# start service
sudo systemctl daemon-reload
sudo systemctl enable artelad
sudo systemctl restart artelad

break
;;

"Create Wallet")
artelad keys add $WALLET
echo "============================================================"
echo "Save address and mnemonic"
echo "============================================================"
ARTELA_WALLET_ADDRESS=$(artelad keys show $WALLET -a)
ARTELA_VALOPER_ADDRESS=$(artelad keys show $WALLET --bech val -a)
echo 'export ARTELA_WALLET_ADDRESS='${ARTELA_WALLET_ADDRESS} >> $HOME/.bash_profile
echo 'export ARTELA_VALOPER_ADDRESS='${ARTELA_VALOPER_ADDRESS} >> $HOME/.bash_profile
source $HOME/.bash_profile

break
;;

"Create Validator")
artelad tx staking create-validator \
--amount=1000000uart \
--pubkey=$(artelad tendermint show-validator) \
--moniker=$NODENAME \
--chain-id=artela_11822-1 \
--commission-rate=0.10 \
--commission-max-rate=0.20 \
--commission-max-change-rate=0.01 \
--min-self-delegation=1 \
--from=wallet \
--gas-prices=20000000000uart \
--gas-adjustment=1.5 \
--gas=auto \
-y 
  
break
;;

"Exit")
exit
;;
*) echo "invalid option $REPLY";;
esac
done
done
