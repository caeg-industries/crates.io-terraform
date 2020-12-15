#!/bin/sh

echo "Setup TLS and nginx"

sudo rm /etc/nginx/sites-enabled/default
sudo mv ${site_fqdn}.conf /etc/nginx/sites-enabled/
sudo certbot --nginx
