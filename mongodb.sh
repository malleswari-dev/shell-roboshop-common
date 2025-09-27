#!/bin/bash
source ./common.sh
app_name=mongodb

check_root

mongodb_setup

app_restart

print_total_time