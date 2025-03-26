brew install gpg
curl -s 'https://raw.githubusercontent.com/zerotier/ZeroTierOne/main/doc/contact%40zerotier.com.gpg' > zt.gpg
gpg --import zt.gpg 
if z=$(curl -s 'https://install.zerotier.com/' | gpg); then echo "$z" | sudo bash; fi                        


sudo su

zerotier-cli join XXXXX
