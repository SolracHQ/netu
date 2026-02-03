## IP address classification functions

import ipv4
import cidr
import constants

# ============================================================================
# Classification functions
# ============================================================================

proc isPrivate*(ip: IpV4): bool =
  ## Check if the IPv4 address is in a private range (RFC 1918)
  ip in PRIVATE_10 or ip in PRIVATE_172 or ip in PRIVATE_192

proc isLoopback*(ip: IpV4): bool =
  ## Check if the IPv4 address is a loopback address (127.0.0.0/8)
  ip in LOOPBACK_CIDR

proc isMulticast*(ip: IpV4): bool =
  ## Check if the IPv4 address is a multicast address (224.0.0.0/4)
  ip in MULTICAST_CIDR

proc isLinkLocal*(ip: IpV4): bool =
  ## Check if the IPv4 address is a link-local address (169.254.0.0/16)
  ip in LINK_LOCAL_CIDR
