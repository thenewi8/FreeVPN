scp fullchain.pem $1:/usr/local/etc/ipsec.d/certs/
scp privkey.pem $1:/usr/local/etc/ipsec.d/private/
scp ipsec.conf $1:/usr/local/etc/
scp eap-radius.conf $1:/usr/local/etc/strongswan.d/charon/
scp iptables-save.bk $1:

ssh $1 << EOF
iptables-restore < iptables-save.bk
ipsec restart 
EOF
