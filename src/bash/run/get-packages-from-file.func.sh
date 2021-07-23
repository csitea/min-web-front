# Gets the default or custom unversioned packages from file.
# Arguments: flag (-d or -c) and file.
# Exit 1 when:
# - flag is other than -d (default) or -c (custom)
# - file does not exist
# Returns the default or custom packages.

do_get_packages_from_file(){

   flag_default="-d"
   flag_custom="-c"
   flag=$1
   if [ $flag != $flag_default ] && [ $flag != $flag_custom ]
      then {
         echo "ERROR : Flag can be either default ('$flag_default') or custom ('$flag_custom').";
         exit 1;
      }
   fi

   fle=$2
   test -f $fle || {
      echo "ERROR : File '$fle' does not exist.";
      exit 1;
   }

   default_seperator='='

   if [ $flag == $flag_custom ]
      then
         packages=$(grep $default_seperator$ $fle | cut -d$default_seperator -f1);
      else
         packages=$(grep -v $default_seperator $fle);
   fi

   echo $packages

}
