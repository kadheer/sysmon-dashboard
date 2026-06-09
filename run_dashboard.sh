#!/bin/bash
cd "$(dirname "$0")" || exit
./collect_system_data.sh
python3 generate_report.py
