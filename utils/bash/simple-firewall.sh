#!/usr/bin/env bash
set -euo pipefail

PORTS=("11434" "9000:9999")
DOCKER_SUBNET="172.16.0.0/12"
TRUSTED_NETWORKS=("127.0.0.1/32" "$DOCKER_SUBNET" "10.42.0.0/24" "192.168.96.0/20")
IPTABLES="${IPTABLES:-/usr/sbin/iptables}"

need_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "Run as root." >&2
    exit 1
  fi
}

have_iptables() {
  command -v "$IPTABLES" >/dev/null 2>&1 || {
    echo "iptables not found at $IPTABLES" >&2
    exit 1
  }
}

rule_exists() {
  "$IPTABLES" -C INPUT "$@" 2>/dev/null
}

insert_rule() {
  local pos="$1"
  shift
  if ! rule_exists "$@"; then
    "$IPTABLES" -I INPUT "$pos" "$@"
  fi
}

delete_rule_if_exists() {
  while rule_exists "$@"; do
    "$IPTABLES" -D INPUT "$@"
  done
}

apply_port_rules() {
  local port
  local trusted_network
  local pos
  for port in "${PORTS[@]}"; do
    delete_rule_if_exists -p tcp --dport "$port" -j DROP
    for trusted_network in "${TRUSTED_NETWORKS[@]}"; do
      delete_rule_if_exists -p tcp -s "$trusted_network" --dport "$port" -j ACCEPT
    done

    pos=1
    for trusted_network in "${TRUSTED_NETWORKS[@]}"; do
      insert_rule "$pos" -p tcp -s "$trusted_network" --dport "$port" -j ACCEPT
      pos=$((pos + 1))
    done
    insert_rule "$pos" -p tcp --dport "$port" -j DROP
  done
}

apply_rules() {
  apply_port_rules
}

remove_rules() {
  local port
  local trusted_network

  for port in "${PORTS[@]}"; do
    delete_rule_if_exists -p tcp --dport "$port" -j DROP
    for trusted_network in "${TRUSTED_NETWORKS[@]}"; do
      delete_rule_if_exists -p tcp -s "$trusted_network" --dport "$port" -j ACCEPT
    done
  done
}

status_rules() {
  "$IPTABLES" -L INPUT -n --line-numbers | sed -n '1,200p'
}

usage() {
  cat <<EOF
Usage: $0 {apply|remove|status}

apply   Add/update INPUT rules for port list: ${PORTS[*]}
remove  Remove INPUT rules for port list: ${PORTS[*]}
status  Show INPUT chain
EOF
}

main() {
  need_root
  have_iptables

  case "${1:-apply}" in
    apply)
      apply_rules
      ;;
    remove)
      remove_rules
      ;;
    status)
      status_rules
      ;;
    *)
      usage
      exit 2
      ;;
  esac
}

main "$@"