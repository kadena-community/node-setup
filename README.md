# Kadena Node Installation

**Note**: this guide assumes your machine is running Ubuntu, and that you have
`sudo` privileges.

### Installation

```bash
wget https://raw.githubusercontent.com/kadena-community/node-setup/master/installnode.sh
sudo bash installnode.sh
```

For your `hostname`, enter your Domain Name or Public IP address.

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
