## CIDR notation for IPv4 networks

import std/strformat
import std/strutils
import ipv4
import ../errors

export errors

type
  PrefixLen* = distinct range[0'u8 .. 32'u8]
    ## Represents a valid prefix length for IPv4 CIDR notation (0-32)

  Cidr* = object ## CIDR notation representation for IPv4 networks
    network*: IpV4 ## The network address
    prefixLen*: PrefixLen ## Prefix length (0-32)

# ============================================================================
# PrefixLen Operations
# ============================================================================

proc prefixLen*(val: uint8): PrefixLen {.raises: [InvalidPrefixLenError].} =
  ## Create a PrefixLen with validation (0-32)
  if val > 32:
    var err = newException(InvalidPrefixLenError, "")
    err.cidrString = ""
    err.prefixValue = int(val)
    err.minValue = 0
    err.maxValue = 32
    raise err
  result = PrefixLen(val)

proc `$`*(p: PrefixLen): string =
  ## Convert PrefixLen to string
  $uint8(p)

proc `==`*(a, b: PrefixLen): bool {.borrow.}

proc `<=`*(a, b: PrefixLen): bool {.borrow.}

proc `<`*(a, b: PrefixLen): bool {.borrow.}

proc `-`*(a, b: PrefixLen): int =
  ## Subtract two PrefixLen values
  int(uint8(a)) - int(uint8(b))

# ============================================================================
# CIDR Constructors
# ============================================================================

proc parsePrefixLen(s: string, cidrStr: string): PrefixLen =
  ## Parse prefix length from a string
  try:
    let value = s.strip().parseInt
    if value < 0 or value > 32:
      var err = newException(InvalidPrefixLenError, "")
      err.cidrString = cidrStr
      err.prefixValue = value
      err.minValue = 0
      err.maxValue = 32
      raise err
    return prefixLen(uint8(value))
  except ValueError:
    var err = newException(InvalidPrefixLenError, "")
    err.cidrString = cidrStr
    err.prefixValue = -1
    err.minValue = 0
    err.maxValue = 32
    raise err

proc hasHostBits*(ip: IpV4, prefixLen: PrefixLen): bool =
  ## Check if an IP address has host bits set for the given prefix length
  if prefixLen.uint8 >= 32:
    return false

  let hostBits = 32 - prefixLen.uint8
  let mask = (1'u32 shl hostBits) - 1
  return (ip.toU32() and mask) != 0

proc maskToNetwork*(ip: IpV4, prefixLen: PrefixLen): IpV4 =
  ## Apply network mask to get the network address (clear host bits)
  if prefixLen.uint8 >= 32:
    return ip

  if prefixLen.uint8 == 0:
    return ipv4(0'u32)

  let networkMask = uint32.high shl (32 - prefixLen.uint8)
  return ipv4(ip.toU32() and networkMask)

proc cidr*(network: IpV4, prefixLen: PrefixLen, strict: bool = false): Cidr =
  ## Create a CIDR block from an IPv4 address and prefix length
  ## Network address is always normalized to clear host bits
  ## If strict is true, raises HostBitsSetError if host bits are set in the input
  if strict and hasHostBits(network, prefixLen):
    var err = newException(HostBitsSetError, "")
    err.cidrString = fmt"{network}/{prefixLen}"
    err.expectedIp = $maskToNetwork(network, prefixLen)
    err.actualIp = $network
    raise err

  result.network = maskToNetwork(network, prefixLen)
  result.prefixLen = prefixLen

proc cidr*(
    cidrStr: string, strict: bool = false
): Cidr {.
    raises:
      [MalformedCidrError, InvalidPrefixLenError, HostBitsSetError, OutOfRangeIpV4Error]
.} =
  ## Parse a CIDR block from a string (e.g., "192.168.1.0/24")
  ## Network address is always normalized to clear host bits
  ## If strict is true, raises HostBitsSetError if host bits are set in the input
  let parts = cidrStr.strip().split('/')
  if parts.len != 2:
    var err = newException(MalformedCidrError, "")
    err.cidrString = cidrStr
    err.reason = "missing '/' separator or wrong format"
    err.underlyingIpError = nil
    raise err

  let ip =
    try:
      ipv4(parts[0])
    except IpV4Error as e:
      var err = newException(MalformedCidrError, "")
      err.cidrString = cidrStr
      err.reason = "invalid IP address part"
      err.underlyingIpError = cast[ref IpV4Error](e)
      raise err

  let prefix = parsePrefixLen(parts[1], cidrStr)

  result = cidr(ip, prefix, strict)

# ============================================================================
# String conversion and comparison
# ============================================================================

proc `$`*(cidr: Cidr): string =
  ## Convert a CIDR block to its string representation (e.g., "192.168.1.0/24")
  fmt"{cidr.network}/{cidr.prefixLen}"

proc `==`*(a, b: Cidr): bool =
  ## Compares two CIDR blocks for equality
  a.network == b.network and a.prefixLen == b.prefixLen

# ============================================================================
# CIDR Properties
# ============================================================================

proc netmask*(cidr: Cidr): IpV4 =
  ## Get the subnet mask for this CIDR block
  if cidr.prefixLen.uint8 == 0:
    return ipv4(0'u32)
  if cidr.prefixLen.uint8 == 32:
    return ipv4(uint32.high)
  let mask = uint32.high shl (32 - cidr.prefixLen.uint8)
  result = ipv4(mask)

proc hostmask*(cidr: Cidr): IpV4 {.inline.} =
  ## Get the host mask (inverse of netmask) for this CIDR block
  not netmask(cidr)

proc networkAddress*(cidr: Cidr): IpV4 {.inline.} =
  ## Get the network address (first IP) of the CIDR block
  cidr.network

proc broadcastAddress*(cidr: Cidr): IpV4 {.inline.} =
  ## Get the broadcast address (last IP) of the CIDR block
  cidr.network or hostmask(cidr)

proc firstUsableHost*(cidr: Cidr): IpV4 {.inline.} =
  ## Get the first usable host IP (network address + 1)
  next(networkAddress(cidr))

proc lastUsableHost*(cidr: Cidr): IpV4 {.inline.} =
  ## Get the last usable host IP (broadcast address - 1)
  prev(broadcastAddress(cidr))

proc numHosts*(cidr: Cidr): uint64 {.inline.} =
  ## Get the total number of IP addresses in this CIDR block
  uint64(1) shl (32 - cidr.prefixLen.uint8)

proc numUsableHosts*(cidr: Cidr): uint64 {.inline.} =
  ## Get the number of usable host IPs (total - 2 for network and broadcast)
  if cidr.prefixLen.uint8 >= 31:
    0'u64
  else:
    numHosts(cidr) - 2

# ============================================================================
# CIDR Operations
# ============================================================================

proc contains*(cidr: Cidr, ip: IpV4): bool =
  ## Check if an IPv4 address is within this CIDR block
  maskToNetwork(ip, cidr.prefixLen) == cidr.network

proc `in`*(ip: IpV4, cidr: Cidr): bool =
  ## Check if an IPv4 address is within this CIDR block (using 'in' operator)
  cidr.contains(ip)

proc overlaps*(a, b: Cidr): bool =
  ## Check if two CIDR blocks overlap
  a.contains(b.network) or b.contains(a.network)

proc supernet*(cidr: Cidr, newPrefixLen: PrefixLen): Cidr =
  ## Get the parent network with a shorter prefix length
  if newPrefixLen.uint8 >= cidr.prefixLen.uint8:
    raise newException(
      InvalidPrefixLenError,
      fmt"New prefix length {newPrefixLen} must be less than current prefix length {cidr.prefixLen}.",
    )
  let supernetNetwork = maskToNetwork(cidr.network, newPrefixLen)
  result = Cidr(network: supernetNetwork, prefixLen: newPrefixLen)

proc subnets*(cidr: Cidr, newPrefixLen: PrefixLen): seq[Cidr] =
  ## Split this CIDR block into smaller subnets with a longer prefix length
  if newPrefixLen.uint8 <= cidr.prefixLen.uint8:
    raise newException(
      InvalidPrefixLenError,
      fmt"New prefix length {newPrefixLen} must be greater than current prefix length {cidr.prefixLen}.",
    )

  let numSubnets = 1'u32 shl (newPrefixLen.uint8 - cidr.prefixLen.uint8)
  let subnetSize = 1'u32 shl (32 - newPrefixLen.uint8)
  result = newSeq[Cidr](numSubnets)

  var currentAddr = cidr.network.toU32()
  for i in 0 ..< numSubnets:
    result[i] = Cidr(network: ipv4(currentAddr), prefixLen: newPrefixLen)
    currentAddr += subnetSize

# ============================================================================
# Iterators
# ============================================================================

iterator hosts*(cidr: Cidr): IpV4 =
  ## Iterate over all IP addresses in the CIDR block
  let firstAddr = cidr.network.toU32()
  let totalHosts = numHosts(cidr)

  for i in 0'u64 ..< totalHosts:
    yield ipv4(uint32(firstAddr + uint32(i)))

iterator usableHosts*(cidr: Cidr): IpV4 =
  ## Iterate over usable host IP addresses (excludes network and broadcast)
  let totalUsable = numUsableHosts(cidr)

  if totalUsable > 0:
    let firstAddr = cidr.network.toU32() + 1
    for i in 0'u64 ..< totalUsable:
      yield ipv4(uint32(firstAddr + uint32(i)))
