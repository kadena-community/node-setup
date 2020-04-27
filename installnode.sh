#!/bin/bash

###############################
# Script by Thanos and Fosskers
###############################

LOG_FILE=/tmp/install.log

decho () {
  echo `date +"%H:%M:%S"` $1
  echo `date +"%H:%M:%S"` $1 >> $LOG_FILE
}

error() {
  local parent_lineno="$1"
  local message="$2"
  local code="${3:-1}"
  echo "Error on or near line ${parent_lineno}; exiting with status ${code}"
  exit "${code}"
}
trap 'error ${LINENO}' ERR

clear

cat <<'FIG'

__/\\\________/\\\__/\\\\\\\\\\\\________/\\\\\\\\\_____________________________
__\/\\\_____/\\\//__\/\\\////////\\\____/\\\\\\\\\\\\\__________________________
___\/\\\__/\\\//_____\/\\\______\//\\\__/\\\/////////\\\________________________
____\/\\\\\\//\\\_____\/\\\_______\/\\\_\/\\\_______\/\\\_______________________
_____\/\\\//_\//\\\____\/\\\_______\/\\\_\/\\\\\\\\\\\\\\\______________________
______\/\\\____\//\\\___\/\\\_______\/\\\_\/\\\/////////\\\_____________________
_______\/\\\_____\//\\\__\/\\\_______/\\\__\/\\\_______\/\\\____________________
________\/\\\______\//\\\_\/\\\\\\\\\\\\/___\/\\\_______\/\\\___________________
_________\///________\///__\////////////_____\///________\///___________________
__/\\\\\_____/\\\_______/\\\\\_______/\\\\\\\\\\\\_____/\\\\\\\\\\\\\\\_________
__\/\\\\\\___\/\\\_____/\\\///\\\____\/\\\////////\\\__\/\\\///////////_________
___\/\\\/\\\__\/\\\___/\\\/__\///\\\__\/\\\______\//\\\_\/\\\___________________
____\/\\\//\\\_\/\\\__/\\\______\//\\\_\/\\\_______\/\\\_\/\\\\\\\\\\\__________
_____\/\\\\//\\\\/\\\_\/\\\_______\/\\\_\/\\\_______\/\\\_\/\\\///////__________
______\/\\\_\//\\\/\\\_\//\\\______/\\\__\/\\\_______\/\\\_\/\\\________________
_______\/\\\__\//\\\\\\__\///\\\__/\\\____\/\\\_______/\\\__\/\\\_______________
________\/\\\___\//\\\\\____\///\\\\\/_____\/\\\\\\\\\\\\/___\/\\\\\\\\\\\\\\\__
_________\///_____\/////_______\/////_______\////////////_____\///////////////__

FIG

# Check if executed as root user
if [[ $EUID -ne 0 ]]; then
  echo -e "This script has to be run as \033[1mroot\033[0m user."
  exit 1
fi

# Print variable on a screen
decho "Make sure you double check information before hitting enter!"

# --- USER INPUT --- #
read -e -p "Please enter your node's Domain Name: " whereami
if [[ $whereami == "" ]]; then
    decho "WARNING: No domain given, exiting!"
    exit 3
fi

read -e -p "Please enter your Public Key: " publickey
if [[ $publickey == "" ]]; then
    decho "WARNING: No public key given, exiting!"
    exit 3
fi

read -e -p "Please enter your Email Address: " email
if [[ $email == "" ]]; then
    decho "WARNING: No email address given, exiting!"
    exit 3
fi

# --- SYSTEM SETUP --- #

# Check for systemd.
systemctl --version >/dev/null 2>&1 || { decho "systemd is required. Are you using Ubuntu 18.04?" >&2; exit 1; }

# Update packages.
decho "Updating system..."

apt-get update -y >> $LOG_FILE 2>&1

# Install required packages
decho "Installing base packages and dependencies..."
decho "This may take a while..."

apt-get install -y certbot >> $LOG_FILE 2>&1
apt-get install -y librocksdb-dev >> $LOG_FILE 2>&1
apt-get install -y curl >> $LOG_FILE 2>&1

# --- NODE BINARY SETUP --- #

NODE=https://github.com/kadena-io/chainweb-node/releases/download/1.8/chainweb-1.8.ghc-8.6.5.ubuntu-18.04.0efa2051.tar.gz
MINER=https://github.com/kadena-io/chainweb-miner/releases/download/v1.0.3/chainweb-miner-1.0.3-ubuntu-18.04.tar.gz

decho 'Downloading Node...'
mkdir -p /root/kda
cd /root/kda/
wget --no-check-certificate $NODE >> $LOG_FILE 2>&1
tar -xvf chainweb-1.8.ghc-8.6.5.ubuntu-18.04.0efa2051.tar.gz >> $LOG_FILE 2>&1
wget --no-check-certificate $MINER >> $LOG_FILE 2>&1
tar -xvf chainweb-miner-1.0.3-ubuntu-18.04.tar.gz >> $LOG_FILE 2>&1

# Create config.yaml
decho "Creating config files and Health check..."

touch /root/kda/config.yaml
cat << EOF > /root/kda/config.yaml
chainweb:
  # The defining value of the network. To change this means being on a
  # completely independent Chainweb.
  chainwebVersion: mainnet01

  # The number of requests allowed per second per client to certain endpoints.
  # If these limits are crossed, you will receive a 429 HTTP error.
  throttling:
    local: 0.1
    mining: 5
    global: 50
    putPeer: 11

  mining:
    # Settings for how a Node can provide work for remote miners.
    coordination:
      enabled: true
      # "public" or "private".
      mode: private
      # The number of "/mining/work" calls that can be made in total over a 5
      # minute period.
      limit: 1200
      # When "mode: private", this is a list of miner account names who are
      # allowed to have work generated for them.
      miners:
      - account: $publickey
        predicate: keys-all
        public-keys:
        - $publickey

  p2p:
    # Your node's network identity.
    peer:
      # Filepath to the "fullchain.pem" of the certificate of your domain.
      # If "null", this will be auto-generated.
      certificateChainFile: /etc/letsencrypt/live/$whereami/fullchain.pem
      # Filepath to the "privkey.pem" of the certificate of your domain.
      # If "null", this will be auto-generated.
      keyFile: /etc/letsencrypt/live/$whereami/privkey.pem

      # You.
      hostaddress:
        # This should be your public IP or domain name.
        hostname: $whereami
        # The port you'd like to run the Node on. 443 is a safe default.
        port: 443

    # Initial peers to connect to in order to join the network for the first time.
    # These will share more peers and block data to your Node.
    peers:
      - address:
          hostname: us-w1.chainweb.com
          port: 443
        id: null
      - address:
          hostname: us-w2.chainweb.com
          port: 443
        id: null
      - address:
          hostname: us-w3.chainweb.com
          port: 443
        id: null
      - address:
          hostname: us-e1.chainweb.com
          port: 443
        id: null
      - address:
          hostname: us-e2.chainweb.com
          port: 443
        id: null
      - address:
          hostname: us-e3.chainweb.com
          port: 443
        id: null
      - address:
          hostname: fr1.chainweb.com
          port: 443
        id: null
      - address:
          hostname: fr2.chainweb.com
          port: 443
        id: null
      - address:
          hostname: fr3.chainweb.com
          port: 443
        id: null
      - address:
          hostname: jp1.chainweb.com
          port: 443
        id: null
      - address:
          hostname: jp2.chainweb.com
          port: 443
        id: null
      - address:
          hostname: jp3.chainweb.com
          port: 443
        id: null

logging:
  # All structural (JSON, etc.) logs.
  telemetryBackend:
    enabled: true
    configuration:
      handle: stdout
      color: auto
      # "text" or "json"
      format: text

  # Simple text logs.
  backend:
    handle: stdout
    color: auto
    # "text" or "json"
    format: text

  logger:
    log_level: warn

  filter:
    rules:
      - key: component
        value: cut-monitor
        level: info
      - key: component
        value: pact-tx-replay
        level: info
      - key: component
        value: connection-manager
        level: info
      - key: component
        value: miner
        level: info
      - key: component
        value: local-handler
        level: info
    default: error
EOF

# --- SYSTEMD SETUP FOR NODE --- #
touch /etc/systemd/system/kadena-node.service
cat <<EOF > /etc/systemd/system/kadena-node.service
[Unit]
Description=Kadena Node

[Service]
User=root
KillMode=process
KillSignal=SIGINT
WorkingDirectory=/root/kda
ExecStart=/root/kda/chainweb-node --config-file=/root/kda/config.yaml
Restart=always
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# --- HEALTH CHECK --- #
# touch /root/kda/health.sh
# chmod +x /root/kda/health.sh
# cat <<EOF > /root/kda/health.sh
# #!/bin/bash
# status_code=\$(timeout 5m curl --write-out %{http_code} https://$whereami:443/chainweb/0.0/mainnet01/health-check --silent --output /dev/null)
# echo \$status_code
# if [[ "\$status_code" -ne 200 ]]; then
#    echo "No response from API: Restarting the Node"
#    systemctl daemon-reload
#    systemctl restart kadena-node
# fi
# EOF

# # --- HEALTH CHECK CRONTAB --- #
# echo "*/5 * * * * /root/kda/health.sh >/root/kda/health.out 2>/root/kda/health.err" >> newCrontab
# crontab -u root newCrontab >> $LOG_FILE 2>&1
# rm newCrontab >> $LOG_FILE 2>&1

# --- DOMAIN-SPECIFIC CERTIFICATE CREATION --- #
certbot certonly --non-interactive --agree-tos -m $email --standalone --cert-name $whereami -d $whereami >> $LOG_FILE 2>&1

# --- ENABLE THE NODE --- #
systemctl daemon-reload
systemctl enable kadena-node

# --- DOWNLOAD A DATABASE SNAPSHOT --- #
echo "Downloading recent database snapshot..."
echo "This may take a while..."

# Send a stop message, just in case.
systemctl stop kadena-node
# No-op if it already exists.
mkdir -p /root/.local/share/chainweb-node/mainnet01/0/
cd /root/.local/share/chainweb-node/mainnet01/0/
# Remove these, in case they were already there.
rm -rf rocksDb sqlite
# Fetch the snapshot.
wget http://node-dbs.chainweb.com/db-chainweb-node-ubuntu.18.04-latest.tar.gz
tar xvfz db-chainweb-node-ubuntu.18.04-latest.tar.gz >> $LOG_FILE 2>&1
systemctl start kadena-node
clear

# Installation Completed
echo 'Installation completed!'
# echo 'Health checks are in place, and everything is automated from now on.'
echo 'Type "nano /root/kda/config.yaml" to edit your config if necessary.'
echo 'CTRL+x to save, Y to confirm, then "systemctl restart kadena-node".'
echo 'Type "journalctl -fu kadena-node" to see the node log.'
