#!/bin/bash
# Multitail script to show Nginx, SSHD, OpenVPN, and Docker logs
# Usage: ./dashboard.sh
LOG_FILES=(
    "/var/log/nginx/access.log"
    "/var/log/nginx/error.log"
    "/var/log/sshd.log"
    "/var/log/openvpn.log"
    "/var/log/docker.log"
)
# Check if multitail is installed
if ! command -v multitail &> /dev/null; then
    echo "multitail is not installed. Please install it first."