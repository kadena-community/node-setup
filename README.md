# Kadena Node Installation

**Note**: this guide assumes your machine is running Ubuntu, that you have
`sudo` privileges, that you've bought a proper Domain Name and are pointing it
at the Public IP Address of your machine.

### Installation

```bash
wget https://raw.githubusercontent.com/kadena-community/node-setup/master/installnode.sh
sudo bash installnode.sh
```

And follow the instructions.

A log of the install is stored in `/tmp/install.log` if there were any errors.

### Update

```bash
cd /root/kda
systemctl stop kadena-node
rm chainweb-node
wget https://github.com/kadena-io/chainweb-node/releases/download/1.8/chainweb-1.8.ghc-8.6.5.ubuntu-18.04.0efa2051.tar.gz
tar -xvf chainweb-1.8.ghc-8.6.5.ubuntu-18.04.0efa2051.tar.gz
systemctl ststart kadena-node
```
