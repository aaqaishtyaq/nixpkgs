#!/usr/bin/env bash

set -eu

cpu_usage() {
  local stat user nice system idle iowait irq softirq steal total idle_all
  local cache_file prev_total prev_idle diff_total diff_idle busy

  if [ ! -r /proc/stat ]; then
    printf "n/a"
    return
  fi

  read -r stat user nice system idle iowait irq softirq steal _ < /proc/stat
  total=$((user + nice + system + idle + iowait + irq + softirq + steal))
  idle_all=$((idle + iowait))

  cache_file="/tmp/tmux-cpu-${UID}.cache"
  if [ -r "$cache_file" ]; then
    read -r prev_total prev_idle < "$cache_file" || true
    if [ -n "${prev_total:-}" ] && [ -n "${prev_idle:-}" ]; then
      diff_total=$((total - prev_total))
      diff_idle=$((idle_all - prev_idle))
      if [ "$diff_total" -gt 0 ]; then
        busy=$((diff_total - diff_idle))
        printf "%d%%" $((busy * 100 / diff_total))
      else
        printf "n/a"
      fi
    else
      printf "n/a"
    fi
  else
    printf "n/a"
  fi

  printf "%s %s\n" "$total" "$idle_all" > "$cache_file"
}

mem_usage() {
  local total avail used pct used_g total_g

  if [ ! -r /proc/meminfo ]; then
    printf "MEM n/a"
    return
  fi

  total="$(awk '/^MemTotal:/ {print $2; exit}' /proc/meminfo)"
  avail="$(awk '/^MemAvailable:/ {print $2; exit}' /proc/meminfo)"

  if [ -z "${total:-}" ] || [ -z "${avail:-}" ] || [ "$total" -le 0 ]; then
    printf "MEM n/a"
    return
  fi

  used=$((total - avail))
  pct=$((used * 100 / total))
  used_g="$(awk -v kib="$used" 'BEGIN { printf "%.1f", kib / 1048576 }')"
  total_g="$(awk -v kib="$total" 'BEGIN { printf "%.1f", kib / 1048576 }')"
  printf "MEM %s/%sG %s%%" "$used_g" "$total_g" "$pct"
}

network_info() {
  local iface addr

  if ! command -v ip >/dev/null 2>&1; then
    printf "NET n/a"
    return
  fi

  iface="$(ip -o -4 route show to default 2>/dev/null | awk '{print $5; exit}')"
  if [ -z "${iface:-}" ]; then
    printf "NET n/a"
    return
  fi

  addr="$(ip -o -4 addr show dev "$iface" 2>/dev/null | awk '{print $4; exit}')"
  addr="${addr%%/*}"
  if [ -n "${addr:-}" ]; then
    printf "NET %s:%s" "$iface" "$addr"
  else
    printf "NET %s" "$iface"
  fi
}

uptime_short() {
  local seconds days hours mins

  if [ ! -r /proc/uptime ]; then
    printf "UP n/a"
    return
  fi

  seconds="$(awk '{print int($1)}' /proc/uptime)"
  days=$((seconds / 86400))
  hours=$(((seconds % 86400) / 3600))
  mins=$(((seconds % 3600) / 60))

  if [ "$days" -gt 0 ]; then
    printf "UP %dd%02dh" "$days" "$hours"
  else
    printf "UP %02dh%02dm" "$hours" "$mins"
  fi
}

load_avg() {
  local one five fifteen

  if [ ! -r /proc/loadavg ]; then
    printf "LOAD n/a"
    return
  fi

  read -r one five fifteen _ < /proc/loadavg
  printf "LOAD %s %s %s" "$one" "$five" "$fifteen"
}

printf "CPU %s | %s | %s | %s | %s" \
  "$(cpu_usage)" \
  "$(load_avg)" \
  "$(mem_usage)" \
  "$(network_info)" \
  "$(uptime_short)"
