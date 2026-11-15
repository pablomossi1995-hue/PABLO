#!/bin/bash
# Diagnóstico Wi-Fi para Mac — SOLO LEE, no cambia nada.
# Uso: bash diagnostico-wifi.sh   (tarda unos 2-3 minutos)
# Guarda el resultado en el Escritorio: diagnostico-wifi.txt

OUT="$HOME/Desktop/diagnostico-wifi.txt"
exec > >(tee "$OUT") 2>&1

WIFI_IF=$(networksetup -listallhardwareports | awk '/Wi-Fi/{getline; print $2}')
ROUTER=$(route -n get default 2>/dev/null | awk '/gateway/{print $2}')
SUBNET=$(echo "$ROUTER" | cut -d. -f1-3)

echo "===== FECHA: $(date) ====="
echo "Interfaz Wi-Fi: $WIFI_IF | Router: $ROUTER"

echo; echo "===== 1. TEST DE VELOCIDAD ====="
networkQuality -v
echo; echo "--- Ping al router (20) ---"
ping -c 20 "$ROUTER" | tail -2
echo; echo "--- Ping a 1.1.1.1 (20) ---"
ping -c 20 1.1.1.1 | tail -2

echo; echo "===== 2. AJUSTES DEL MAC ====="
echo "--- DNS ---"; scutil --dns | grep 'nameserver\[' | sort -u
echo "--- VPN ---"; scutil --nc list
ifconfig | grep -E '^(utun|ipsec|ppp)'
echo "--- Ahorro de energía ---"; pmset -g
echo "--- Apps usando internet (muestra 5 s) ---"
nettop -P -L 2 -s 5 -J bytes_in,bytes_out -x | tail -n +2 | sort -t, -k3 -nr | head -25

echo; echo "===== 3. SEÑAL, BANDA Y CANAL ====="
system_profiler SPAirPortDataType

echo; echo "===== 4. DISPOSITIVOS EN LA RED ====="
for i in $(seq 1 254); do ping -c1 -W 300 "$SUBNET.$i" >/dev/null 2>&1 & done; wait
arp -a
echo "--- Servicios anunciados (dns-sd, 6 s) ---"
for s in _airplay._tcp _googlecast._tcp _raop._tcp _printer._tcp _ipp._tcp _hap._tcp _smb._tcp _companion-link._tcp _spotify-connect._tcp; do
  echo "## $s"; (dns-sd -B "$s" local. & P=$!; sleep 6; kill $P) 2>/dev/null
done

echo; echo "===== 5. REDES CERCANAS ====="
echo "(están en la sección 'Other Local Wi-Fi Networks' del paso 3)"

echo; echo "===== FIN. Archivo guardado en: $OUT ====="
