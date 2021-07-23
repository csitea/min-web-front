#!/usr/bin/env bash

set -x
main(){
   do_set_vars "$@"  # is inside, unless --help flag is present
   ts=$(date "+%Y%m%d_%H%M%S")
   main_log_dir=~/var/log/$RUN_UNIT/; mkdir -p $main_log_dir
   main_exec "$@" \
    > >(tee $main_log_dir/$RUN_UNIT.$ts.out.log) \
    2> >(tee $main_log_dir/$RUN_UNIT.$ts.err.log)
}

main_exec(){
   do_check_sudo_rights
   do_resolve_os
   do_set_vars "$@"  # is inside, unless --help flag is present
   do_set_fs_permissions
   do_install_min_req_bins
   do_load_functions

   test -z ${actions:-} && {
      IFS=$'\r\n' GLOBIGNORE='*' command eval "deploy_step_funcs=($(cat $current_box_definition_file))"
      do_log "INFO should run the following functions: \t"
      echo "${deploy_step_funcs[@]}"| perl -ne 's| |\n\t|g;print'
      counter=0;
      for i in ${!deploy_step_funcs[*]}
      do
        ((counter+=1))
        run_step=`echo ${deploy_step_funcs[$i]}|cut -c 4-`
        do_log "INFO START $run_step"
        printf "$counter/${#deploy_step_funcs[*]} $run_step \n\n";
        ${deploy_step_funcs[$i]}
        do_log "INFO STOP $run_step" ; echo -e "\n\n"
        sleep 1 ; do_flush_screen
      done
   }
   test -z ${actions:-} || {
      do_run_actions "$actions"
   }
   do_finalize
}


#------------------------------------------------------------------------------
# the "reflection" func - identify the the funcs per file
#------------------------------------------------------------------------------
get_function_list () {
   env -i PATH=/bin:/usr/bin:/usr/local/bin bash --noprofile --norc -c '
      source "'"$1"'"
      typeset -f |
      grep '\''^[^{} ].* () $'\'' |
      awk "{print \$1}" |
      while read -r fnc_name; do
         type "$fnc_name" | head -n 1 | grep -q "is a function$" || continue
            echo "$fnc_name"
            done
            '
}


do_read_cmd_args() {

	while [[ $# -gt 0 ]]; do
		case "$1" in
			-a|--actions) shift && actions="${actions:-}${1:-} " && shift ;;
			-b|--box) shift && export BOX=${1:-} && shift ;;
			-h|--help) actions=' do_print_usage ' && shift && test -z ${BOX:-} && BOX=sat ;;
			-j|--target-project-dir) shift && export TGT_PROJ_DIR=${1:-} && shift ;;
			*) echo FATAL unknown "cmd arg: '$1' - invalid cmd arg, probably a typo !!!" && shift && exit 1
    esac
  done
	shift $((OPTIND -1))

}


do_run_actions(){
   actions=$1
      cd $PRODUCT_DIR
      actions="$(echo -e "${actions}"|sed -e 's/^[[:space:]]*//')"  #or how-to trim leading space
      run_funcs=''
      while read -d ' ' arg_action ; do
         while read -r fnc_file ; do
            #debug func fnc_file:$fnc_file
            while read -r fnc_name ; do
               #debug fnc_name:$fnc_name
               action_name=`echo $(basename $fnc_file)|sed -e 's/.func.sh//g'`
               action_name=`echo do_$action_name|sed -e 's/-/_/g'`
               # debug  action_name: $action_name
               test "$action_name" != "$arg_action" && continue
               source $fnc_file
               test "$action_name" == "$arg_action" && run_funcs="$(echo -e "${run_funcs}\n$fnc_name")"
               #debug run_funcs: $run_funcs ; sleep 3
            done< <(get_function_list "$fnc_file")
         done < <(find "src/bash/run/" -type f -name '*.func.sh'|sort)

      done < <(echo "$actions")

   run_funcs="$(echo -e "${run_funcs}"|sed -e 's/^[[:space:]]*//;/^$/d')"
   while read -r run_func ; do
      #debug run_funcs: $run_funcs ; sleep 3
      cd $PRODUCT_DIR
      do_log "INFO START ::: running action :: $run_func"
      $run_func
      exit_code=$?
      if [[ "$exit_code" != "0" ]]; then
         exit $exit_code
      fi
      do_log "INFO STOP ::: running function :: $run_func"
   done < <(echo "$run_funcs")

}


do_flush_screen(){
   printf "\033[2J";printf "\033[0;0H"
}


#------------------------------------------------------------------------------
# echo pass params and print them to a log file and terminal
# usage:
# do_log "INFO some info message"
# do_log "DEBUG some debug message"
#------------------------------------------------------------------------------
do_log(){
   type_of_msg=$(echo $*|cut -d" " -f1)
   msg="$(echo $*|cut -d" " -f2-)"
   log_dir="${PRODUCT_DIR:-}/dat/log/bash" ; mkdir -p $log_dir
	log_file="$log_dir/${RUN_UNIT:-}.`date "+%Y%m%d"`.log"
   echo " [$type_of_msg] `date "+%Y-%m-%d %H:%M:%S %Z"` [${RUN_UNIT:-}][@${host_name:-}] [$$] $msg " | \
		tee -a $log_file
}


do_install_min_req_bins(){
	which perl 2>/dev/null || {
      run_os_func install_bins perl
   }
	which jq 2>/dev/null || {
      run_os_func install_bins jq
   }
}


do_set_vars(){
   set -u -o pipefail
	do_read_cmd_args "$@"
   export host_name="$(hostname -s)"
   unit_run_dir=$(perl -e 'use File::Basename; use Cwd "abs_path"; print dirname(abs_path(@ARGV[0]));' -- "$0")
   export RUN_UNIT=$(cd $unit_run_dir/../../../.. ; basename `pwd`)
   export PRODUCT_DIR=$(cd $unit_run_dir/../../.. ; echo `pwd`)
   test -z ${ENV:-} && echo "FATAL !!! No env defined !!! export ENV={dev,tst,stg,prd}" && exit 1

   cd $PRODUCT_DIR
   # workaround for github actions running on docker
   test -z ${GROUP:-} && export GROUP=$(id -gn)
   test -z ${GROUP:-} && export GROUP=$(ps -o group,supgrp $$|tail -n 1|awk '{print $1}')
   test -z ${USER:-} && export USER=$(id -un)
   test -z ${UID:-} && export UID=$(id -u)
   test -z ${GID:-} && export GID=$(id -g)
}



do_check_sudo_rights(){
   printf "\nChecking sudo rights.\n\n"
   if sudo -n true 2>/dev/null; then
      printf "OK\n"
   else
      msg="sudo rights for user '$USER' do not exist !!! \n\n exiting ... \n\n\n"
      echo -e "$msg"
      exit 1
   fi
}



do_set_fs_permissions(){

   # Check if is running inside a container to ignore this function.
   test -f /.dockerenv && return 0

   chmod 700 $PRODUCT_DIR ; sudo chown -R ${USER:-}:${GROUP:-} $PRODUCT_DIR

   # User chmod rwx to source dirs.
   for dir in `echo lib src cnf`; do
      chmod -R 0700 $PRODUCT_DIR/$dir ;
   done  ;


   # User chmod rwx to sh and py files and rw- to all other files from source dirs.
   for dir in "$PRODUCT_DIR/cnf" "$PRODUCT_DIR/lib" "$PRODUCT_DIR/src"; do
      find $dir -type f -not -path */node_modules/* -not -path */venv/* \
         \( -name '*.*' ! -name '*.sh' ! -name '*.py' \) -exec chmod 600 {} \;
      find $dir -type f -not -path */node_modules/* -not -path */venv/* \
         \( -name '*.sh' -or -name '*.py' \) -exec chmod 700 {} \;
   done
}


do_finalize(){

   do_flush_screen

   cat << EOF_FIN_MSG
   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
         $RUN_UNIT run completed
   :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
EOF_FIN_MSG
}


do_load_functions(){
    while read -r f; do source $f; done < <(ls -1 $PRODUCT_DIR/lib/bash/funcs/*.sh)
    while read -r f; do source $f; done < <(ls -1 $PRODUCT_DIR/src/bash/run/*.func.sh)
 }

run_os_func(){
	func_to_run=$1 ; shift ;

	if [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
	    distro=$(cat /etc/os-release|egrep '^ID='|cut -d= -f2)
	    if [ $distro == "ubuntu" ]; then
		"do_ubuntu_""$func_to_run" "$@"
	    elif [ $distro == "alpine" ]; then
		"do_alpine_""$func_to_run" "$@"
	    else
	       echo "your Linux distro is not supported !!!"
	    fi
	elif [ $(uname -s) == "Darwin" ]; then
	   echo "you are running on mac"
		"do_mac_""$func_to_run" "$@"
	fi

}


do_resolve_os(){
	if [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
	    distro=$(cat /etc/os-release|egrep '^ID='|cut -d= -f2)
	    if [ $distro == "ubuntu" ]; then
         export OS=ubuntu
	    elif [ $distro == "alpine" ]; then
         export OS=alpine
	    else
	       echo "your Linux distro is not supported !!!"
	    fi
	elif [ $(uname -s) == "Darwin" ]; then
         export OS=mac
	fi

}

main "$@"
