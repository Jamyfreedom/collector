#!/bin/sh

#Usage: vuls.sh <path_to_target_directory>

# Define variables
EIS_CMD_OUT_DIR="$1"
EIS_VULS_DIR="$(readlink -e "$(dirname "$0")")/vuls"

EIS_VULS_CMD="$EIS_VULS_DIR/vuls-scanner scan"
EIS_VULS_CONF="$EIS_VULS_DIR/config.toml"

EIS_VULS_OUT_DIR="$EIS_CMD_OUT_DIR/vuls_output"
EIS_VULS_LOG="$EIS_VULS_OUT_DIR/log"
EIS_VULS_RES="$EIS_VULS_OUT_DIR/results"

mkdir "$EIS_VULS_OUT_DIR"
mkdir "$EIS_VULS_LOG"
mkdir "$EIS_VULS_RES"
$EIS_VULS_CMD -config "$EIS_VULS_CONF" -log-dir "$EIS_VULS_LOG" \
    -results-dir "$EIS_VULS_RES"
