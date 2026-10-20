#!/usr/bin/env bash





#
# Update Nginx hardening snippet
#
curl https://raw.githubusercontent.com/trumb/nginx-hardening/refs/heads/main/security-hardening.conf > cnf/security-hardening.conf || exit 1
