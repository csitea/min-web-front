#!/usr/bin/env python3

import datetime, sys, os, io, glob, pprint, requests, argparse, yaml, json, time, traceback
import os.path as path
from jq import jq
from pprintjson import pprintjson as ppjson
from requests.exceptions import HTTPError
from requests.auth import HTTPBasicAuth
import urllib.parse


gsd = {} # global singleton dictionary

def main():
    args = vars(parse_cmd_args())
    set_vars(args)

# src: https://gist.github.com/tawateer/a47460dd055a2bd69f94
def parse_cmd_args():
    parser = argparse.ArgumentParser(description='export qvarn data')
    parser.add_argument(
        '-j', '--jira_ticket', required=True, type=str, help='the jira ticket id')
    return parser.parse_args()


def call_get_uri_get_json(uri,headers={}):

    try:
        print(headers)
        print("eof headers")
        print(uri)
        print("eof uri")
        response = requests.get(uri,headers=headers)
        response.raise_for_status()
        json_response = response.json()
        return json_response

    except HTTPError as http_err:
        traceback.print_exc
    except Exception as err:
        traceback.print_exc


def set_vars(args):
    try:
        global ticket_dir

    except(IndexError) as error:
        print ("ERROR in set_vars: " , str(error))
        traceback.print_stack()
        sys.exit(1)


def write_string_to_file(fle,s):
    with io.open(fle, mode='w', encoding='utf-8') as f:
        f.write(s)

main() # Action !!!
