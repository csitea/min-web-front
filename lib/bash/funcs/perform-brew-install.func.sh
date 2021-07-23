# Argument: file of the caller function.

do_perform_brew_install(){

   list_fle=$(do_get_list_file_from_action $1) || { echo $list_fle; exit $?; }

   packages=$(do_get_packages_from_file -d $list_fle) || { echo $packages; exit $?; }

   for package in $packages
   do
      if [ $(brew list jq | grep -i 'bin/jq'|wc -l) -eq 1 ]
      then
         echo "Package '$package' is already installed.";
      else
         brew install $package

         if [ $(brew list jq | grep -i 'bin/jq'|wc -l) -ne 1 ]
         then {
            echo "ERROR : Package '$package' ";
            exit 1;
         }
         fi
      fi
   done

}
