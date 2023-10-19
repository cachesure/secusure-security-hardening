role: pki-openssl-ca
dependson: nginx
operating system: CentOS, Ubuntu

description:
This role will create a local OpenSSL Certificate Authority.
Certificate Signing Requests [CSR], Java Key Stores [JKS], Certificate Revocation Lists [CRL] and self-signed certificates can be processed by the CA and packaged as a full-chain PEM or JKS.
The function of this role could be suited to a development environment that requires valid & disposable SSL certificates, the CA is designed to be disposable as it is not intended to ever run again are certificates are generated.
