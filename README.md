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

### Monitoring your Node

A code of `200` means GOOD.

```bash
# monitor status
tail -f /home/kda/health.out

# monitor errors
tail -f /home/kda/health.err

# monitor resource utilization
top
```
