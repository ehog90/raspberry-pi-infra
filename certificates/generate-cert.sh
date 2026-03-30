#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $0 [-c <ca_cert>] [-k <ca_key>] [-d <domain>] [-r <root_dir>]"
    echo "If not provided, you will be prompted for missing values."
    exit 1
}

# === Parse arguments ===
CA_CERT=""
CA_KEY=""
DOMAIN=""
ROOT_DIR=""

while getopts "c:k:d:r:" opt; do
    case $opt in
        c) CA_CERT="$OPTARG" ;;
        k) CA_KEY="$OPTARG" ;;
        d) DOMAIN="$OPTARG" ;;
        r) ROOT_DIR="$OPTARG" ;;
        *) usage ;;
    esac
done

# === Prompt for missing inputs ===
if [[ -z "$CA_CERT" ]]; then
    read -rp "Enter path to CA certificate file: " CA_CERT
fi

if [[ -z "$CA_KEY" ]]; then
    read -rp "Enter path to CA key file: " CA_KEY
fi

if [[ -z "$DOMAIN" ]]; then
    read -rp "Enter domain name: " DOMAIN
fi

if [[ -z "$ROOT_DIR" ]]; then
    read -rp "Enter root directory [./cert]: " ROOT_DIR
    ROOT_DIR="${ROOT_DIR:-./cert}"
fi

CERTS_DIR="$ROOT_DIR"
mkdir -p "$CERTS_DIR"

# File paths
KEY_FILE="$CERTS_DIR/$DOMAIN.key"
CSR_FILE="$CERTS_DIR/$DOMAIN.csr"
CRT_FILE="$CERTS_DIR/$DOMAIN.crt"
EXT_FILE="$CERTS_DIR/$DOMAIN.ext"
SERIAL_FILE="$CERTS_DIR/regor-ca.srl"

# === Dates ===
START_DATE=$(date -u +"%Y%m%d%H%M%SZ")
END_DATE=$(date -u -d "+730 days" +"%Y%m%d%H%M%SZ")

# === Create CA if it doesn't exist ===
if [[ ! -f "$CA_KEY" || ! -f "$CA_CERT" ]]; then
    echo "=== CA files not found. Creating new local CA ==="
    mkdir -p "$ROOT_DIR"
    openssl genrsa -out "$CA_KEY" 4096
    openssl req -x509 -new -nodes -key "$CA_KEY" -sha256 -days 3650 \
        -out "$CA_CERT" -subj "/CN=local-regor-ca"
fi

# === Generate private key for domain ===
echo "=== Generating private key for $DOMAIN ==="
openssl genrsa -out "$KEY_FILE" 2048

# === Generate CSR for domain ===
echo "=== Generating CSR for $DOMAIN ==="
openssl req -new -key "$KEY_FILE" -out "$CSR_FILE" -subj "/CN=$DOMAIN"

# === Create SAN + extensions config ===
echo "=== Creating SAN extensions for $DOMAIN ==="
cat > "$EXT_FILE" <<EOF
[v3_req]
basicConstraints = CA:FALSE
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = $DOMAIN
DNS.2 = www.$DOMAIN
EOF

# === Generate certificate signed by CA ===
echo "=== Signing certificate with CA (2 years validity) ==="
openssl x509 -req \
    -in "$CSR_FILE" \
    -CA "$CA_CERT" \
    -CAkey "$CA_KEY" \
    -CAcreateserial \
    -out "$CRT_FILE" \
    -days 730 \
    -extfile "$EXT_FILE" \
    -extensions v3_req

# === Done ===
echo "=== Certificate generation complete! ==="
echo "Private Key: $KEY_FILE"
echo "Certificate: $CRT_FILE"
echo "CSR: $CSR_FILE"
echo "Extensions: $EXT_FILE"
echo "CA Certificate: $CA_CERT"

# === Verify certificate ===
openssl x509 -in "$CRT_FILE" -noout -text -dates
