## Classify operation - Business logic for classifying IPs and CIDRs

import ../ipaddress
import std/tables

type
  IpClass* = enum
    ## IP address classification categories
    classPrivate = "private"
    classPublic = "public"
    classLoopback = "loopback"
    classMulticast = "multicast"
    classLinkLocal = "link-local"
    classUnspecified = "unspecified"
    classBroadcast = "broadcast"

  ClassifyResult* = object ## Result of a classify operation
    classifications*: Table[IpClass, seq[IpV4]] ## Map of classification to list of IPs

proc classifyIp*(ip: IpV4): IpClass =
  ## Classify a single IP address
  if ip == UNSPECIFIED:
    return classUnspecified
  elif ip == BROADCAST:
    return classBroadcast
  elif ip.isLoopback():
    return classLoopback
  elif ip.isMulticast():
    return classMulticast
  elif ip.isLinkLocal():
    return classLinkLocal
  elif ip.isPrivate():
    return classPrivate
  else:
    return classPublic

proc classify*(ips: seq[IpV4]): ClassifyResult =
  ## Classify a list of IP addresses
  result.classifications = initTable[IpClass, seq[IpV4]]()

  # Initialize all classification categories
  for class in IpClass:
    result.classifications[class] = @[]

  # Classify each IP
  for ip in ips:
    let ipClass = classifyIp(ip)
    result.classifications[ipClass].add(ip)
