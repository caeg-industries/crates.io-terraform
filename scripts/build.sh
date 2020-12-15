#! /bin/bash
set -eux

source $HOME/.cargo/env
pushd crates.io
git checkout subcrates
diesel migration run
yarn install
yarn build
cargo build
