#!/bin/bash
do_check_install_py_modules(){
   set -x
   test -z ${TGT_DIR:-} && TGT_DIR=$PRODUCT_DIR
   do_check_install_poetry $TGT_DIR
   cd $TGT_DIR
   poetry config virtualenvs.create true
   poetry install -v
   cd -
}
