#!/usr/bin/env bash

set_tmux_option() {
  local option="$1"
  local value="$2"
  tmux set-option -gq "$option" "$value"
}

get_tmux_option() {
  local option="$1"
  local default_value="$2"
  local option_value="$(tmux show-option -gqv "$option")"
  if [ -z "$option_value" ]; then
    echo "$default_value"
  else
    echo "$option_value"
  fi
}

get_primary_ip_macos() {
  if="NONE"
  route_str="$(route -n get 8.8.8.8 2> /dev/null | grep 'interface:' | awk '{ print $2 }')"
  if [ -n "${route_str}" ]; then
    if="${route_str}"
    ip="$(ipconfig getifaddr "${if}" 2> /dev/null)"
  else
    ip="no internet"
  fi

  case "${if}" in
    en*)
      ethernet="$(ifconfig "${if}" 2> /dev/null | grep "supported media:" | grep "baseT")"
      if [ -n "${ethernet}" ]; then
        icon="ethernet"
      else
        icon="wifi"
      fi
      ;;
    tun*|utun*|ipsec*)
      icon="vpn"
      ;;
    *)
      icon="unknown"
      ;;
  esac
  printf "%s:%s" "${icon}" "${ip}"
}

get_primary_ip_linux() {
  if="NONE"
  route_str="$(ip route get 8.8.8.8 2> /dev/null | head -1)"
  if [ -n "${route_str}" ]; then
    if echo "${route_str}" | /usr/bin/grep -q " via "; then
      ip=$(echo "${route_str}" | cut -d' ' -f7)
    else
      ip=$(echo "${route_str}" | cut -d' ' -f5)
    fi

    if=$(ip address show to "${ip}" | head -1 | cut -f2 -d: | tr -d ' ' | cut -c1-2)
  else
    ip="no internet"
  fi

  case "${if}" in
    en|et)
      icon="ethernet"
      ;;
    wl)
      icon="wifi"
      ;;
    vp)
      icon="vpn"
      ;;
    *)
      icon="unknown"
      ;;
  esac

  printf "%s:%s" "${icon}" "${ip}"
}

get_primary_ip() {
  case "$(uname -s)" in
    Darwin*)
      get_primary_ip_macos
      ;;
    *)
      get_primary_ip_linux
      ;;
  esac
}
