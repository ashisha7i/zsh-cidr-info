#!/bin/bash
# cidr-info.sh — Calculate network, broadcast, usable range, and host count from a CIDR

set -euo pipefail

usage() {
  echo "Usage: $0 [--all] <IPv4/CIDR>"
  echo "  --all : Include network and broadcast in First/Last range"
  exit 1
}

include_all=false
if [[ $# -eq 2 && $1 == "--all" ]]; then
  include_all=true
  cidr="$2"
elif [[ $# -eq 1 ]]; then
  cidr="$1"
else
  usage
fi

ip=${cidr%/*}
prefix=${cidr#*/}

# Validate prefix
if ! [[ "$prefix" =~ ^[0-9]+$ ]] || (( prefix < 0 || prefix > 32 )); then
  echo "Invalid prefix: $prefix" >&2
  exit 1
fi

# Convert dotted IP to integer
ip2int() {
  local a b c d
  IFS=. read -r a b c d <<< "$1"
  for x in "$a" "$b" "$c" "$d"; do
    if ! [[ "$x" =~ ^[0-9]+$ ]] || (( x < 0 || x > 255 )); then
      echo "Invalid IP: $1" >&2
      exit 1
    fi
  done
  echo $(( (a<<24) + (b<<16) + (c<<8) + d ))
}

# Convert integer back to dotted IP
int2ip() {
  local n=$1
  local o1=$(( (n >> 24) & 255 ))
  local o2=$(( (n >> 16) & 255 ))
  local o3=$(( (n >> 8) & 255 ))
  local o4=$(( n & 255 ))
  echo "$o1.$o2.$o3.$o4"
}

ip_int=$(ip2int "$ip")

# Build subnet mask
if (( prefix == 0 )); then
  mask=0
else
  mask=$(( (0xFFFFFFFF << (32 - prefix)) & 0xFFFFFFFF ))
fi
inv_mask=$(( 0xFFFFFFFF ^ mask ))

# Calculate network & broadcast
network=$(( ip_int & mask ))
broadcast=$(( network | inv_mask ))

# Total addresses
total=$(( 1 << (32 - prefix) ))

# Usable range
if (( prefix == 32 )); then
  first=$network
  last=$network
  usable=1
elif (( prefix == 31 )); then
  first=$network
  last=$broadcast
  usable=2
else
  if $include_all; then
    first=$network
    last=$broadcast
    usable=$total
  else
    first=$(( network + 1 ))
    last=$(( broadcast - 1 ))
    usable=$(( total - 2 ))
  fi
fi

# Output
echo "  Input CIDR      : $cidr"
echo "  IP              : $ip"
echo "  Prefix          : /$prefix"
echo "  Netmask         : $(int2ip "$mask")"
echo "  Wildcard Mask   : $(int2ip "$inv_mask")"
echo "  Network         : $(int2ip "$network")"
echo "  Broadcast       : $(int2ip "$broadcast")"
echo "  First Address   : $(int2ip "$first")"
echo "  Last Address    : $(int2ip "$last")"
echo "  Total Addresses : $total"
echo "  Usable Hosts    : $usable"
echo " "

if [[ "$include_all" == false ]]; then
  echo "  Use --all option to see full range (inclusive of Network and Broadcast IPs)"
fi
