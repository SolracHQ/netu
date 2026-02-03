## Hosts operation - Business logic for listing host IPs in a CIDR block

import ../ipaddress

proc getAllHosts*(cidr: Cidr): seq[IpV4] =
  ## Get all IP addresses in a CIDR block
  result = @[]
  for ip in cidr.hosts():
    result.add(ip)

proc getUsableHosts*(cidr: Cidr): seq[IpV4] =
  ## Get usable host IP addresses (excludes network and broadcast)
  result = @[]
  for ip in cidr.usableHosts():
    result.add(ip)
