# Configuración automática DNS para examen radio.lti.org

$domain      = "radio.lti.org"
$netId       = "172.16.160"
$networkCIDR = "172.16.160.0/24"
$dnsServerIp = "172.16.160.41"   # IP del servidor DNS (este Windows)
$servicesIp  = "172.16.160.42"   # Servidor música/web/mail
$printerIp   = "172.16.160.43"   # Impressora1

Write-Host ">>> Creando zona directa $domain ..."
# Crear zona directa primaria
Add-DnsServerPrimaryZone -Name $domain -ZoneFile "$domain.dns" -ErrorAction SilentlyContinue

Write-Host ">>> Creando zona inversa para $networkCIDR ..."
# Crear zona inversa primaria (172.16.160.x → x.160.16.172.in-addr.arpa)
$reverseZone = "$($netId.Split('.')[2]).$($netId.Split('.')[1]).$($netId.Split('.')[0]).in-addr.arpa"
# Eso queda: 160.16.172.in-addr.arpa
Add-DnsServerPrimaryZone -NetworkId $networkCIDR -ZoneFile "$reverseZone.dns" -ErrorAction SilentlyContinue

Write-Host ">>> Añadiendo registros A ..."

# Registro A para servidor de serveis: musica.radio.lti.org
Add-DnsServerResourceRecordA -Name "musica" -ZoneName $domain -IPv4Address $servicesIp -CreatePtr

# Registro A para noticies.radio.lti.org (misma IP que musica)
Add-DnsServerResourceRecordA -Name "noticies" -ZoneName $domain -IPv4Address $servicesIp -CreatePtr

# Registro A para impressora1.radio.lti.org
Add-DnsServerResourceRecordA -Name "impressora1" -ZoneName $domain -IPv4Address $printerIp -CreatePtr

Write-Host ">>> Añadiendo CNAME para web.radio.lti.org -> musica.radio.lti.org ..."

# Alias web.radio.lti.org → musica.radio.lti.org
Add-DnsServerResourceRecordCName -Name "web" -ZoneName $domain -HostNameAlias "musica.$domain"

Write-Host ">>> Añadiendo registro MX para $domain ..."

# MX del dominio radio.lti.org → musica.radio.lti.org
$mxRecord = New-DnsServerResourceRecord -Name $domain -ZoneName $domain -Mx `
    -Preference 10 -MailExchange ("musica." + $domain)

Add-DnsServerResourceRecord -ZoneName $domain -InputObject $mxRecord

Write-Host ""
Write-Host "✅ DNS configurado:"
Write-Host "   - Zona directa: $domain"
Write-Host "   - Zona inversa: $reverseZone"
Write-Host "   - musica.$domain -> $servicesIp"
Write-Host "   - noticies.$domain -> $servicesIp"
Write-Host "   - web.$domain (CNAME) -> musica.$domain"
Write-Host "   - MX $domain -> musica.$domain"
Write-Host "   - impressora1.$domain -> $printerIp"
