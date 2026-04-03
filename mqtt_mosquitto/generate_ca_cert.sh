#!/bin/bash
set -e # Azonnali leállás hiba esetén

# --- Alapértelmezett értékek ---
PREFIX="ca"
COMMON_NAME="MyPermanentCA"
DAYS=10000

# --- Súgó funkció ---
show_help() {
    echo "Használat: $0 [OPCIÓK]"
    echo ""
    echo "Opciók:"
    echo "  -p, --prefix   Fájlnév prefix (alapértelmezett: ca)"
    echo "  -d, --domain   CA Common Name (CN) (alapértelmezett: MyPermanentCA)"
    echo "  -h, --help     Ennek a súgónak a megjelenítése"
    echo ""
    echo "Példa:"
    echo "  $0 -p vallalati_ca -d \"Sajat Vallalati CA\""
    exit 0
}

# --- Paraméterek feldolgozása ---
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -p|--prefix)
            PREFIX="$2"
            shift
            ;;
        -d|--domain)
            COMMON_NAME="$2"
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

echo "=== CA (Certificate Authority) Generáló ==="
echo " Fájl prefix  : $PREFIX (.crt, .key)"
echo " CA Név (CN)  : $COMMON_NAME"
echo " Érvényesség  : $DAYS nap"
echo "==========================================="

# CA generálása az aktuális mappába
echo "--- CA kulcs és tanúsítvány generálása ---"
openssl genrsa -out "${PREFIX}.key" 4096
openssl req -x509 -new -nodes -key "${PREFIX}.key" -sha256 -days $DAYS -out "${PREFIX}.crt" -subj "/C=HU/ST=Budapest/L=Budapest/O=SajatIoT/CN=$COMMON_NAME"

# Jogosultságok beállítása (a kulcsot szigorúan védjük!)
echo "--- Jogosultságok beállítása ---"
chmod 600 "${PREFIX}.key"
chmod 644 "${PREFIX}.crt"

echo "------------------------------------------------"
echo "KÉSZ! A CA tanúsítvány 27 évig érvényes."
echo "Létrehozott fájlok az aktuális mappában: ${PREFIX}.crt, ${PREFIX}.key"
echo "------------------------------------------------"