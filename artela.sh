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
curl -L https://go.dev/dl/go1.22.7.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.profile
source .profile

# download binary
cd $HOME && rm -rf artela
git clone https://github.com/artela-network/artela
cd artela
git checkout v0.4.9-rc9
make install

#update lib
#cd $HOME
#wget https://github.com/artela-network/artela/releases/download/v0.4.7-rc7-fix-execution/artelad_0.4.7_rc7_fix_execution_Linux_amd64.tar.gz
#tar -xvf artelad_0.4.7_rc7_fix_execution_Linux_amd64.tar.gz
#sudo mv $HOME/libaspect_wasm_instrument.so /usr/lib/

# config
artelad config chain-id $ARTELA_CHAIN_ID
artelad config keyring-backend test

# init
artelad init $NODENAME --chain-id $ARTELA_CHAIN_ID

# download genesis and addrbook
curl -L https://snapshots-testnet.nodejumper.io/artela/genesis.json > $HOME/.artelad/config/genesis.json
curl -L https://snapshots-testnet.nodejumper.io/artela/addrbook.json > $HOME/.artelad/config/addrbook.json

# set minimum gas price
sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"20000000000uart\"|" $HOME/.artelad/config/app.toml

# set peers and seeds
SEEDS=""
PEERS="ff2bfe932a9d4955d5c2c43078a5508a0756e1cd@84.247.168.131:26656,e7cf4a28f99db3899d4b02449e23c9a3e8785dea@213.199.55.29:26656,ea447a8c49aab91971e7a37c7ba56e857048eaa2@77.237.244.71:17656,66bea3849ac05acf61819a2af2c6f4a4f9154625@149.102.137.104:26656,e0c08d7623b2a0dc5d37e01e201055c00fff6b9d@5.189.162.179:45656,21dfb6e516d0977ee89227fc8a626cd8bc5809a9@213.199.45.37:26656,fd08a3be023d7446e3e9aae55e9d6b71e2ce32e2@109.199.124.154:3456,82b42033928b64eaf2229d680d911b7425febdbc@38.242.235.123:26656,ed81be22a54fa50f3598202ddc89050899c61f8d@45.136.17.34:3456,936e6c67633a4bfae82c4f0125824278f827560b@152.53.34.214:3456,64af6870f342899bfc475da28ce4bb16b0e62f23@161.97.151.149:3456,1f09c918f39240cf204996cd1239eccdbb22a779@45.136.17.26:3456,ba19ee8c73b1edbaa54f9114cde15fc2cc37a08e@92.118.58.126:3456,0d6f5be0f227a9dda3c98a1415610caa9e592860@213.199.38.215:45656,0f5a4ad942c2bb222362e7cb92f11f0f474a0f6d@45.136.17.29:3456,b081d81ca2ca19b33f14477694a8a0d4cd444c66@158.51.99.57:26656,3d116e281c93bc73cd35b9036a64c7b3c7a6b1e4@84.46.240.232:3456,9f10c006519ead8942ddbdbcbb5d5f03c2fdf35d@217.76.54.115:26656,0ca7efaf9774d455895a7c845db418435f9272da@195.7.6.216:3456,e28052c540835386e657e9932b46380640014693@213.199.50.196:3456"
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
#sed -i -e "s/iavl-disable-fastnode = false/iavl-disable-fastnode = true/" $HOME/.artelad/config/app.toml

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
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

# reset
artelad tendermint unsafe-reset-all --home $HOME/.artelad --keep-addr-book
curl https://snapshots-testnet.nodejumper.io/artela/artela_latest.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.artelad

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
