#!/bin/sh

echo "Setup TLS and nginx"

sudo rm /etc/nginx/sites-enabled/default
sudo mv ${site_fqdn}.conf /etc/nginx/sites-enabled/
sudo add-apt-repository universe
sudo add-apt-repository -y ppa:certbot/certbot
sudo apt-get update
sudo apt-get install -y python-certbot-nginx
sudo certbot --nginx
