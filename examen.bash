#!/bin/bash
# Configuración automática de servidor DHCP para examen 172.16.160.0/24
# Probado para Ubuntu Server con isc-dhcp-server instalado.

set -e

### 🔧 PARÁMETROS EDITABLES (si cambian en otro examen)
EXAM_IF="ens20"                # Interfaz de la red de examen
EXAM_NET="172.16.160.0"
EXAM_MASK="255.255.255.0"
EXAM_PREFIX="24"
WAN_IF="enp1s0"                # Interfaz que va por DHCP normal (ISARD)

DHCP_IP="172.16.160.40"        # IP del servidor DHCP
ROUTER_IP="172.16.160.1"       # Gateway lógico
DNS_IP="172.16.160.41"         # IP del servidor DNS (Windows Server)

RANGE_START="172.16.160.100"
RANGE_END="172.16.160.150"

DOMAIN="radio.lti.org"

### 🛡 Comprobación de permisos
if [ "$(id -u)" -ne 0 ]; then
    echo "⚠ Este script debe ejecutarse como root (sudo)."
    exit 1
fi

echo ">>> Configurando servidor DHCP para la red ${EXAM_NET}/24 en interfaz ${EXAM_IF}"

### 🗂 Backups
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

echo ">>> Haciendo copias de seguridad de netplan y dhcpd..."

mkdir -p /etc/netplan/backup-${TIMESTAMP}
cp /etc/netplan/*.yaml /etc/netplan/backup-${TIMESTAMP}/ 2>/dev/null || true

if [ -f /etc/dhcp/dhcpd.conf ]; then
    cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.bak-${TIMESTAMP}
fi

if [ -f /etc/default/isc-dhcp-server ]; then
    cp /etc/default/isc-dhcp-server /etc/default/isc-dhcp-server.bak-${TIMESTAMP}
fi

### 🌐 Netplan: interfaz de examen + interfaz WAN
echo ">>> Escribiendo /etc/netplan/01-examen.yaml ..."

cat >/etc/netplan/01-examen.yaml <<EOF
network:
  version: 2
  ethernets:
    ${WAN_IF}:
      dhcp4: true
    ${EXAM_IF}:
      dhcp4: no
      addresses:
        - ${DHCP_IP}/${EXAM_PREFIX}
EOF

echo ">>> Aplicando netplan..."
netplan apply

echo ">>> Estado de interfaces tras netplan:"
ip a | sed -n '1,20p'

### ⚙️ isc-dhcp-server: interfaz donde escuchar
echo ">>> Configurando /etc/default/isc-dhcp-server ..."

cat >/etc/default/isc-dhcp-server <<EOF
# Fichero generado por config_dhcp_examen.sh
INTERFACESv4="${EXAM_IF}"
INTERFACESv6=""
EOF

### 📜 dhcpd.conf básico para el examen
echo ">>> Configurando /etc/dhcp/dhcpd.conf ..."

cat >/etc/dhcp/dhcpd.conf <<EOF
default-lease-time 600;
max-lease-time 7200;
authoritative;

subnet ${EXAM_NET} netmask ${EXAM_MASK} {
    range ${RANGE_START} ${RANGE_END};
    option routers ${ROUTER_IP};
    option subnet-mask ${EXAM_MASK};
    option domain-name "${DOMAIN}";
    option domain-name-servers ${DNS_IP};
}
EOF

### 🚀 Reinicio del servicio
echo ">>> Reiniciando servicio isc-dhcp-server ..."
systemctl restart isc-dhcp-server

echo ">>> Estado del servicio:"
systemctl status isc-dhcp-server --no-pager -l || true

echo
echo "✅ Configuración terminada."
echo "   - Interfaz ${EXAM_IF} con IP ${DHCP_IP}/${EXAM_PREFIX}"
echo "   - DHCP sirviendo rango ${RANGE_START} - ${RANGE_END}"
echo "   - Router lógico: ${ROUTER_IP}"
echo "   - DNS anunciado: ${DNS_IP}"
