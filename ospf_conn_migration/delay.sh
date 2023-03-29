#!/usr/bin/env bash

function get_config_hz() {
  local config_hz
  local k_conf_line

  # First check for actual kernel config
  if [ -f /proc/config.gz ]; then
    k_conf_line=$(zcat /proc/config.gz | grep -E '^CONFIG_HZ_[0-9]+')
  # Fallback to Ubuntu like distros
  elif [ -f "/boot/config-$(uname -r)" ]; then
    k_conf_line=$(grep -E '^CONFIG_HZ_[0-9]+' "/boot/config-$(uname -r)" )
  else
    echo "Kernel config not found"
    exit 1
  fi

  if [ -n "$k_conf_line" ]; then
      config_hz=$(echo "$k_conf_line" | grep -oE '[0-9]+')
  else
    echo "CONFIG_HZ_XXX not set in this kernel. That's odd..."
    exit 1
  fi

  echo "$config_hz"
}

__set_impairment_tbf(){ local buflat_val limit_bytes
    local iface=${1}
    local delay=${2:-}
    local rate=${3:-}
    local loss=${4:-}
    local maxlat=${5:-1ms}
    local rate_val=${rate%mbit}
    local delay_val=${delay%ms}
    if [ "${delay_val}" == "" ]; then
        delay_val=0
        unset delay
    fi


    local maxlat_val=${maxlat%ms}
    if [ "${maxlat_val}" -ge "${delay_val}" ]; then
        buflat_val=$(( 3 * maxlat_val / 2 ))
        limit_bytes=$(( ( rate_val * buflat_val * 1000 ) / 8 ))
    else
        buflat_val=1
        limit_bytes=$(( ( rate_val * 1000000 ) / $(get_config_hz) ))
    fi


    latency=$(( 1500 / ( rate_val / 8 ) ))


    tc qdisc del dev "${iface}" root &> /dev/null || true
    tc qdisc del dev "${iface}" ingress &> /dev/null || true
    tc qdisc add dev "${iface}" root handle 1: netem ${delay:+delay "$delay"}  limit 100000 # ${loss:+loss "$loss"}
    ### FIXME bandwidth #tc qdisc add dev "${iface}" parent 1:1 handle 2: tbf rate "${rate}" burst "${limit_bytes}" latency "${latency}"us
    #tc qdisc add dev "${iface}" handle ffff: ingress
    #tc filter add dev "${iface}" parent ffff: u32 match u32 0 0 police rate 100mbit burst "${limit_bytes}" conform-exceed drop
}


if [ "$#" -ne 4 ]; then
    echo "Usage: $0 interface delay rate max_latency"
    exit 1
fi


__set_impairment_tbf $1 $2 $3 0 $4
tc qdisc show dev $1
ethtool -K $1 gro off gso off tso off
