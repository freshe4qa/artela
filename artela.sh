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
apt install curl iptables build-essential git wget jq make gcc nano tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev -y

# install go
sudo rm -rf /usr/local/go
curl -L https://go.dev/dl/go1.21.6.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile
source .bash_profile

# download binary
cd $HOME && rm -rf artela
git clone https://github.com/artela-network/artela
cd artela
git checkout v0.4.7-rc7-fix-execution
make install

#update lib
cd $HOME
wget https://github.com/artela-network/artela/releases/download/v0.4.7-rc7-fix-execution/artelad_0.4.7_rc7_fix_execution_Linux_amd64.tar.gz
tar -xvf artelad_0.4.7_rc7_fix_execution_Linux_amd64.tar.gz
mkdir libs
mv $HOME/libaspect_wasm_instrument.so $HOME/libs/
mv $HOME/artelad /usr/local/bin/
echo 'export LD_LIBRARY_PATH=$HOME/libs:$LD_LIBRARY_PATH' >> ~/.bashrc
source ~/.bashrc

# config
artelad config chain-id $ARTELA_CHAIN_ID
artelad config keyring-backend test

# init
artelad init $NODENAME --chain-id $ARTELA_CHAIN_ID

# download genesis and addrbook
wget -qO $HOME/.artelad/config/genesis.json https://public-snapshot-storage-develop.s3.ap-southeast-1.amazonaws.com/artela/artela_11822-1/genesis.json
curl -L https://snapshots-testnet.nodejumper.io/artela-testnet/addrbook.json > $HOME/.artelad/config/addrbook.json

# set minimum gas price
sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"20000000000uart\"|" $HOME/.artelad/config/app.toml

# set peers and seeds
SEEDS="59df4b3832446cd0f9c369da01f2aa5fe9647248@162.55.65.137:15956"
PEERS="fee30216aa088a90fba8d82347a735ca959cd646@173.212.223.120:25656,fb582d9c8b56229142e0b1f25344b9701263aea7@185.215.165.45:3456,60b3963b03cbae7aa038d06726fd3946247d3507@217.15.162.238:3456,46925bebc56e38dd70230f82a6dbf87fa7fc6bcd@154.217.39.9:3456,c2d1aef4d9b2a8609a5f761771235f7c02280462@38.58.179.252:3456,6d1bc3d051c2e8eb2fe7df284cd505ab97eefcfe@75.119.131.252:3456,1f09c918f39240cf204996cd1239eccdbb22a779@45.136.17.26:3456,8d1b38c031f19bca255ed588a4885c99520090f7@161.97.169.2:3456,da1b93e7bbf6f4bfa35486894ae0c3f035b42f28@35.201.233.155:3456,41173f24734c1ec3876fcc9cffb8945299b7baf5@34.88.212.97:3456"
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
curl https://snapshots-testnet.nodejumper.io/artela-testnet/artela-testnet_latest.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.artelad

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
