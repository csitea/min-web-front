#!/bin/bash
do_ubuntu_check_install_awscli() {

   do_perform_apt_get_install ${BASH_SOURCE} || { exit $?; }

   sudo ln -sfn $(which python3.8) /usr/bin/python
   sudo ln -sfn $(which python3.8) /usr/bin/python3

   wget https://bootstrap.pypa.io/get-pip.py ; sudo python3 get-pip.py ; sudo rm -v get-pip.py

   # Install python requirements for aws-cli.
   pip3 install -r ${BASH_SOURCE/.func.sh/.requirements.txt} || \
      { echo "ERROR : Error during requirements installation for aws-cli."; exit 1; }

}
