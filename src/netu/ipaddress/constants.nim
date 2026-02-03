## Constants - Special IP Addresses and CIDR Ranges

import ipv4
import cidr

# ============================================================================
# Special IP Addresses
# ============================================================================

const
  LOCALHOST* = ipv4(127, 0, 0, 1) ## Localhost IP address (127.0.0.1)

  BROADCAST* = ipv4(255, 255, 255, 255) ## Broadcast address (255.255.255.255)

  UNSPECIFIED* = ipv4(0, 0, 0, 0) ## Unspecified/any address (0.0.0.0)

# ============================================================================
# Common Subnet Masks
# ============================================================================

const
  MASK_8* = ipv4(255, 0, 0, 0) ## /8 subnet mask (255.0.0.0)

  MASK_16* = ipv4(255, 255, 0, 0) ## /16 subnet mask (255.255.0.0)

  MASK_24* = ipv4(255, 255, 255, 0) ## /24 subnet mask (255.255.255.0)

  MASK_30* = ipv4(255, 255, 255, 252) ## /30 subnet mask (255.255.255.252)

  MASK_32* = ipv4(255, 255, 255, 255) ## /32 subnet mask (255.255.255.255)

# ============================================================================
# Standard CIDR Ranges
# ============================================================================

const
  LOOPBACK_CIDR* = cidr(ipv4(127, 0, 0, 0), prefixLen(8)) ## Loopback range (127.0.0.0/8)

  PRIVATE_10* = cidr(ipv4(10, 0, 0, 0), prefixLen(8))
    ## Private range (10.0.0.0/8) RFC 1918

  PRIVATE_172* = cidr(ipv4(172, 16, 0, 0), prefixLen(12))
    ## Private range (172.16.0.0/12) RFC 1918

  PRIVATE_192* = cidr(ipv4(192, 168, 0, 0), prefixLen(16))
    ## Private range (192.168.0.0/16) RFC 1918

  LINK_LOCAL_CIDR* = cidr(ipv4(169, 254, 0, 0), prefixLen(16))
    ## Link-local range (169.254.0.0/16)

  MULTICAST_CIDR* = cidr(ipv4(224, 0, 0, 0), prefixLen(4))
    ## Multicast range (224.0.0.0/4)

  ANY* = cidr(ipv4(0, 0, 0, 0), prefixLen(0)) ## Any/all addresses (0.0.0.0/0)
