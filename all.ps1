# ============================================================
# SUPER DNS EXAM SCRIPT - TOTALMENTE AUTOMÁTICO
# Dominio: radio.lti.org
# DNS Server: 172.16.160.42 (estético aunque no exista)
# NO modifica la IP del servidor, solo crea las zonas y registros
# ============================================================

$domain = "radio.lti.org"
$dnsIP  = "172.16.160.42"      # IP estética para el examen
$servicesIP = "172.16.160.42"  # Servidor de serveis (virtual)
$printerIP  = "172.16.160.43"  # Impressora1

Write-Host ">>> Instalando rol DNS (si no está instalado) ..."
Install-WindowsFeature DNS -IncludeManagementTools

Write-Host ">>> Iniciando servicio DNS ..."
Start-Service DNS

# ============================================================
#   ZONA DIRECTA
# ============================================================
Write-Host ">>> Creando zona directa $domain ..."
Add-DnsServerPrimaryZone -Name $domain -ZoneFile "$domain.dns" -DynamicUpdate None -ErrorAction SilentlyContinue

# ============================================================
#   ZONA INVERSA (172.16.160.x)
# ============================================================
Write-Host ">>> Creando zona inversa 172.16.160.x ..."
Add-DnsServerPrimaryZone -NetworkId "172.16.160.0/24" -ZoneFile "160.16.172.in-addr.arpa.dns" -ErrorAction SilentlyContinue

# ============================================================
#   REGISTROS A
# ============================================================
Write-Host ">>> Creando registros A ..."
Add-DnsServerResourceRecordA -Name "musica"     -ZoneName $domain -IPv4Address $servicesIP -CreatePtr
Add-DnsServerResourceRecordA -Name "noticies"   -ZoneName $domain -IPv4Address $servicesIP -CreatePtr
Add-DnsServerResourceRecordA -Name "impressora1" -ZoneName $domain -IPv4Address $printerIP -CreatePtr

# ============================================================
#   CNAME
# ============================================================
Write-Host ">>> Creando CNAME web -> musica ..."
Add-DnsServerResourceRecordCName -Name "web" -HostNameAlias "musica.$domain" -ZoneName $domain

# ============================================================
#   MX
# ============================================================
Write-Host ">>> Creando registro MX para $domain ..."
Add-DnsServerResourceRecordMX -ZoneName $domain -MailExchange "musica.$domain" -Preference 10

Write-Host "======================================================"
Write-Host " DNS COMPLETAMENTE CONFIGURADO PARA EL EXAMEN ✔"
Write-Host " Dominio: $domain"
Write-Host " DNS estetico: $dnsIP"
Write-Host " Registros creados:"
Write-Host "   musica -> $servicesIP"
Write-Host "   noticies -> $servicesIP"
Write-Host "   impressora1 -> $printerIP"
Write-Host "   web (CNAME) -> musica"
Write-Host "   MX -> musica"
Write-Host "======================================================"
