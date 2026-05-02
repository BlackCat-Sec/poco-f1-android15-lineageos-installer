#!/usr/bin/env bash
set -euo pipefail

echo "[INFO] Updating Kali package lists..."
apt update

echo "[INFO] Installing practical ethical-security essentials..."
DEBIAN_FRONTEND=noninteractive apt install -y \
  nmap \
  netcat-traditional \
  socat \
  tcpdump \
  tshark \
  dnsutils \
  whois \
  traceroute \
  iproute2 \
  iputils-ping \
  curl \
  wget \
  git \
  python3 \
  python3-pip \
  python3-venv \
  jq \
  vim \
  nano \
  tmux \
  openssh-client \
  openssh-server \
  nikto \
  whatweb \
  gobuster \
  dirb \
  ffuf \
  sqlmap \
  metasploit-framework \
  wordlists \
  seclists \
  hashcat \
  john \
  hydra \
  aircrack-ng \
  bettercap

echo "[INFO] Cleaning package cache..."
apt clean

echo "[INFO] Verifying installed tools..."
for tool in nmap nc socat tcpdump tshark dig whois traceroute curl wget git python3 jq vim tmux ssh nikto whatweb gobuster dirb ffuf sqlmap msfconsole john hydra aircrack-ng bettercap; do
  if command -v "$tool" >/dev/null 2>&1; then
    printf "[OK] %-18s %s\n" "$tool" "$(command -v "$tool")"
  else
    printf "[WARN] %-18s not found\n" "$tool"
  fi
done

echo "[OK] Ethical-security toolkit install complete."
