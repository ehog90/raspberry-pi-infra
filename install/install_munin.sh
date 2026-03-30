#!/bin/bash
set -e # Ez megállítja a szkriptet, ha bármelyik parancs hibára fut

# Ellenőrizzük, hogy root jogosultsággal fut-e a szkript
if [ "$EUID" -ne 0 ]; then
  echo "Kérlek, futtasd rootként! (pl.: sudo ./setup_munin_pi5.sh)"
  exit 1
fi

echo "=== Csomaglista frissítése és alapkövetelmények telepítése ==="
apt-get update
# A hibát okozó 'awk' eltávolítva. A munin, munin-node, python3-docker és a wget telepítése:
apt-get install -y munin munin-node python3-docker wget

echo "=== Docker Munin plugin letöltése és telepítése ==="
DOCKER_PLUGIN_PATH="/usr/share/munin/plugins/docker_"
wget -qO $DOCKER_PLUGIN_PATH https://raw.githubusercontent.com/kimor79/munin-docker/master/docker_
chmod +x $DOCKER_PLUGIN_PATH

echo "=== Docker plugin szimbolikus linkek létrehozása ==="
ln -sf $DOCKER_PLUGIN_PATH /etc/munin/plugins/docker_cpu
ln -sf $DOCKER_PLUGIN_PATH /etc/munin/plugins/docker_memory
ln -sf $DOCKER_PLUGIN_PATH /etc/munin/plugins/docker_network

echo "=== Docker plugin jogosultságok beállítása ==="
cat <<EOT > /etc/munin/plugin-conf.d/docker
[docker_*]
user root
env.docker_host unix://var/run/docker.sock
EOT

echo "=== Egyedi Raspberry Pi 5 Hőmérséklet plugin létrehozása ==="
PI_TEMP_PLUGIN="/usr/share/munin/plugins/pi5_temp"
cat <<'EOT' > $PI_TEMP_PLUGIN
#!/bin/sh
# Raspberry Pi 5 Hőmérséklet monitorozó Munin plugin

case $1 in
   config)
        cat <<'EOM'
graph_title Raspberry Pi 5 CPU Hőmérséklet
graph_vlabel Celsius fok
graph_category sensors
graph_info A Raspberry Pi 5 processzorának hőmérséklete.
temp.label CPU Temp
temp.warning 75
temp.critical 80
EOM
        exit 0;;
esac

echo -n "temp.value "
awk '{printf "%.1f\n", $1/1000}' /sys/class/thermal/thermal_zone0/temp
EOT

chmod +x $PI_TEMP_PLUGIN
ln -sf $PI_TEMP_PLUGIN /etc/munin/plugins/pi5_temp

echo "=== Hasznos alap pluginek automatikus engedélyezése ==="
munin-node-configure --shell | sh

echo "=== Munin Node újraindítása ==="
systemctl restart munin-node

echo "=== KÉSZ! ==="
echo "A Munin node sikeresen települt és újraindult."
