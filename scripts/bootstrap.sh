#! /bin/bash
set -eux

## Vagrant setup
#cp /vagrant/env.sample .

sudo apt-get update
sudo apt-get install -y curl git nodejs gcc pkg-config libssl-dev libpq-dev postgresql-client nginx
sudo add-apt-repository universe
sudo add-apt-repository -y ppa:certbot/certbot
sudo apt-get update
sudo apt-get install -y python-certbot-nginx

# Install rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env

# Install nodejs
curl -sL https://deb.nodesource.com/setup_14.x | sudo bash -
echo "deb https://deb.nodesource.com/node_14.x focal main" | sudo tee /etc/apt/sources.list.d/nodesource.list
sudo apt-get update && sudo apt-get install -y nodejs

# Install yarn
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-get update && sudo apt-get install -y yarn

# Get cargo project
# test -d cargo || git clone https://github.com/caeg-industries/cargo

# Diesel CLI
cargo install diesel_cli --no-default-features --features postgres

# Get crates.io
test -d crates.io || git clone https://github.com/caeg-industries/crates.io
#sed 's|DATABASE_URL=|DATABASE_URL=postgres://crates:YourPwdShouldBeLongAndSecure!@crates-postgres.c1piscwtiuok.us-west-1.rds.amazonaws.com:5432/cargo_registry|g' env.sample > crates.io/.env
#pushd crates.io
#diesel migration run
#git checkout subcrates
#yarn install
#cargo build
sudo echo "KillUserProcesses=no" | sudo tee -a /etc/systemd/logind.conf
sudo systemctl restart systemd-logind
sudo loginctl enable-linger ubuntu


echo "Finished"
