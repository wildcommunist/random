#!/bin/bash

red=$(tput setaf 1)
cyan=$(tput setaf 6)
green=$(tput setaf 2)
reset=$(tput sgr0)

golangdlpath="https://dl.google.com/go/"
golangver="go1.18.2.linux-amd64.tar.gz"

BRC=~/.bashrc
CORE_GIT="https://github.com/terra-money/core"
CORE_VER="v2.1.1"
CORE_VER_MAINNET="v2.1.1"
SERVICE_ADDRESS="/etc/systemd/system/terrad.service"

TESTNET="pisco-1"
MAINNET="phoenix-1"

# GAS Fees
MIN_GAS="0.15"
P2P_PORT="26656"

sudo apt update
sudo apt install jq wget git nano build-essential -y
wget "$golangdlpath$golangver" -P /tmp/ 


# Remove old go install
if [ -d "/usr/local/go" ]
then
        sudo rm -Rf /usr/local/go
fi

sudo tar -C /usr/local -xzf /tmp/$golangver
rm /tmp/$golangver

if test -f "$BRC"; then
        echo "$BRC exists."
        echo '' >> $BRC
        echo 'PATH=$PATH:/usr/local/go/bin' >> $BRC
        echo 'PATH=$PATH:$(go env GOPATH)/bin' >> $BRC
fi

export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:$(go env GOPATH)/bin

echo "${cyan}Installed $(go version) successfully${reset}"

read -p "Is this installation for TEST NET? (Y)es (N)o " -n 1 -r IS_TESTNET
echo

if [[ ! $IS_TESTNET =~ ^[Yy]$ ]]
then
        CHAIN_ID=$MAINNET
        read -p "${red}You have selected MAIN NET. Is this correct?${reset} (Y)es (N)o " -n 1 -r CONFIRM
        echo
        if [[ ! $CONFIRM =~ ^[Yy]$ ]]
        then
                echo "${red}Relaunch the installer again if you want to make some changes${reset}"
                exit
        fi
        CORE_VER=$CORE_VER_MAINNET
else
        CHAIN_ID=$TESTNET
fi

git clone $HOME/$CORE_GIT
cd $HOME/core
git checkout $CORE_VER
make install

echo "${cyan}Installed terrad $(terrad version)${reset}"

read -p "What is the moniker (name)? " read MONIKER
read -p  "Cool, moniker is ${cyan}$MONIKER${reset}, next chain id. What should it be ($CHAIN_ID)?: " -r input
CHAIN_ID="${input:-$CHAIN_ID}"
echo "Moniker: ${cyan}$MONIKER${reset}, chain id: ${cyan}$CHAIN_ID${reset}"
terrad init "$MONIKER" --chain-id "$CHAIN_ID"

# Check if service exists
HAVE_SERVICE="n"
if test ! -f "$SERVICE_ADDRESS"; then
        read -p "Install terrad service? (y/n) " -n 1 -r
        echo
        if [[  $REPLY =~ ^[Yy]$ ]]
        then
                echo "Installing service..."

                sudo touch $SERVICE_ADDRESS
                sudo tee $SERVICE_ADDRESS << END
[Unit]
Description=Terra Daemon
After=network.target

[Service]
Type=simple
User=$(whoami)
ExecStart=$(which terrad) start
Restart=on-abort

[Install]
WantedBy=multi-user.target

[Service]
LimitNOFILE=65535
END


                sudo systemctl daemon-reload
                sudo systemctl enable terrad
                echo "${green}Service installed!${reset}"
                HAVE_SERVICE="y"
        fi
else
        echo "SERVICE EXISTS"
        HAVE_SERVICE="y"
fi



if [[  $IS_TESTNET =~ ^[Yy]$ ]]
then
        GENESIS_FILE="https://raw.githubusercontent.com/terra-money/testnet/master/pisco-1/genesis.json"
        sed -i 's/persistent_peers = ""/persistent_peers = "a4a8fbd7d26242263250a1d3ecb39f113832534b@52.73.183.21:26656, 3a4c8f4d75781f39b558c3889157acfaa144a793@50.19.18.17:26656, 948f35f9aa8817dc65fbc522ef685e9fd5beba72@46.101.246.161:26656"/' ~/.terra/config/config.toml
else
        GENESIS_FILE="https://phoenix-genesis.s3.us-west-1.amazonaws.com/genesis.json"
        sed -i 's/persistent_peers = ""/persistent_peers = "dc865a0d882f30e41e99ef23d9e6164163607523@54.147.79.192:26656,bdce6030a2bdebe4c660a76599fe3dee4a42d50f@35.154.54.64:26656,0f1096278efafcf3f0d3bd5b6544e6b8dcc36a0e@206.189.129.195:26656,c8ab8910e5f7bfcc6e81351eb851eb8c0540a194@exitnode.cereslabs.io:26656,33afc1c21cb225bb2cfb9700442a576bbaeb7691@163.172.100.203:26656,9038d63588e0ab421fa71582720c1efb1ee867f6@45.34.1.114:27656,daa2fd0dc725d6673e7688c9c57fc3b6d99c83c4@solarsys.noip.me:27656,331c2bbcd1aab921563dce85dedae840e1369e39@142.132.199.98:10656,91b675be5f81931375358e02ab687c88fab02e41@135.148.55.229:11656,9dc9e9b50c4cae52cdbec2034d879427b2a429ae@54.180.81.122:26656,ad825ef6b29306d80b0eb8101133cedf7933eb5e@116.203.36.94:26656,f2069012aec5ced4e88e7e4311391eabe72bb5a3@node-phoenix.terra.lunastations.online:26656,9fe9cc32880be11134e1ec360a61082541019233@162.55.85.23:26656,065fd6f49a4a424727433b3a8e3d5945e4935d9c@78.46.68.41:26656,9909a0fc254852005c6d382b2321008e669f7ad0@65.108.199.18:9095,5d423d17f84f25b8c2167fd8be4abd0b8ba89091@65.108.110.125:12095,1b308820fa76c033cd2e41e1a11b2533a55f4a03@65.108.10.95:17095,1903ccc818ee9923cd66078689d71000b2c6e4c9@65.108.98.218:10095,276dd792b8eb8703e65edcb5f5527d16b762191c@138.201.16.240:15095,7d7e614db9a73e1e6d7b56903ad79bfc13623783@142.132.252.8:11095,f58748aa96bd0110a1ed5c00b0fbf4e9faf92b20@18.219.130.4:26656,1e5e39efe018876c355cbb81a772668e5ce5e1ea@52.54.234.245:26656,49171079e358230f214f521b572f4b0caa4afa1b@51.222.42.166:26322,9c888a18a8c4a493830f56e4effd5da6035acfb7@141.95.66.199:26322,4ebf87085c2a3cc65d09549938985cf72a3c7734@phoenix.terra.kkvalidator.com:26656,89e8c6097c1cc56e2f1e0f96ef2eedd3dd31aa8c@34.67.180.86:26656,69e8b793059b813d79e5c3f4c4ff9f0d0c7d82e8@216.153.60.190:26656,f1818c94e9fdf77027196f96fe9062002d588c2a@216.153.60.189:26656"/' ~/.terra/config/config.toml
fi

echo "Downloading genesis file: ${cyan}$GENESIS_FILE${reset}"
wget "$GENESIS_FILE" -P /tmp/
cp /tmp/genesis.json ~/.terra/config/genesis.json && rm /tmp/genesis.json

#set min gas prices
read -p "Select minimum gas price (default ${cyan}$MIN_GAS${reset}): " -r input
MIN_GAS="${input:-$MIN_GAS}"
sed -i 's/minimum-gas-prices = "0uluna"/minimum-gas-prices = "'${MIN_GAS}'uluna"/g' ~/.terra/config/app.toml
echo "Set minimum gas price to ${cyan}${MIN_GAS}uluna${reset}"
read -p "Select P2P port (default ${cyan}$P2P_PORT${reset}): " -r input
P2P_PORT="${input:-$P2P_PORT}"
EXT_IP="$(curl -s httpbin.org/ip | jq -r .origin)"
echo "Setting your IP to: ${cyan}$EXT_IP:$P2P_PORT${reset}"
sed -i -e 's/external_address = \"\"/external_address = \"'$EXT_IP':26656\"/g' ~/.terra/config/config.toml

if [[  $HAVE_SERVICE =~ ^[Yy]$ ]]
then
    read -p "Start the service? (y/n):  " -n 1 -r reset
        echo
    if [[  $reset =~ ^[Yy]$ ]]
    then
        sudo systemctl start terrad
        echo "View service logs with: ${cyan}sudo journalctl -t terrad -f${reset}"
    fi
fi


echo "${green}Installation complete!${reset}"
