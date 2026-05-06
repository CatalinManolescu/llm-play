#!/usr/bin/env bash
set -euo pipefail

PORT="11434"
DOCKER_SUBNET="172.16.0.0/12"
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

apply_rules() {
  # Remove old copies first so ordering stays sane
  delete_rule_if_exists -p tcp --dport "$PORT" -j DROP
  delete_rule_if_exists -p tcp -s "$DOCKER_SUBNET" --dport "$PORT" -j ACCEPT
  delete_rule_if_exists -p tcp -s 127.0.0.1/32 --dport "$PORT" -j ACCEPT

  # Re-add in the correct order
  insert_rule 1 -p tcp -s 127.0.0.1/32 --dport "$PORT" -j ACCEPT
  insert_rule 2 -p tcp -s "$DOCKER_SUBNET" --dport "$PORT" -j ACCEPT
  insert_rule 3 -p tcp --dport "$PORT" -j DROP
}

remove_rules() {
  delete_rule_if_exists -p tcp --dport "$PORT" -j DROP
  delete_rule_if_exists -p tcp -s "$DOCKER_SUBNET" --dport "$PORT" -j ACCEPT
  delete_rule_if_exists -p tcp -s 127.0.0.1/32 --dport "$PORT" -j ACCEPT
}

status_rules() {
  "$IPTABLES" -L INPUT -n --line-numbers | sed -n '1,200p'
}

usage() {
  cat <<EOF
Usage: $0 {apply|remove|status}

apply   Add/update INPUT rules for Ollama port $PORT
remove  Remove INPUT rules for Ollama port $PORT
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