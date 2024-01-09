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
if ! [ -x "$(command -v go)" ]; then
ver="1.20.3" && \
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz" && \
sudo rm -rf /usr/local/go && \
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz" && \
rm "go$ver.linux-amd64.tar.gz" && \
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile && \
source $HOME/.bash_profile && \
go version
fi

# download binary
cd $HOME && rm -rf artela
git clone https://github.com/artela-network/artela
cd artela
git checkout v0.4.7-rc4
make install

# config
artelad config chain-id $ARTELA_CHAIN_ID
artelad config keyring-backend test

# init
artelad init $NODENAME --chain-id $ARTELA_CHAIN_ID

# download genesis and addrbook
wget -qO $HOME/.artelad/config/genesis.json https://docs.artela.network/assets/files/genesis-314f4b0294712c1bc6c3f4213fa76465.json
wget -qO $HOME/.artelad/config/addrbook.json https://snapshots.theamsolutions.info/artela-addrbook.json

# set minimum gas price
sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0.02uart\"|" $HOME/.artelad/config/app.toml

# set peers and seeds
SEEDS=""
PEERS="b23bc610c374fd071c20ce4a2349bf91b8fbd7db@65.108.72.233:11656,30fb0055aced21472a01911353101bc4cd356bb3@47.89.230.117:26656,9e2fbfc4b32a1b013e53f3fc9b45638f4cddee36@47.254.66.177:26656,978dee673bd447147f61aa5a1bdaabdfb8f8b853@47.88.57.107:26656,aa416d3628dcce6e87d4b92d1867c8eca36a70a7@47.254.93.86:26656"
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

# enable prometheus
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.artelad/config/config.toml

# create service
sudo tee /etc/systemd/system/artelad.service > /dev/null << EOF
[Unit]
Description=Artela Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which nibid) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

# reset
artelad tendermint unsafe-reset-all --home $HOME/.artelad --keep-addr-book 


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
--moniker="$NODENAME" \
--chain-id=artela_11822-1 \
--commission-rate=0.1 \
--commission-max-rate=0.2 \
--commission-max-change-rate=0.05 \
--min-self-delegation=1 \
--from=wallet \
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
