# Kadena one liner node installation

### Installation 
wget https://raw.githubusercontent.com/kadena-community/node-setup/master/installnode.sh && sudo bash installnode.sh

Enter you domain name with an A record already pointed at your IP

A log of the install is stored in /tmp/install.log if you get any error

Monitoring your node
------------------------------------------
```Monitoring your node:

code 200 means GOOD

monitor status
tail -f /home/kda/health.out

monitor errors
tail -f /home/kda/health.err

monitor resource utilization
top
```
