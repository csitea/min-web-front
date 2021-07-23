#!/bin/bash
do_ubuntu_check_install_nodejs(){

    command -v node || {
        sudo apt-get install -y curl
        curl -fsSL https://deb.nodesource.com/setup_14.x | sudo -E bash -
        sudo apt-get install -y nodejs
    }

    command -v yarn || {
        sudo npm install -g yarn
    }

    echo -e "\nnode version: $(node --version)"
    echo -e "\nnpm version: $(npm --version)"
    echo -e "\nyarn version: $(yarn --version)\n"

}
