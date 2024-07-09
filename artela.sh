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
wget -O $HOME/.artelad/config/addrbook.json https://testnet-files.bonynode.online/artela/addrbook.json

# set minimum gas price
sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"20000000000uart\"|" $HOME/.artelad/config/app.toml

# set peers and seeds
SEEDS="59df4b3832446cd0f9c369da01f2aa5fe9647248@162.55.65.137:15956"
PEERS="0e8b16937784f5dc322502f3bec00251d7c1022c@84.247.165.21:26656,2a974b9ecf2dddc57cecbdda5cc38f9f9d4f554f@149.102.156.247:3456,878313193d0a6ea7cd691387fe07cfebe0dbb986@37.60.248.37:3456,aa0c9902fc25b88be6dfb0045599b3849413dab8@84.46.244.60:3456,cbbb7482ccca3740761a6de8c42d2cd936b390d7@167.235.115.119:38656,f75939e4f2b130c63f41171770459d85f950ca0a@[2a03:4000:6b:291:865:1bff:feb0:1876]:3456,30fb0055aced21472a01911353101bc4cd356bb3@47.89.230.117:36657,6ea3de0558632ca04d1fee9d232d13b477425070@49.51.253.203:3456,3348d92eb21c077c860420a37d798f8100e819fe@131.226.221.12:3456,3bee1b1296356c47fc4e3128073027808719098b@100.42.179.174:3456,b777cf123ef2453f06ff63930f1e0fd60aede949@161.97.115.111:26656,58009d85e6057334b08035c6912490aadbf7c7db@149.102.145.46:3456,d6034b52fe3c20764a7120c23e6a2eadc2caec2b@89.117.56.249:3456,50c695e5c41fc71cb24d09597e8264775caa6e7a@149.137.247.22:3456,daa8c658b9594887c27deeb3eee4a03444338f1b@38.242.209.16:45656,96da5bebb4249c57fd9c7c3c1f2df7d0cee5cfc0@217.15.162.235:3456,6fb1aa6a29475ebb4fe71270d124f2ffa2dd1bb4@162.19.234.110:36656,e6e145333f307f3cced5441a0d0886ba70f33605@35.221.221.228:3456,5cd1856a021b81428df2fc73dc19f62306f481a2@93.42.224.26:30656,141adab16a5439a744133277abec412e8b60d369@213.199.34.59:3456,04e275d1993781b2ed37b19fade1ed3db3ab7717@152.53.46.223:3456,09de87861c0d883be3fa8301936022f1285d7507@185.234.69.165:3456,a56fd9627d49a44e10e57e344682e1fdde563db3@49.12.56.162:26656,bd6564af6edf4693c0a0da976bc75559a83e48bd@173.249.19.35:25656,a84cd3e3d401f7b853135a4ca786057c7a0b913a@38.242.157.138:26656,9c3ad8697395459ace730b096141b9360f8aee37@161.97.142.145:3456,aa2e2400ead278c81b0a04b703eb51b604f4ddbe@185.255.131.50:3456,c4a372104340082d27a74f144c25d5ffc642d679@86.48.5.49:3456,578d00435d46eb148c06adaee8f7ef672d12bea8@5.180.149.249:3456,df1933b675e284d3de3696799c6dde7be32f2451@152.53.2.107:3456,df292c0b47c82e72b9720d14d51465bf2fdf3883@152.53.32.51:3456,8c4b1d64f94dfd9f9997bc4e66c37163c354c7b3@84.247.179.88:3456,c27f37d226decf0dacdde71bb417ef603f678e52@89.116.27.78:3456,ef5fd230eecccfa397e0edfbbbde3454bd858ada@38.58.182.41:3456,0cabe01a4dfcef4f3105a575a5bea58b0310d7d2@185.252.234.24:3456,14fb77ff72e10aea7f307933a45e241ac29d993b@84.247.163.6:3456,16408ed57fc59c99d8489934e95970fb28a8f3e1@5.189.186.227:25656,5c5bf1802c18151dc72573746ce81489850e69a5@195.201.193.242:26656,c4ad137b920899536d34f09eb37aaa314f739fe9@194.238.26.209:3456,3cbf1df47dbc1e2ff5e222dbe98ec8291b42d787@109.123.253.251:26656"
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
curl https://testnet-files.bonynode.online/artela/snap_artela.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.artelad

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
