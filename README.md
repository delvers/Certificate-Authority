# Certificate Authoritie Script
  The purpos of this script is to create a CA, Server and Client Certificates.
  Also it (should) handle revocations and other maintenance tasks

## Overview
  Workflow:
  - Set your defaults in etc/shared.cnf
  ```
  # Optionally, specify some defaults.
  countryName_default             = DE
  stateOrProvinceName_default     = Hamburg
  localityName_default            = Hamburg
  0.organizationName_default      = Example Ltd
  #organizationalUnitName_default  =
  emailAddress_default            = root@example.com
  ```
  - Create a CA key and cert (on a save machine, if possible offline)
  - Create a intermediate certificate with key (also on that save machine)
  - Create server and client certificates

  The CA key and cert should be stored in a save (offline) place. It's only needed
  to create new intermediate certificates.

## Folder structure
#### CA Certificate and Key
- certs/ca.cert.pem
- private/ca.key.pem

#### Intermediate Certificates and Keys
  - intermediate/certs/intermediate*.cert.pem
  - intermediate/private/intermediate*.key.pem

#### User and Server Certificates + Keys
  - intermediate/certs/*.cert.pem
  - intermediate/private/*.key.pem

## ToDo
- Replace absolute directory paths
- Support multiple intermediate certificates
- Support creation of client certificates
- Support certs without passwords
- Handle some configurations
- Handle revocations
- Refactor script
- Add setup wizard
