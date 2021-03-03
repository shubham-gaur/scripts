#!/bin/bash

# Bash shell script for generating self-signed certs. Run this in a folder, as it
# generates a few files. Large portions of this script were taken from the
# following artcile:
#
# http://usrportage.de/archives/919-Batch-generating-SSL-certificates.html
#
# Additional alterations by: Brad Landers
# Date: 2012-01-27
# usage: ./gen_cert.sh example.com
source credentials.txt
OUT=generated
mkdir -p ./$OUT

# Script accepts a single argument, the fqdn for the cert
DOMAIN="$1"
if [ -z "$DOMAIN" ]; then
  echo "Usage: $(basename $0) <domain>"
  exit 11
fi

fail_if_error() {
  [ $1 != 0 ] && {
    unset PASSPHRASE
    echo -n "WARN: Error!"
    exit 10
  }
}

# Generate a passphrase
export PASSPHRASE=$(head -c 500 /dev/urandom | tr -dc a-z0-9A-Z | head -c 128; echo)

# Certificate details; replace items in angle brackets with your own info
subj="
C=$C
ST=$ST
O=$O
localityName=$LOCALITY_NAME
commonName=$DOMAIN
organizationalUnitName=$ORGANIZATION_UNIT
emailAddress=$EMAIL
"

# Generate the server private key
echo -e "INFO: Generating private key..."
openssl genrsa -des3 -out $OUT/$DOMAIN.key -passout env:PASSPHRASE 2048
fail_if_error $?

# Generate the CSR
openssl req \
    -new \
    -batch \
    -subj "$(echo -n "$subj" | tr "\n" "/")" \
    -key $OUT/$DOMAIN.key \
    -out $OUT/$DOMAIN.csr \
    -passin env:PASSPHRASE
fail_if_error $?
cp $OUT/$DOMAIN.key $OUT/$DOMAIN.key.org
fail_if_error $?

# Strip the password so we don't have to type it every time we restart Apache
echo -e "INFO: Generating organization key..."
openssl rsa -in $OUT/$DOMAIN.key.org -out $OUT/$DOMAIN.key -passin env:PASSPHRASE
fail_if_error $?

# Generate the cert (good for 10 years)
echo -e "INFO: Generating certificates..."
openssl x509 -req -days 3650 -in $OUT/$DOMAIN.csr -signkey $OUT/$DOMAIN.key -out $OUT/$DOMAIN.crt
fail_if_error $?
echo -e "INFO: Certificate generation completed!"

#openssl rsa -in $DOMAIN.key -check
openssl x509 -in $OUT/$DOMAIN.crt -text -noout
CERT_MD5=$(openssl x509 -noout -modulus -in $OUT/$DOMAIN.crt| openssl md5 | awk '{print $2}')
KEY_MD5=$(openssl rsa -noout -modulus -in $OUT/$DOMAIN.key| openssl md5 | awk '{print $2}')
if [ $CERT_MD5 = $KEY_MD5 ]; then
    echo -e "INFO: Verification successfull"
    exit 0
else
    echo -e "CRITICAL: Verification failed"
    exit 1
fi
