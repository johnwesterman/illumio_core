## Preparing the PCE environment for production (hardening)

### SUMMARY

Note: This document is intended for technical users who will be implementing the solution described below. This document is not intended for non-technical audiences. Refer to the Illumio Security Alert: Insecure Network Transmission (KB article 2894) which is intended for Security professional and non-technical audience. See the Frequently Asked Questions section below for more information.

Supported PCE Versions: 17.1.x, 18.2.x, and later

### INTRODUCTION
When the Illumio Policy Compute Engine (PCE) is deployed in a multi-node cluster, there are several connections between PCE components running on different nodes.

Within the cluster, connections may be encrypted or plaintext. Some plaintext connections can contain user and system credentials and other sensitive data. Depending on the customer network configuration, this data may be interceptable on the wire using packet sniffers, network taps, or similar tools. This risk exists in PCE multi-node cluster deployments. Splitting the cluster’s nodes across data centers or WAN links may increase this risk, especially if the WAN links are accessible by third parties.

This risk applies only to connections between nodes in one PCE cluster. The following are NOT impacted:

1. Connections to the PCE by the Virtual Enforcement Node (VEN) or web console. These always use TLS.
1. Connections between PCE clusters in a supercluster configuration. These always use TLS.
1. Single-node cluster (SNC) deployments, which do not make any outbound connections.
1. Customers using Illumio’s SaaS Cloud Edition PCE. This applies only to on-premise customer deployments.

Technically speaking, on the IIlumio PCE cluster, REST API over HTTPS calls are received by a PCE core node. The HTTPS (TLS/SSL) portion is terminated on the core node. Subsequently, some intra-cluster communication (between PCE nodes) happens over TLS, and some intra-cluster communication occurs using plaintext protocols. For example, if a REST call needs to be load balanced to the other core node, the REST call is forwarded using HTTP (plaintext). If the other PCE core node is in a different data center, then the REST traffic could potentially could be sent over a insecure (e.g. shared) WAN link. REST calls contain an Authentication header, which has a base64-encoded username:password string. If this plaintext traffic is snooped on the WAN link, then it's possible for the authentication data to be read.

### ILO-PIPGEN for single-node security

NOTE: On newer versions of software ILO-PIPGEN and ILO-VPNGEN are no longer required as they are handled by the software without the need for further configurations. These processes described in the next two sections are for older software versions. That said, there is no reason why you should not harden a system even further at the kernel if that is desired.

When the Illumio Policy Compute Engine (PCE) is deployed on-premise, there are several connections between PCE components running on different nodes. Illumio recommends restricting connectivity to PCE hosts such that connections to these components cannot be made from external sources.

All PCE components listen for connections on TCP and UDP ports in stable, documented ranges. Illumio requires that all PCE nodes be allowed to communicate freely with each other but recommends that no other inbound connections be accepted to ports in these ranges.

Illumio ASP protects critical assets using microsegmentation, and this control can be provided to all other applications using the Virtual Enforcement Node (VEN). However, running the VEN on the hosts running Illumio’s PCE is not supported at this time for operational reasons.

Illumio has provided a utility to help customers configure iptables on each PCE host in such a way that PCE components are protected but other services are unaffected. This utility, called ilo-pipgen (attached below), can be used with new or existing PCE deployments. With this solution, inbound connections to PCE components are permitted only from other PCE hosts and not from any other sources.

To obtain and use instructions for ilo-pipgen [go here](https://support.illumio.com/knowledge-base/articles/Configuring-iptables-on-PCE-hosts-with-ilo-pipgen.html). It can also be obtained from Illumio Support, an Illumio SE or Illumio PS team members.

Here is an example of a script that I generated with a DROP policy (vs ALLOW) that will only allow the outside world to communicate inbound on 22/8443/8444 TCP. And I would remove 22 TCP in a production environment or be more strict with its usage like changing the source network. You can use this script by changing the IP address used to be your own SNC server address.

```
#
# Generated by ./ilo-pipgen on pce.illumio.test
# Tue Apr 20 10:01:16 EDT 2021
#
# Modified April 30, 2021 10:53 by John Westerman to
#   change input policy form ALLOW to DROP and add SSH
#   to the input policy for ACCEPT. All else is DROPPED.
# 

*raw

:PREROUTING ACCEPT
:OUTPUT     ACCEPT

-A PREROUTING -i lo -j NOTRACK
-A OUTPUT     -o lo -j NOTRACK

COMMIT

*filter

:INPUT   DROP
:FORWARD DROP
:OUTPUT  ACCEPT

-A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p icmp -j ACCEPT
-A INPUT -i lo -j ACCEPT

# Allow public ports

-A INPUT -p tcp -m multiport --dports 8443,8444 -m conntrack --ctstate NEW -j ACCEPT

# Allow from 10.8.1.1

-A INPUT -p tcp -s 10.8.1.1 --dport 3100:3600 -m conntrack --ctstate NEW -j ACCEPT
-A INPUT -p tcp -s 10.8.1.1 --dport 5100:6300 -m conntrack --ctstate NEW -j ACCEPT
-A INPUT -p tcp -s 10.8.1.1 --dport 8000:8400 -m conntrack --ctstate NEW -j ACCEPT
-A INPUT -p udp -s 10.8.1.1 --dport 8000:8400 -m conntrack --ctstate NEW -j ACCEPT
-A INPUT -p tcp -s 10.8.1.1 --dport 11200:11300 -m conntrack --ctstate NEW -j ACCEPT
-A INPUT -p tcp -s 10.8.1.1 --dport 24200:25300 -m conntrack --ctstate NEW -j ACCEPT

# Block all other traffic to Illumio ports

-A INPUT -p tcp --dport 3100:3600 -j DROP
-A INPUT -p tcp --dport 5100:6300 -j DROP
-A INPUT -p tcp --dport 8000:8400 -j DROP
-A INPUT -p udp --dport 8000:8400 -j DROP
-A INPUT -p tcp --dport 11200:11300 -j DROP
-A INPUT -p tcp --dport 24200:25300 -j DROP

# Insert custom rules here if desired:

-A INPUT -p tcp -m multiport --dports 22 -m conntrack --ctstate NEW -j ACCEPT

# Done

COMMIT

```

### ILO-VPNGEN for multi-node security

The file ilo-vpngen.sh can be obtained from Illumio Support, an Illumio SE or Illumio PS team member. Also reference the official web site above for all of the details. [Illumio Support for ilo-vpngen.](https://support.illumio.com/knowledge-base/articles/Enabling-encryption-with-ilo-vpngen.html)
