ssh $1 << EOF
rm -rf strongswan*
apt update

apt install libpam-dev libssl-dev libgmp-dev build-essential ca-certificates

wget http://download.strongswan.org/strongswan.tar.gz
tar xzf strongswan.tar.gz
cd strongswan-*

./configure  --enable-eap-identity --enable-eap-md5 \
--enable-eap-mschapv2 --enable-eap-tls --enable-eap-ttls --enable-eap-peap  \
--enable-eap-tnc --enable-eap-dynamic --enable-eap-radius --enable-xauth-eap  \
--enable-xauth-pam  --enable-dhcp  --enable-openssl  --enable-addrblock --enable-unity  \
--enable-certexpire --enable-radattr --enable-tools --enable-openssl --disable-gmp

make
make install
EOF

scp fullchain.pem $1:/usr/local/etc/ipsec.d/certs/
scp privkey.pem $1:/usr/local/etc/ipsec.d/private/
scp ipsec.conf $1:/usr/local/etc/
scp ipsec.secrets $1:/usr/local/etc/
scp strongswan.conf $1:/usr/local/etc/
scp eap-radius.conf $1:/usr/local/etc/strongswan.d/charon/
scp xauth-eap.conf $1:/usr/local/etc/strongswan.d/charon/
scp iptables-save.bk $1:

ssh $1 << EOF
iptables-restore < iptables-save.bk
ipsec restart 
EOF
