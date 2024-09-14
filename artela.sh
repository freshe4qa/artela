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
PEERS="5c9b1bc492aad27a0197a6d3ea3ec9296504e6fd@artela-testnet-peer.itrocket.net:30656,e7b2f932bf4a58031ce09aab50b80353a4c3b6b4@78.46.46.87:3456,6039d6d5fd29338d5b0f9ccc0182b6ffbb64f618@164.68.111.133:26656,1b0cd81c4b06fd57f613c691dc93bae79b117a89@109.205.182.73:3456,64af6870f342899bfc475da28ce4bb16b0e62f23@161.97.151.149:3456,daf1bfabfd3e0514188659942d854d8d09712986@[2a01:4f8:171:d6e::2]:23456,a9ffffea32e0617f844b2ffbbf5b4548ee94fa44@80.65.211.230:3456,8660f9dd4cd2858b2b5d9a6b726d9d3203625bfc@217.76.48.228:3456,2d48fc88b3313502a1e78fa708ee35cd960bd291@173.249.26.237:30656,4f7b1f100d8f7c78da34ebc4c5978fcccbcebdc7@38.242.252.83:26656,b0120fbe6c7f7bc274472ac2c7176c4fe82582a5@178.18.240.218:3456,55f27297790beba8c0c2a72b412c111ac6dedde1@173.249.29.163:25656,14fbdc03002e348f469dff986c6ca89da3d399c0@38.242.219.113:26656,70ec94e9dd3437f32d78f9f17e0f87278bbaf807@93.189.30.123:26656,8889b28795e8be109a532464e5cc074e113de780@47.251.54.123:26656,830d3e3272bb4a9853ebada3cf2bba27fdcd3ece@47.245.26.161:26656,f809f4fd17a9cf434b059af3e86262bbac3cb809@47.251.32.165:26656,4d108a6199f393ec6018257db306caf9deeda268@95.216.228.91:3456,0172eec239bb213164472ea5cbd96bf07f27d9f2@47.251.14.47:26656"
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
curl https://server-4.itrocket.net/testnet/artela/artela_2024-09-14_13046951_snap.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.artelad

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
