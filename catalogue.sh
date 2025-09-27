#!/bin/bash
source ./common.sh
app_name=catalogue
check_root
app_setup
nodejs_setup
systemd_setup

catalogue_setup

app_restart

print_total_time