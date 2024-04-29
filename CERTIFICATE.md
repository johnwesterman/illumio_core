# All Things Certificates

```
Author: John Westerman, Illumio, Inc.
Serial number for this document is 20240429104819;
Version 2024.4
Monday April 29, 2024 10:48

Changed:
1. Cleaned up some of the wording.
2. Added highlighting and references to other documents using hyperlinks.
3. Fixed paragraph nesting.
4. Addes pkcs7 certficate wording.
```

Certificates are used for 3 major components in the PCE software installation that use TLS:
- **Web Service** – Used to secure access to the PCE web console, as well as that provided by the Illumio ASP REST API.
- **Event Service** – Provides continuous, secure connectivity from the PCE to the VENs under management and provides a notification capability so that VENs can be instructed to update policy on the host Workloads.
- **Service Discovery** – Used for cluster management between PCE node members in the cluster and allows real time alerting on service availability and status.

When building your certificate it will be important to remember these key x509 attributes included with the certificate:

- TLS Web **Server Authentication** Extended Key Usage
- TLS Web **Client Authentication** Extended Key Usage
- **Subject Alternative Names (SAN)** are included for the PCE cluster VIP name (load balancer FQDN) and core node names. You do not need to include the data nodes or any IP addresses in the SAN field of the certificate.

A single, common, certificate will be used for all these functions on all of the nodes but it is important that all the right options are present in the certificate to allow for secure communication of the software.

## Validating the Certificate.

Your certificate file should be in PEM format. If you look at the file, it will be text with "_BEGIN CERTIFICATE_" and _"END CERTIFICATE"_ in the text. Cat the certificate and make sure it's not encrypted.

Check the certificate to be valid:
```
openssl x509 -text -noout -in <certificate_name>
```
Another check that is displayed a little easier to read is to ask the PCE about the certificate. The following command will look at all of the certificates in the certificate chain and display information for each of them. If there is a problem with the certificate chain it will show up in this data. This is an Illumio specific command and uses my command line aliases [explained here](README.md#set-up-for-command-aliasing-optional).

```
ctlenv setup -ql --test 5
```

-or-

```
 /opt/illumio-pce/illumio-pce-env setup --test 5 --list
```

NOTE: You should see the full chain here. You also want the following extended attributes:
```
X509v3 Extended Key Usage:
TLS Web Server Authentication, TLS Web Client Authentication
```
*If you do not have TLS web and client you will need to generate a new certificate that include these attributes.*

## Certificates with passwords

**The Illumio platform expects private keys and certificates without passwords**. If you have a certificate or private key with a password you will need to remove the password before using.

To extract the password from a PEM file using OpenSSL, you can use the following command:

```bash
openssl rsa -in yourfile.pem -out keyfile.txt
```

Replace `yourfile.pem` with the path to your PEM file. When you run this command, OpenSSL will prompt you to enter the password for the PEM file. After entering the correct password, OpenSSL will extract the private key from the PEM file and save it to `keyfile.txt`.

Please note that you should ensure that you have the necessary permissions to access and extract the private key from the PEM file. Additionally, make sure to keep the extracted key file secure and handle it with care to maintain the security of your private key.

## Certificate Relationship

_**Note that MD5 is use to calculate these values. In a FIPS certified operating system MD5 will be disabled. You will have to check these certificates on a system that will support MD5 calculations.**_

Check to insure that the Private Key and the Certificate are related:
```
openssl rsa -modulus -noout -in server.key | openssl md5
openssl x509 -modulus -noout -in server.crt | openssl md5
```
If you are using a FIPS (Federal Information Processing Standards) enabled operating system you will need to use one of the other hashing methods that are considered more secure. [I describe that process here](#fipshashing). Switch MD5 with one of the other hashing algorythms as necessary to validate the relationship above.

NOTE: For the evaluation certificates, the file names I am working with are:
```
star_poc_segmentationpov_com.pem - Server private key
star_poc_segmentationpov_com_bundle.crt - Certificate bundle
```

And other commands to check certificates that are helpful:

```
openssl x509 -issuer -noout -in certificate_name.crt
openssl x509 -subject -noout -in certificate_name.crt

and you can combine these:

openssl x509 -subject -issuer -noout -in certificate_name.crt
```

These can help in identifying certificates, validating order, etc.

## Preparing the certificate and key files to be used

The Illumio PCE installer program installs the certificate and private keys as follows:

The private key is at /var/lib/illumio-pce/cert/server.key. Make sure it has the following file attributes:
```
chmod 400 server.key
chown ilo-pce:ilo-pce server.key
```

The server certificate bundle is at */var/lib/illumio-pce/cert/server.crt*

NOTE: this is a bundle file with full chain of trust in PEM format that will include all root and intermediate certificates in this order:

1. PCE certificate
2. Intermediate certificate(s) in order of trust
3. Root certificate

Make sure the certificate file has the proper permissions:
```
chmod 440 server.crt
chown ilo-pce:ilo-pce server.crt
```

If necessary (it usually isn't) the trusted CA bundle into /etc/ssl/certs/ca-bundle.crt
- this is not important and no need to copy anything here using the illumioeval certificates
- the full chain of trust is established in the server certificate with CA bundle above
- the CA will be known to the PCE/VEN because the ca-certificates package has been installed and COCOMO is defined.

##  UPDATING CA-trust (if required)

There should be no reason to do this with a valid certificate. This will only be required when there is no CA or the certificate chain can not be validated by the host. Sometimes (COMODO) there are more than 1 (often 2) intermediate certificates in use. You will need to combine the server certificate with all the intermedia and finally the root certificate chain. And do so in order: Server, then all intermediates, then the root certificate in one file.

Note: If either the PCE or the VENs do not have access to the CA (that is, the CA is *not* known internally) copy the root and intermediate certificates using any file name to: **/etc/pki/ca-trust/source/anchors/** then run these commands:
```
update-ca-trust force-enable; update-ca-trust extract; update-ca-trust check
```

To do the same for Ubuntu:

Go to /usr/local/share/ca-certificates/
Create a new folder, i.e. "sudo mkdir <any_folder_name>"
Copy the .crt file into the "any_folder_name" folder
Make sure the permissions are OK (755 for the folder, 644 for the file)
Finally, run "sudo update-ca-certificates"

## A note on setting up an Multi-Node Cluster (MNC)

**If you are not setting up an MNC you can safely skip this section.**

In most cases this document is used to set up a quick testing environment for functional testing using a single node (SNC). Normally a SNC is not used in production. Occasionally there is a need to set up a multi-node cluster (MNC) in a test environment. Here are some of my thoughts with that process.

Typically the setup will be run ("illumio-pce-env setup") on one core node only. That will generate a runtime yaml file and put it in the /etc/illumio-pce/runtime_env.yml file. This file will be a template in for all of the nodes constituting the MNC. In that file there are things that need to be consistent in the cluster:

* The certificate used in this process is the certificate used on all of the nodes. There will be only one certificate and one private key for all nodes. The certificate and private key are the same for all nodes. The point is once you have generated a proper certificate above you have what you need for the cluster nodes.
* The runtime_env.yml file will be mostly the same between all the nodes. The only thing that will likely be different is the **"node_type:"** directive. For the cores it is "core" and for the data nodes it's "data1" and "data2" in a 4 node cluster.
* The **"pce_fqdn:"** directive should never be a core node FQDN. It should always be a separate name which is usually the FQDN of the load balancer VIP IP for the PCE cluster.
* The **"service_discovery_fqdn:"** directive should all be the same. Usually we recommend point to the core0 FQDN or IP address.

So how to go about doing this.

* Run the setup on core0.
* Copy the **/etc/illumio-pce/runtime_env.yml** to each of the other nodes **/etc/illumio-pce/runtime_env**.
* Make relevant changes as indicated above to each of the other nodes changing their "node_type" to reflect the function of the node.

Once you have completed the work above you can continue to start and run the PCE MNC just like you would for an SNC. These steps follow.

<a id="fipshashing"></a>
### FIPS and hashing

When working with a FIPS (Federal Information Processing Standards) enabled system, you need to ensure that you are using approved cryptographic algorithms. In addition to MD5, which is not considered secure for cryptographic purposes due to vulnerabilities, you can use the following hash algorithms that are FIPS-compliant:

1. **SHA-1 (Secure Hash Algorithm 1)**:
   - While SHA-1 is still considered secure for some non-cryptographic purposes, it is generally not recommended for cryptographic applications due to vulnerabilities. It is included here for completeness, but it is advisable to use stronger algorithms.

2. **SHA-2 (Secure Hash Algorithm 2)**:
   - SHA-2 includes several variants such as SHA-256, SHA-384, and SHA-512. These are widely used and considered secure for cryptographic purposes. SHA-256 is commonly used for digital signatures and certificate verification.

3. **SHA-3 (Secure Hash Algorithm 3)**:
   - SHA-3 is the latest member of the Secure Hash Algorithm family, designed as a replacement for SHA-2. It offers different internal workings compared to SHA-2 and is also considered secure.

4. **BLAKE2**:
   - BLAKE2 is a cryptographic hash function that is faster than MD5 and SHA-1 while providing better security. It is not part of the SHA family but is a popular choice for secure hashing.

5. **Whirlpool**:
   - Whirlpool is a cryptographic hash function that produces a hash value of 512 bits. It is designed to be secure and is an alternative to the SHA family of hash functions.

When working with a FIPS-enabled Linux workload, you should consult the specific FIPS guidelines and regulations applicable to your environment to ensure compliance. It's important to use approved cryptographic algorithms and configurations to maintain the security and integrity of your system and data.

## Working with PKCS7 Certificates.

To convert a PKCS#7 certificate (also known as a .p7b or .p7c file) to PEM format, you can follow these steps using OpenSSL, a widely-used tool for working with cryptographic files:

1. **Install OpenSSL**: If you don't already have OpenSSL installed on your system, you can download it from the official website or install it using a package manager for your operating system.

2. **Convert PKCS#7 to PEM**:
   - Open a terminal or command prompt.
   - Run the following OpenSSL command to extract the certificates from the PKCS#7 file and convert them to PEM format:
     ```
     openssl pkcs7 -print_certs -in yourfile.p7b -out certificates.pem
     ```
     Replace `yourfile.p7b` with the path to your PKCS#7 file and `certificates.pem` with the desired output file name for the PEM format certificates.

3. **Verify the Conversion**:
   - Once the command has been executed successfully, you should have a PEM file containing the certificates extracted from the PKCS#7 file.
   - You can verify the contents of the PEM file using a text editor or by running the following command:
     ```
     openssl x509 -in certificates.pem -text -noout
     ```
     This command will display the details of the certificate(s) in the PEM file.

By following these steps, you should be able to convert a PKCS#7 certificate file to PEM format using OpenSSL. Make sure to securely store and manage the PEM format certificates as needed for your specific use case.

### PKCS7 Certificate contents

A PKCS#7 certificate file, also known as a .p7b or .p7c file, typically contains one or more digital certificates in a specific format defined by the Public-Key Cryptography Standards (PKCS) #7 specification. Here is what is typically contained in a PKCS#7 certificate file:

1. **Digital Certificates**: The primary content of a PKCS#7 certificate file is one or more digital certificates. These certificates are used to establish the identity of entities in a secure manner. Each certificate contains information such as the public key, subject (entity being identified), issuer (entity issuing the certificate), validity period, and other metadata.

2. **Certificate Chain**: A PKCS#7 certificate file may contain a chain of certificates, also known as a certificate chain. This chain includes the end-entity certificate (the certificate for the entity being identified) along with intermediate certificates and possibly a root certificate. The chain helps establish a trust relationship between the end-entity certificate and a trusted root certificate authority.

3. **Certificate Revocation Lists (CRLs)**: In some cases, a PKCS#7 certificate file may include Certificate Revocation Lists (CRLs). CRLs contain information about certificates that have been revoked by the issuing certificate authority before their expiration date. This information helps ensure the security and integrity of the certificate ecosystem.

4. **Certificate Attributes**: PKCS#7 certificate files may also include additional attributes or metadata associated with the certificates, such as certificate extensions, key usage information, signature algorithms, and other relevant details.

5. **Encrypted Data**: In some scenarios, a PKCS#7 certificate file may also contain encrypted data, such as encrypted messages or encrypted keys. This encrypted data can be securely transmitted or stored using the certificates contained in the file.

Overall, a PKCS#7 certificate file serves as a container for digital certificates and related cryptographic information, facilitating secure communication, authentication, and data protection in various applications and systems. When working with PKCS#7 certificate files, it is important to understand the contents and structure of the file to ensure proper handling and utilization of the certificates contained within.