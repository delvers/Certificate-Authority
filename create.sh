#!/bin/bash

# define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

init_dirs=('private' 'certs' 'csr' 'newcerts')

# init ca directory
function init_ca {
  for d in ${init_dirs[*]}
  do
    mkdir -p ./${d}
  done
  touch ./index.txt
  echo 1000 > ./serial
  echo "## DO NOT EDIT ##" > ./openssl.cnf
  echo "# use the configuration files ./etc/*.cnf" >> ./openssl.cnf
  cat ./etc/shared.cnf >> ./openssl.cnf
  cat ./etc/root_ca.cnf >> ./openssl.cnf
}

# init intermediate certs directory
function init_intermediate {
  for d in ${init_dirs[*]}
  do
    mkdir -p ./intermediate/${d}
  done
  touch ./intermediate/index.txt
  echo 1000 > ./intermediate/serial
  echo 1000 > ./intermediate/crlnumber
  echo "## DO NOT EDIT ##" > ./intermediate/openssl.cnf
  echo "# use the configuration files ./etc/*.cnf" >> ./intermediate/openssl.cnf
  cat ./etc/shared.cnf > ./intermediate/openssl.cnf
  cat ./etc/intermediate_ca.cnf >> ./intermediate/openssl.cnf
}

# function to create CA Root Key
function create_root_ca_key {
  echo "######## Generate CA Root Key ############"
  openssl genrsa -aes256 -out private/ca.key.pem 4096
  chmod 400 ./private/ca.key.pem
}

# function to create CA Root Certificate
function create_root_ca_cert {
  echo "######## Generate CA Root Certificate ##########"
  openssl req -config openssl.cnf \
        -key private/ca.key.pem \
        -new -x509 -days 7300 -sha256 -extensions v3_ca \
        -out certs/ca.cert.pem
  chmod 444 ./certs/ca.cert.pem
}

# handles program flow for creating a ca
function create_ca {
  # checks if root key already exists
  if [ -f ./private/ca.key.pem ]
  then
    echo "./private/ca.key.pem already exists. "
    echo -e "${RED}Do you REALY want to overwrite your ROOT CA KEY?"
    read -p "Are you sure? [y/N]" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
      chmod +w ./private/ca.key.pem
      read -p "REALY? [y/N]" -n 1 -r
      echo
      if [[ $REPLY =~ ^[Yy]$ ]]
      then
        echo -e "${NC}"
        create_root_ca_key
      fi
    fi
    echo -e "${NC}"
  else
      create_root_ca_key
  fi

  # checks if root cert already exists
  if [ -f ./certs/ca.cert.pem ]
  then
    echo "./certs/ca.cert.pem already exists. "
    echo -e "${RED}Do you REALY want to overwrite your ROOT CA CERT?"
    read -p "Are you sure? [y/N]" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
      chmod +w ./certs/ca.cert.pem
      read -p "REALY? [y/N]" -n 1 -r
      echo
      if [[ $REPLY =~ ^[Yy]$ ]]
      then
        echo -e "${NC}"
        create_root_ca_cert
      fi
    fi
    echo -e "${NC}"
  else
      create_root_ca_cert
  fi


  if [ -f ./certs/ca.cert.pem ]
  then
    openssl x509 -noout -text -in certs/ca.cert.pem
    echo -e "${GREEN}########## SUCCESS ##########${NC}"
  else
    echo -e "${RED}########## FAILURE ##########${NC}"
  fi
}

# function to create Intermediate private key
function create_intermediate_key {
  echo "######## Generate Intermediate Key ############"
  openssl genrsa -aes256 \
      -out ./intermediate/private/intermediate.key.pem 4096
  chmod 400 ./intermediate/private/intermediate.key.pem
}

# function to create and sign Intermediate Certificate
function create_intermediate_cert {
  echo "######## Generate Intermediate Certificate ############"
  # create intermediate certificate
  openssl req -config ./intermediate/openssl.cnf -new -sha256 \
      -key ./intermediate/private/intermediate.key.pem \
      -out ./intermediate/csr/intermediate.csr.pem
  # sign intermediate certificate by root ca
  openssl ca -config ./openssl.cnf -extensions v3_intermediate_ca \
      -days 3650 -notext -md sha256 \
      -in ./intermediate/csr/intermediate.csr.pem \
      -out ./intermediate/certs/intermediate.cert.pem
  chmod 444 ./intermediate/certs/intermediate.cert.pem
}

function create_intermediate {
  if [[ -f ./intermediate/private/intermediate.key.pem ]]
  then
    echo "./intermediate/private/intermediate.key.pem already exists."
    echo -e "${RED}Do you REALY want to overwrite your intermediate CA KEY?"
    read -p "Are you sure? [y/N]" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
      chmod +w ./intermediate/private/intermediate.key.pem
      read -p "REALY? [y/N] " -n 1 -r
      echo
      if [[ $REPLY =~ ^[yY]$ ]]
      then
        echo -e "${NC}"
        create_intermediate_key
      fi
    fi
    echo -e "${NC}"
  else
    create_intermediate_key
  fi

  if [[ -f ./intermediate/certs/intermediate.cert.pem ]]
  then
    echo "./intermediate/certs/intermediate.cert.pem already exists."
        echo -e "${RED}Do you REALY want to overwrite your intermediate CA Certificate?"
    read -p "Are you sure? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[yY]$ ]]
    then
      chmod +w ./intermediate/certs/intermediate.cert.pem
      read -p "REALY? [y/N] " -n 1 -r
      echo
      if [[ $REPLY =~ ^[Yy]$ ]]
      then
        echo -e "${NC}"
        create_intermediate_cert
      fi
    fi
    echo -e "${NC}"
  else
    create_intermediate_cert
  fi

  cat ./intermediate/certs/intermediate.cert.pem \
        ./certs/ca.cert.pem > ./intermediate/certs/ca-chain.cert.pem
  chmod 444 ./intermediate/certs/ca-chain.cert.pem

  if [[ -f ./intermediate/certs/intermediate.cert.pem ]]
  then
    openssl x509 -noout -text \
      -in ./intermediate/certs/intermediate.cert.pem
    openssl verify -CAfile ./certs/ca.cert.pem \
      ./intermediate/certs/intermediate.cert.pem
  fi

}

function create_certificat_key {
  echo "########## Create Certificate Key #########"
  openssl genrsa -aes256 \
      -out ./intermediate/private/${1}.key.pem 2048
  chmod 400 ./intermediate/private/${1}.key.pem
}

function create_certificat_csr {
  echo "########## Create Certificate csr ##########"
  openssl req -config ./intermediate/openssl.cnf \
      -key ./intermediate/private/${1}.key.pem \
      -new -sha256 -out ./intermediate/csr/${1}.csr.pem
}

function sign_certificat {
  echo "########## Sign Certificate ##########"
  openssl ca -config ./intermediate/openssl.cnf \
      -extensions server_cert -days 375 -notext -md sha256 \
      -in ./intermediate/csr/${1}.csr.pem \
      -out ./intermediate/certs/${1}.cert.pem
  chmod 444 ./intermediate/certs/${1}.cert.pem
}

function create_certificat {
  if [[ -f ./intermediate/private/${1}.key.pem ]]
  then
    echo "./intermediate/private/${1}.key.pem already exists."
    echo -e "${RED}Do you REALY want to overwrite your Certificate KEY for ${1}?"
    read -p "Are you sure? [y/N]" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
      chmod +w ./intermediate/private/${1}.key.pem
      read -p "REALY? [y/N] " -n 1 -r
      echo
      if [[ $REPLY =~ ^[yY]$ ]]
      then
        echo -e "${NC}"
        create_certificat_key ${1}
      fi
    fi
    echo -e "${NC}"
  else
    create_certificat_key ${1}
  fi

  if [[ -f ./intermediate/csr/${1}.csr.pem ]]
  then
    echo "./intermediate/csr/${1}.csr.pem already exists."
        echo -e "${RED}Do you REALY want to overwrite your csr for ${1}?"
    read -p "Are you sure? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[yY]$ ]]
    then
      chmod +w ./intermediate/csr/${1}.csr.pem
      read -p "REALY? [y/N] " -n 1 -r
      echo
      if [[ $REPLY =~ ^[Yy]$ ]]
      then
        echo -e "${NC}"
        create_certificat_csr $1
      fi
    fi
    echo -e "${NC}"
  else
    create_certificat_csr $1
  fi

  if [[ -f ./intermediate/certs/${1}.cert.pem ]]
  then
    echo "./intermediate/certs/${1}.cert.pem already exists."
        echo -e "${RED}Do you REALY want to overwrite your Certificate for ${1}?"
    read -p "Are you sure? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[yY]$ ]]
    then
      chmod +w ./intermediate/certs/${1}.cert.pem
      read -p "REALY? [y/N] " -n 1 -r
      echo
      if [[ $REPLY =~ ^[Yy]$ ]]
      then
        echo -e "${NC}"
        sign_certificat $1
      fi
    fi
    echo -e "${NC}"
  else
    sign_certificat $1
  fi

  if [[ -f ./intermediate/certs/${1}.cert.pem ]]
  then
    openssl x509 -noout -text \
        -in ./intermediate/certs/${1}.cert.pem
    openssl verify -CAfile ./intermediate/certs/ca-chain.cert.pem \
          ./intermediate/certs/${1}.cert.pem
  fi
}

function main {
  init_ca
  case "$1" in
    ca)
      create_ca
      ;;
    intermediate)
      init_intermediate
      create_intermediate
      ;;
    cert)
      if [[ -e ./intermediate ]]
      then
        create_certificat $2
      else
        echo "Maybe you should create a intermediate certificate by ~# ./create.sh intermediate"
      fi
      ;;
    *)
      echo "Usage: ./create.sh {ca|intermediate|cert <domain>}"
      exit 1
  esac
}

main $1 $2
