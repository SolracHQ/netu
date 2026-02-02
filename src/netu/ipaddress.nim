import strutils
import strformat
import errors

export errors

type
  IpV4* = object ## IPv4 address represented as 4 octets
    octets*: array[4, uint8] ## The four octets of the IPv4 address

  Cidr* = object ## CIDR notation representation for IPv4 networks
    network*: IpV4 ## The network address
    prefixLen*: uint8 ## Prefix length (0-32)

# ============================================================================
# Constants - Special IP Addresses and CIDR Ranges
# ============================================================================

const
  LOCALHOST* = IpV4(octets: [127'u8, 0'u8, 0'u8, 1'u8])
    ## Localhost IP address (127.0.0.1)
  BROADCAST* = IpV4(octets: [255'u8, 255'u8, 255'u8, 255'u8])
    ## Broadcast address (255.255.255.255)
  UNSPECIFIED* = IpV4(octets: [0'u8, 0'u8, 0'u8, 0'u8])
    ## Unspecified/any address (0.0.0.0)

  MASK_8* = IpV4(octets: [255'u8, 0'u8, 0'u8, 0'u8]) ## /8 subnet mask (255.0.0.0)
  MASK_16* = IpV4(octets: [255'u8, 255'u8, 0'u8, 0'u8]) ## /16 subnet mask (255.255.0.0)
  MASK_24* = IpV4(octets: [255'u8, 255'u8, 255'u8, 0'u8])
    ## /24 subnet mask (255.255.255.0)
  MASK_30* = IpV4(octets: [255'u8, 255'u8, 255'u8, 252'u8])
    ## /30 subnet mask (255.255.255.252)
  MASK_32* = IpV4(octets: [255'u8, 255'u8, 255'u8, 255'u8])
    ## /32 subnet mask (255.255.255.255)

  LOOPBACK_CIDR* =
    Cidr(network: IpV4(octets: [127'u8, 0'u8, 0'u8, 0'u8]), prefixLen: 8'u8)
    ## Loopback range (127.0.0.0/8)

  PRIVATE_10* = Cidr(network: IpV4(octets: [10'u8, 0'u8, 0'u8, 0'u8]), prefixLen: 8'u8)
    ## Private range (10.0.0.0/8) RFC 1918
  PRIVATE_172* =
    Cidr(network: IpV4(octets: [172'u8, 16'u8, 0'u8, 0'u8]), prefixLen: 12'u8)
    ## Private range (172.16.0.0/12) RFC 1918
  PRIVATE_192* =
    Cidr(network: IpV4(octets: [192'u8, 168'u8, 0'u8, 0'u8]), prefixLen: 16'u8)
    ## Private range (192.168.0.0/16) RFC 1918

  LINK_LOCAL_CIDR* =
    Cidr(network: IpV4(octets: [169'u8, 254'u8, 0'u8, 0'u8]), prefixLen: 16'u8)
    ## Link-local range (169.254.0.0/16)

  MULTICAST_CIDR* =
    Cidr(network: IpV4(octets: [224'u8, 0'u8, 0'u8, 0'u8]), prefixLen: 4'u8)
    ## Multicast range (224.0.0.0/4)

  ANY* = Cidr(network: IpV4(octets: [0'u8, 0'u8, 0'u8, 0'u8]), prefixLen: 0'u8)
    ## Any/all addresses (0.0.0.0/0)

# ============================================================================
# IPv4 Functions
# ============================================================================

proc `==`*(a, b: IpV4): bool =
  ## Compares two IPv4 addresses for equality
  result =
    a.octets[0] == b.octets[0] and a.octets[1] == b.octets[1] and
    a.octets[2] == b.octets[2] and a.octets[3] == b.octets[3]

proc `$`*(ip: IpV4): string =
  ## Convert an IPv4 address to its string representation in dotted-decimal notation
  result = fmt"{ip.octets[0]}.{ip.octets[1]}.{ip.octets[2]}.{ip.octets[3]}"

proc parseOctet(s: string, ipStr: string): uint8 =
  ## Parse a single octet from a string
  try:
    let value = s.parseInt
    if value < 0 or value > 255:
      raise newException(
        OutOfRangeIpV4Error,
        fmt"Invalid octet '{s}' in IPv4 address: {ipStr}. Must be between 0 and 255.",
      )
    return uint8(value)
  except ValueError:
    raise newException(
      MalformedIpV4Error,
      fmt"Invalid octet '{s}' in IPv4 address: {ipStr}. Must be an integer between 0 and 255.",
    )

proc ipv4*(ipStr: string): IpV4 =
  ## Parse an IPv4 address from a string in dotted-decimal notation
  let parts = ipStr.strip().split('.')
  if parts.len != 4:
    raise newException(
      MalformedIpV4Error,
      fmt"Malformed IPv4 address: {ipStr}. Expected 4 octets, got {parts.len}.",
    )

  for i in 0 .. 3:
    result.octets[i] = parseOctet(parts[i], ipStr)

proc ipv4*(ipInt: SomeInteger): IpV4 =
  ## Convert a 32-bit unsigned integer to an IPv4 address in network byte order
  if ipInt < 0 and ipInt > high(uint32):
    raise newException(
      OutOfRangeIpV4Error,
      fmt"IPv4 integer value {ipInt} is out of range (0 to {high(uint32)}).",
    )
  let ipU32 = uint32(ipInt)
  result.octets[0] = uint8((ipU32 shr 24) and 0xFF)
  result.octets[1] = uint8((ipU32 shr 16) and 0xFF)
  result.octets[2] = uint8((ipU32 shr 8) and 0xFF)
  result.octets[3] = uint8(ipU32 and 0xFF)

proc toU32*(ip: IpV4): uint32 =
  ## Convert an IPv4 address to a 32-bit unsigned integer in network byte order
  result =
    (uint32(ip.octets[0]) shl 24) or (uint32(ip.octets[1]) shl 16) or
    (uint32(ip.octets[2]) shl 8) or uint32(ip.octets[3])

# Bitwise operators
proc `and`*(a, b: IpV4): IpV4 =
  ## Bitwise AND operation on two IPv4 addresses
  result.octets[0] = a.octets[0] and b.octets[0]
  result.octets[1] = a.octets[1] and b.octets[1]
  result.octets[2] = a.octets[2] and b.octets[2]
  result.octets[3] = a.octets[3] and b.octets[3]

proc `or`*(a, b: IpV4): IpV4 =
  ## Bitwise OR operation on two IPv4 addresses
  result.octets[0] = a.octets[0] or b.octets[0]
  result.octets[1] = a.octets[1] or b.octets[1]
  result.octets[2] = a.octets[2] or b.octets[2]
  result.octets[3] = a.octets[3] or b.octets[3]

proc `not`*(ip: IpV4): IpV4 =
  ## Bitwise NOT operation on an IPv4 address
  result.octets[0] = not ip.octets[0]
  result.octets[1] = not ip.octets[1]
  result.octets[2] = not ip.octets[2]
  result.octets[3] = not ip.octets[3]

# Comparison operators
proc `<`*(a, b: IpV4): bool =
  ## Compare two IPv4 addresses numerically
  result = a.toU32() < b.toU32()

proc `<=`*(a, b: IpV4): bool =
  ## Compare two IPv4 addresses numerically
  result = a.toU32() <= b.toU32()

proc `>`*(a, b: IpV4): bool =
  ## Compare two IPv4 addresses numerically
  result = a.toU32() > b.toU32()

proc `>=`*(a, b: IpV4): bool =
  ## Compare two IPv4 addresses numerically
  result = a.toU32() >= b.toU32()

# Utility functions
proc next*(ip: IpV4): IpV4 =
  ## Get the next IPv4 address (increment by 1), wraps around at 255.255.255.255
  result = ipv4(ip.toU32() + 1)

proc prev*(ip: IpV4): IpV4 =
  ## Get the previous IPv4 address (decrement by 1), wraps around at 0.0.0.0
  result = ipv4(ip.toU32() - 1)

# ============================================================================
# CIDR Functions
# ============================================================================

proc `==`*(a, b: Cidr): bool =
  ## Compares two CIDR blocks for equality
  result = a.network == b.network and a.prefixLen == b.prefixLen

proc `$`*(cidr: Cidr): string =
  ## Convert a CIDR block to its string representation (e.g., "192.168.1.0/24")
  result = fmt"{cidr.network}/{cidr.prefixLen}"

proc parsePrefixLen(s: string, cidrStr: string): uint8 =
  ## Parse prefix length from a string
  try:
    let value = s.strip().parseInt
    if value < 0 or value > 32:
      raise newException(
        InvalidPrefixLenError,
        fmt"Invalid prefix length '{value}' in CIDR notation: {cidrStr}. Must be between 0 and 32.",
      )
    return uint8(value)
  except ValueError:
    raise newException(
      InvalidPrefixLenError,
      fmt"Invalid prefix length '{s}' in CIDR notation: {cidrStr}. Must be an integer between 0 and 32.",
    )

proc hasHostBits*(ip: IpV4, prefixLen: uint8): bool =
  ## Check if an IP address has host bits set for the given prefix length
  if prefixLen >= 32:
    return false

  let hostBits = 32 - prefixLen
  let mask = (1'u32 shl hostBits) - 1
  return (ip.toU32() and mask) != 0

proc maskToNetwork*(ip: IpV4, prefixLen: uint8): IpV4 =
  ## Apply network mask to get the network address (clear host bits)
  if prefixLen >= 32:
    return ip

  let networkMask = uint32.high shl (32 - prefixLen)
  return ipv4(ip.toU32() and networkMask)

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
    raise newException(
      MalformedCidrError,
      fmt"Malformed CIDR notation: {cidrStr}. Expected format 'IP/PrefixLength'.",
    )

  let ip =
    try:
      ipv4(parts[0])
    except IpV4Error as e:
      raise newException(
        MalformedCidrError,
        fmt"Malformed IP address in CIDR notation: {cidrStr}. Error: {e.msg}",
      )

  let prefixLen = parsePrefixLen(parts[1], cidrStr)

  if strict and hasHostBits(ip, prefixLen):
    raise newException(
      HostBitsSetError,
      fmt"Host bits are set in network address: {cidrStr}. Expected {maskToNetwork(ip, prefixLen)}/{prefixLen}.",
    )

  result.network = maskToNetwork(ip, prefixLen)
  result.prefixLen = prefixLen

proc cidr*(network: IpV4, prefixLen: uint8, strict: bool = false): Cidr =
  ## Create a CIDR block from an IPv4 address and prefix length
  ## Network address is always normalized to clear host bits
  ## If strict is true, raises HostBitsSetError if host bits are set in the input
  if prefixLen > 32:
    raise newException(
      InvalidPrefixLenError,
      fmt"Invalid prefix length '{prefixLen}'. Must be between 0 and 32.",
    )

  if strict and hasHostBits(network, prefixLen):
    raise newException(
      HostBitsSetError,
      fmt"Host bits are set in network address: {network}/{prefixLen}. Expected {maskToNetwork(network, prefixLen)}/{prefixLen}.",
    )

  result.network = maskToNetwork(network, prefixLen)
  result.prefixLen = prefixLen

proc netmask*(cidr: Cidr): IpV4 =
  ## Get the subnet mask for this CIDR block
  if cidr.prefixLen == 0:
    return UNSPECIFIED
  if cidr.prefixLen == 32:
    return BROADCAST
  let mask = uint32.high shl (32 - cidr.prefixLen)
  result = ipv4(mask)

proc networkAddress*(cidr: Cidr): IpV4 {.inline.} =
  ## Get the network address (first IP) of the CIDR block
  result = cidr.network

proc broadcastAddress*(cidr: Cidr): IpV4 {.inline.} =
  ## Get the broadcast address (last IP) of the CIDR block
  result = cidr.network or not netmask(cidr)

proc firstUsableHost*(cidr: Cidr): IpV4 {.inline.} =
  ## Get the first usable host IP (network address + 1)
  result = next(networkAddress(cidr))

proc lastUsableHost*(cidr: Cidr): IpV4 {.inline.} =
  ## Get the last usable host IP (broadcast address - 1)
  result = prev(broadcastAddress(cidr))

proc hostmask*(cidr: Cidr): IpV4 {.inline.} =
  ## Get the host mask (inverse of netmask) for this CIDR block
  result = not netmask(cidr)

proc numHosts*(cidr: Cidr): uint32 {.inline.} =
  ## Get the total number of IP addresses in this CIDR block
  result = uint32(1) shl (32 - cidr.prefixLen)

proc numUsableHosts*(cidr: Cidr): uint32 {.inline.} =
  ## Get the number of usable host IPs (total - 2 for network and broadcast)
  if cidr.prefixLen >= 31:
    result = 0
  else:
    result = numHosts(cidr) - 2

proc contains*(cidr: Cidr, ip: IpV4): bool =
  ## Check if an IPv4 address is within this CIDR block
  result = maskToNetwork(ip, cidr.prefixLen) == cidr.network

proc `in`*(ip: IpV4, cidr: Cidr): bool =
  ## Check if an IPv4 address is within this CIDR block (using 'in' operator)
  result = cidr.contains(ip)

proc overlaps*(a, b: Cidr): bool =
  ## Check if two CIDR blocks overlap
  # Two CIDR blocks overlap if one contains the network address of the other
  result = a.contains(b.network) or b.contains(a.network)

proc supernet*(cidr: Cidr, newPrefixLen: uint8): Cidr =
  ## Get the parent network with a shorter prefix length
  if newPrefixLen >= cidr.prefixLen:
    raise newException(
      InvalidPrefixLenError,
      fmt"New prefix length {newPrefixLen} must be less than current prefix length {cidr.prefixLen}.",
    )
  let supernetNetwork = maskToNetwork(cidr.network, newPrefixLen)
  result = Cidr(network: supernetNetwork, prefixLen: newPrefixLen)

proc subnets*(cidr: Cidr, newPrefixLen: uint8): seq[Cidr] =
  ## Split this CIDR block into smaller subnets with a longer prefix length
  if newPrefixLen <= cidr.prefixLen:
    raise newException(
      InvalidPrefixLenError,
      fmt"New prefix length {newPrefixLen} must be greater than current prefix length {cidr.prefixLen}.",
    )
  if newPrefixLen > 32:
    raise newException(
      InvalidPrefixLenError,
      fmt"New prefix length {newPrefixLen} is out of range. Must be between 0 and 32.",
    )

  let numSubnets = 1'u32 shl (newPrefixLen - cidr.prefixLen)
  let subnetSize = 1'u32 shl (32 - newPrefixLen)
  result = newSeq[Cidr](numSubnets)

  var currentAddr = cidr.network.toU32()
  for i in 0 ..< numSubnets:
    result[i] = Cidr(network: ipv4(currentAddr), prefixLen: newPrefixLen)
    currentAddr += subnetSize

iterator hosts*(cidr: Cidr): IpV4 =
  ## Iterate over all IP addresses in the CIDR block
  let firstAddr = cidr.network.toU32()
  let totalHosts = numHosts(cidr)

  for i in 0'u32 ..< totalHosts:
    yield ipv4(firstAddr + i)

iterator usableHosts*(cidr: Cidr): IpV4 =
  ## Iterate over usable host IP addresses (excludes network and broadcast)
  let totalUsable = numUsableHosts(cidr)

  if totalUsable > 0:
    let firstAddr = cidr.network.toU32() + 1
    for i in 0'u32 ..< totalUsable:
      yield ipv4(firstAddr + i)

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
