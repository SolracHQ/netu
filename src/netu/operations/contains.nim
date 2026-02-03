## Contains operation - Business logic for checking IP containment in CIDRs

import ../ipaddress
import std/sets
import std/tables

type ContainsResult* = object ## Result of a contains operation
  notContained*: seq[IpV4] ## List of IPs that were not contained
  containMap*: Table[IpV4, seq[Cidr]] ## Map of IPs to CIDRs that contain them

proc contains*(cidrs: HashSet[Cidr], ips: HashSet[IpV4]): ContainsResult =
  ## Check if all IPs are contained in at least one CIDR
  ##
  ## Returns:
  ##   ContainsResult with allContained=true if all IPs match at least one CIDR,
  ##   otherwise allContained=false with list of non-matching IPs

  for ip in ips:
    var found = false
    result.containMap[ip] = @[]
    for cidr in cidrs:
      if ip in cidr:
        found = true
        result.containMap[ip].add(cidr)

    if not found:
      result.notContained.add(ip)

proc allContained*(res: ContainsResult): bool =
  ## Check if all IPs were contained in at least one CIDR
  res.notContained.len == 0
