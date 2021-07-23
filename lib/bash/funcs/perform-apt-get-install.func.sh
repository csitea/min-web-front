# Argument: file of the caller function.

do_perform_apt_get_install(){

   list_fle=$(do_get_list_file_from_action $1) || { echo $list_fle; exit $?; }

   packages=$(do_get_packages_from_file -d $list_fle) || { echo $packages; exit $?; }

   sudo apt-get update

   for package in $packages
      do
         if [ "$(sudo dpkg -s $package | grep Status)" == "Status: install ok installed" ]
            then
               echo "Package '$package' is already installed.";
         else
            sudo apt-get install -y $package

            if [ "$(sudo dpkg -s $package | grep Status)" != "Status: install ok installed" ]
               then {
                  echo "ERROR : Package '$package' is not available from Ubuntu default repository, a custom installation needs to be implemented.";
                  exit 1;
               }
            fi
         fi
      done

}
