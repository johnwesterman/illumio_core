# How To Install OpenSSL 1.1.1s in CentOS / REHL / ROCKY Release 9x

In this paper I will explain how to install OpenSSL 1.1.1s in CentOS / REHL / ROCKY release 9.

In the software I have downloaded (minimal release) openssl 1.1.1 does not come with the software by default. However, I have a requirement for openssl 1.1.1 in my work. This is the process to install the software.

OpenSSL is a robust, commercial-grade, and full-featured toolkit for the Transport Layer Security (TLS) and Secure Sockets Layer (SSL) protocols. OpenSSL is a software library for applications that secure communications over computer networks against eavesdropping or need to identify the party at the other end.

1. A CentOS / REHL / ROCKY release 9 installed dedicated server or KVM VPS. I recommend the "minimal" version of these releases.
1. A root user access or normal user with administrative privileges.

## Keep the server up to date

Always keep the server up to date the security purpose.
```
dnf update -y
```
## Install development tools

We need to install a development tool and few dependencies to install OpenSSL
```
dnf group install ‘Development Tools’
```
## Install dependencies
```
dnf install perl-core zlib-devel wget bzip2 -y
```
## Download OpenSSL 1.1.1s

We will download the latest stable version is the 1.1.1 series. This is also our Long Term Support (LTS) version, supported until 11th September 2023.
```
cd /usr/local/src/
```
```
wget https://www.openssl.org/source/openssl-1.1.1s.tar.gz
```
Now, extract the tar file

```
tar -xzvf openssl-1.1.1s.tar.gz
```
## Configure and build

Navigate to the extracted directory and configure, build, test and install OpenSSL in the default location /usr/local/ssl.

```
cd openssl-1.1.1s
```

## Configure it with PATH
```
./config –prefix=/usr/local/ssl –openssldir=/usr/local/ssl shared zlib
```

Output should look something like this:

```
Insert text here.
```

## Install OpenSSL 1.1.1s

Now, build the software:

```
make
```
```
make test
```
```
make install
```
Make sure you observe for any errors. If done properly, there won't be anything other than warnings here.

## Configure it shared libraries.

Once we have successfully installed OpenSSL, configure it shared libraries.

Naviagate to the /etc/ld.so.conf.d directory and create a configuration file.

```
cd /etc/ld.so.conf.d/
```
```
vi openssl-1.1.1s.conf
```

Add the following path in the config file

    /usr/local/ssl/lib

Save and exit (:wq)

Reload the dynamic link

```
ldconfig -v
```

## Configure OpenSSL Binary

Time to insert the binary of our new version of OpenSSL /usr/local/ssl/bin/openssl and replace the default openssl file.

First, take a backup of existed openssl file.

```
mv /bin/openssl /bin/openssl.backup
```

Create new environment files for OpenSSL. This file may not exist. Open it anyway.

```
vi /etc/profile.d/openssl.sh
```

and add the following lines

```
OPENSSL_PATH=/usr/local/ssl/bin
export OPENSSL_PATH
PATH=$PATH:$OPENSSL_PATH
export PATH
```

Save and exit (:wq)

Make the newly created file executable
```
chmod +x /etc/profile.d/openssl.sh
```
Reload the new OpenSSL environment file and check the default PATH
```
source /etc/profile.d/openssl.sh
echo $PATH
```

Verify the installation and version of the OpenSSL

```
which openssl
```
This should return the path of the newly installed software.
```
openssl version -a
```
This should return the 1.1.1 version of openssl. Output will be similar like:

```
OpenSSL 1.1.1s 8 Dec 2020
built on: Sun Jan 10 03:58:36 2021 UTC
platform: linux-x86_64
options: bn(64,64) rc4(16x,int) des(int) idea(int) blowfish(ptr)
compiler: gcc -fPIC -pthread -m64 -Wa,–noexecstack -Wall -O3 -DOPENSSL_USE_NODELETE -DL_ENDIAN -DOPENSSL_PIC -DOPENSSL_CPUID_OBJ -DOPENSSL_IA32_SSE2 -DOPENSSL_BN_ASM_MONT -DOPENSSL_BN_ASM_MONT5 -DOPENSSL_BN_ASM_GF2m -DSHA1_ASM -DSHA256_ASM -DSHA512_ASM -DKECCAK1600_ASM -DRC4_ASM -DMD5_ASM -DAESNI_ASM -DVPAES_ASM -DGHASH_ASM -DECP_NISTZ256_ASM -DX25519_ASM -DPOLY1305_ASM -DZLIB -DNDEBUG
OPENSSLDIR: “/usr/local/ssl”
ENGINESDIR: “/usr/local/ssl/lib/engines-1.1”
Seeding source: os-specific
```

The installation tasks have been completed successfully.