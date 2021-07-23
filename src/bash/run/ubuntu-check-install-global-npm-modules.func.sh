#!/bin/bash
do_ubuntu_check_install_global_npm_modules() {

   # if the nodejs bin does not exist install it ...
	which node 2>/dev/null || {
      run_os_func check_install_nodejs
   }

   export PUPPETEER_SKIP_DOWNLOAD='true'

   # install the npm modules from the list file
   npm_modules_lst_fle=$(dirname ${BASH_SOURCE})'/npm-modules.lst'
   npm_modules_lst=$(cat $npm_modules_lst_fle | xargs)
   sudo npm install -g $npm_modules_lst || {
      echo "ERROR : Failed to install the npm modules"
      exit 1
   }

}
