#!/bin/bash
set -e # Álljon le azonnal, ha bármelyik parancs hibára fut!

# --- Alapértelmezett értékek ---
CA_CERT="ca.crt"
CA_KEY="ca.key"
RAW_URL=""
SERVER_PREFIX="server"
CLIENT_PREFIX="client"
CLIENT_ID="mqtt-client-01"
DAYS=9999

# --- Súgó funkció ---
show_help() {
    echo "Használat: $0 -d <URL-vagy-DOMAIN> [OPCIÓK]"
    echo ""
    echo "Kötelező paraméter:"
    echo "  -d, --domain      Szerver domain neve vagy IP címe"
    echo ""
    echo "Opcionális paraméterek:"
    echo "  -c, --cacert      CA tanúsítvány (alapértelmezett: ca.crt)"
    echo "  -k, --cakey       CA kulcs (alapértelmezett: ca.key)"
    echo "  -s, --server      Szerver fájlok prefixe (alapértelmezett: server)"
    echo "  -cl, --client     Kliens fájlok prefixe (alapértelmezett: client)"
    echo "  -i, --client-id   Kliens azonosító/CN (alapértelmezett: mqtt-client-01)"
    echo "  -h, --help        Ennek a súgónak a megjelenítése"
    echo ""
    echo "Példa:"
    echo "  $0 -d mqtt.sajatdomain.hu -c myCA.crt -k myCA.key -s broker"
    exit 0
}

# --- Paraméterek feldolgozása ---
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d|--domain)
            RAW_URL="$2"
            shift
            ;;
        -c|--cacert)
            CA_CERT="$2"
            shift
            ;;
        -k|--cakey)
            CA_KEY="$2"
            shift
            ;;
        -s|--server)
            SERVER_PREFIX="$2"
            shift
            ;;
        -cl|--client)
            CLIENT_PREFIX="$2"
            shift
            ;;
        -i|--client-id)
            CLIENT_ID="$2"
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo "Hiba: Ismeretlen paraméter: $1"
            echo "A segítségért használd a --help kapcsolót."
            exit 1
            ;;
    esac
    shift
done

# --- 0. Ellenőrzések ---
if [ -z "$RAW_URL" ]; then
    echo "Hiba: A domain (-d) megadása kötelező!"
    echo "A segítségért használd a --help kapcsolót."
    exit 1
fi

if [ ! -f "$CA_CERT" ] || [ ! -f "$CA_KEY" ]; then
    echo "Hiba: A CA tanúsítvány ($CA_CERT) vagy a CA kulcs ($CA_KEY) nem található!"
    exit 1
fi

# Domain kinyerése (eltávolítja a protokollokat és a portokat, ha lennének)
DOMAIN=$(echo "$RAW_URL" | sed -e 's|^[^/]*//||' -e 's|/.*$||' -e 's|:.*$||')

echo "=== Szerver és Kliens Tanúsítvány Generáló ==="
echo " Domain (CN)      : $DOMAIN"
echo " CA Fájlok        : $CA_CERT, $CA_KEY"
echo " Szerver prefix   : $SERVER_PREFIX"
echo " Kliens prefix    : $CLIENT_PREFIX"
echo " Kliens azonosító : $CLIENT_ID"
echo " Érvényesség      : $DAYS nap"
echo "=============================================="

# 1. Szerver kulcs és CSR
echo "--- 1. Szerver kulcs és CSR generálása ---"
openssl genrsa -out "${SERVER_PREFIX}.key" 2048
openssl req -new -key "${SERVER_PREFIX}.key" -out "${SERVER_PREFIX}.csr" -subj "/CN=$DOMAIN"

# SAN (Subject Alternative Name)
echo "subjectAltName = DNS:$DOMAIN" > "${SERVER_PREFIX}.ext"

# 2. Szerver aláírása a meglévő CA-val
echo "--- 2. Szerver tanúsítvány aláírása ---"
openssl x509 -req -in "${SERVER_PREFIX}.csr" -CA "$CA_CERT" -CAkey "$CA_KEY" -CAcreateserial -out "${SERVER_PREFIX}.crt" -days $DAYS -sha256 -extfile "${SERVER_PREFIX}.ext"

# 3. Kliens kulcs és CSR
echo "--- 3. Kliens kulcs és CSR generálása ---"
openssl genrsa -out "${CLIENT_PREFIX}.key" 2048
openssl req -new -key "${CLIENT_PREFIX}.key" -out "${CLIENT_PREFIX}.csr" -subj "/CN=$CLIENT_ID"

# 4. Kliens aláírása
echo "--- 4. Kliens tanúsítvány aláírása ---"
openssl x509 -req -in "${CLIENT_PREFIX}.csr" -CA "$CA_CERT" -CAkey "$CA_KEY" -CAcreateserial -out "${CLIENT_PREFIX}.crt" -days $DAYS -sha256

# Biztonsági jogosultságok beállítása a kulcsokra
chmod 600 "${SERVER_PREFIX}.key" "${CLIENT_PREFIX}.key"
chmod 644 "${SERVER_PREFIX}.crt" "${CLIENT_PREFIX}.crt"

# Takarítás
rm -f "${SERVER_PREFIX}.csr" "${CLIENT_PREFIX}.csr" "${SERVER_PREFIX}.ext" *.srl

echo "-----------------------------------------------"
echo "Sikeres generálás a következő domainhez: $DOMAIN"
echo "Szerver fájlok: ${SERVER_PREFIX}.crt, ${SERVER_PREFIX}.key"
echo "Kliens fájlok : ${CLIENT_PREFIX}.crt, ${CLIENT_PREFIX}.key"
echo "-----------------------------------------------"