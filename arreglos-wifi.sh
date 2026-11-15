#!/bin/bash
# Arreglos Wi-Fi elegidos por el usuario:
#   1) Desactivar el modo de bajo consumo
#   2) Conectarse a la red de 5 GHz (lo haces tú desde el menú Wi-Fi)
# Antes de cambiar nada guarda los valores actuales en el Escritorio.
# Al final repite el test y abre la página del router en el navegador.
# Uso: bash arreglos-wifi.sh

ANTES="$HOME/Desktop/wifi-antes.txt"
DESPUES="$HOME/Desktop/wifi-despues.txt"
ROUTER=$(route -n get default 2>/dev/null | awk '/gateway/{print $2}')

estado_wifi() {
  system_profiler SPAirPortDataType 2>/dev/null \
    | awk '/Current Network Information/{f=1} /Other Local Wi-Fi Networks/{f=0} f' \
    | grep -E 'PHY Mode|Channel|Signal|Transmit Rate'
}

echo "===== PASO A: apunto los valores actuales ====="
{
  echo "Fecha: $(date)"
  echo "--- Modo de bajo consumo (1 = activado) ---"
  pmset -g | grep lowpowermode
  echo "--- Conexión Wi-Fi actual ---"
  estado_wifi
  echo "--- Redes Wi-Fi guardadas (en este orden) ---"
  networksetup -listpreferredwirelessnetworks en0
  echo
  echo "PARA DESHACER:"
  echo "  Bajo consumo:  sudo pmset -a lowpowermode 1"
  echo "  Wi-Fi:         vuelve a elegir tu red de antes en el menú Wi-Fi"
} | tee "$ANTES"

echo
echo "===== PASO B: desactivo el modo de bajo consumo ====="
echo ">> Escribe tu contraseña del Mac (no se verá al escribir) y pulsa Intro:"
sudo pmset -a lowpowermode 0 && pmset -g | grep lowpowermode

echo
echo "===== PASO C: cambia a la red de 5 GHz ====="
echo "1. Haz clic en el icono del Wi-Fi (arriba a la derecha de la pantalla)."
echo "2. Elige la red de tu casa que acabe en '5G' o '5GHz' (si existe)."
echo "   Si solo ves una red con tu nombre, quédate en ella: el router elige la banda solo."
echo "3. Ponte en el mismo sitio de siempre."
read -r -p ">> Cuando esté conectado, pulsa Intro para seguir... "
echo "--- Conexión ahora ---"
estado_wifi

echo
echo "===== PASO D: repito el test (unos 2 minutos) ====="
{
  echo "Fecha: $(date)"
  echo "--- Conexión Wi-Fi ---"; estado_wifi
  echo "--- Test de velocidad ---"; networkQuality -v | sed -n '/SUMMARY/,$p'
  echo "--- Ping al router (20) ---"; ping -c 20 "$ROUTER" | tail -2
  echo "--- Ping a 1.1.1.1 (20) ---"; ping -c 20 1.1.1.1 | tail -2
} | tee "$DESPUES"

echo
echo "===== PASO E: abro la página de tu router ====="
echo "Escribe tú la contraseña (suele venir en la pegatina de debajo del router)."
open "http://$ROUTER"

echo
echo "===== FIN ====="
echo "Valores de antes:  $ANTES"
echo "Resultado nuevo:   $DESPUES"
echo "Copia el texto del PASO D (Cmd+A, Cmd+C) y pégalo en el chat."
