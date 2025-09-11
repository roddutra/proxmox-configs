#!/bin/bash

# Certificate generation script for Traefik local setup
# This script generates self-signed certificates for *.homelab.local

set -e

echo "🔐 Generating self-signed certificates for homelab.local..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
DOMAIN="homelab.local"
CERT_DIR="./certs"
DAYS_VALID=3650  # 10 years

# Create certificate directory
mkdir -p "$CERT_DIR"

# Method selection
echo -e "${YELLOW}Choose certificate generation method:${NC}"
echo "1) Self-signed with OpenSSL (Quick, with browser warnings)"
echo "2) mkcert (No warnings, requires mkcert installation)"
read -p "Enter choice (1 or 2): " choice

case $choice in
    1)
        echo -e "${GREEN}Generating self-signed certificate with OpenSSL...${NC}"
        
        # Check if OpenSSL is installed
        if ! command -v openssl &> /dev/null; then
            echo -e "${RED}OpenSSL is not installed. Please install it first.${NC}"
            exit 1
        fi
        
        # Generate private key
        openssl genrsa -out "$CERT_DIR/$DOMAIN.key" 2048
        
        # Generate certificate request with SAN
        cat > "$CERT_DIR/openssl.conf" <<EOF
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = State
L = City
O = Homelab
CN = *.$DOMAIN

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = $DOMAIN
DNS.2 = *.$DOMAIN
DNS.3 = *.*.homelab.local
EOF
        
        # Generate self-signed certificate
        openssl req -new -x509 -sha256 -key "$CERT_DIR/$DOMAIN.key" \
            -out "$CERT_DIR/$DOMAIN.crt" -days $DAYS_VALID \
            -config "$CERT_DIR/openssl.conf"
        
        # Clean up config file
        rm "$CERT_DIR/openssl.conf"
        
        echo -e "${GREEN}✅ Self-signed certificate generated successfully!${NC}"
        echo -e "${YELLOW}⚠️  You will see browser warnings. Add exception when accessing services.${NC}"
        ;;
        
    2)
        echo -e "${GREEN}Generating certificate with mkcert...${NC}"
        
        # Check if mkcert is installed
        if ! command -v mkcert &> /dev/null; then
            echo -e "${RED}mkcert is not installed.${NC}"
            echo "Install mkcert first:"
            echo "  macOS: brew install mkcert"
            echo "  Linux: Download from https://github.com/FiloSottile/mkcert/releases"
            echo "  Then run: mkcert -install"
            exit 1
        fi
        
        # Generate certificate for domain and wildcard
        mkcert -cert-file "$CERT_DIR/$DOMAIN.crt" \
               -key-file "$CERT_DIR/$DOMAIN.key" \
               "$DOMAIN" "*.$DOMAIN" "*.*.homelab.local"
        
        echo -e "${GREEN}✅ Certificate generated with mkcert!${NC}"
        echo -e "${GREEN}Root CA location: $(mkcert -CAROOT)${NC}"
        echo -e "${YELLOW}📋 To trust on other devices, copy the root CA from above location.${NC}"
        ;;
        
    *)
        echo -e "${RED}Invalid choice. Exiting.${NC}"
        exit 1
        ;;
esac

# Set appropriate permissions
chmod 644 "$CERT_DIR/$DOMAIN.crt"
chmod 600 "$CERT_DIR/$DOMAIN.key"

echo ""
echo -e "${GREEN}Certificate files created:${NC}"
echo "  - Certificate: $CERT_DIR/$DOMAIN.crt"
echo "  - Private Key: $CERT_DIR/$DOMAIN.key"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Copy the certificate files to your Proxmox container:"
echo "   scp -r certs/ root@<PROXMOX_IP>:/root/traefik/"
echo ""
echo "2. Deploy Traefik with docker-compose:"
echo "   docker-compose -f docker-compose-local.yml up -d"
echo ""
echo "3. Configure AdGuard DNS to point *.homelab.local to Traefik IP"