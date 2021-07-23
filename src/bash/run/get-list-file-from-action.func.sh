# Argument: file of the caller function.
# Exit 1 when caller's:
# - file does not exist
# - list file does not exist

do_get_list_file_from_action(){

   caller_fle=$1

   test -f $caller_fle || {
      echo "ERROR : Caller's file '$caller_fle' does not exist.";
      exit 1;
   }

   listfle="${caller_fle/.func.sh/.lst}"

   test -f $listfle || {
      echo "ERROR : List file '$listfle' does not exist.";
      exit 1;
   }

   echo $listfle

}
