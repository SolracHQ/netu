## IPv4 address type and operations

import std/strformat
import std/strutils
import ../errors

export errors

type IpV4* = object
  ## IPv4 address stored as a 32-bit unsigned integer (network byte order)
  value: uint32

# ============================================================================
# Constructors
# ============================================================================

proc ipv4*(value: uint32): IpV4 {.inline.} =
  ## Create an IPv4 address from a 32-bit unsigned integer
  IpV4(value: value)

proc ipv4*(a, b, c, d: uint8): IpV4 {.inline.} =
  ## Create an IPv4 address from four octets
  IpV4(
    value: (uint32(a) shl 24) or (uint32(b) shl 16) or (uint32(c) shl 8) or uint32(d)
  )

proc parseOctet(s: string, ipStr: string, octetIdx: int): uint8 =
  ## Parse a single octet from a string
  try:
    let value = s.parseInt
    if value < 0 or value > 255:
      var err = newException(OutOfRangeIpV4Error, "")
      err.ipString = ipStr
      err.octetIndex = octetIdx
      err.octetValue = value
      err.minValue = 0
      err.maxValue = 255
      raise err
    return uint8(value)
  except ValueError:
    var err = newException(MalformedIpV4Error, "")
    err.ipString = ipStr
    err.octetIndex = octetIdx
    err.octetValue = s
    err.reason = "not a valid number"
    raise err

proc ipv4*(ipStr: string): IpV4 =
  ## Parse an IPv4 address from a string in dotted-decimal notation
  let parts = ipStr.strip().split('.')
  if parts.len != 4:
    var err = newException(MalformedIpV4Error, "")
    err.ipString = ipStr
    err.octetIndex = -1
    err.octetValue = ""
    err.reason = fmt"expected 4 octets, got {parts.len}"
    raise err

  let octets = [
    parseOctet(parts[0], ipStr, 0),
    parseOctet(parts[1], ipStr, 1),
    parseOctet(parts[2], ipStr, 2),
    parseOctet(parts[3], ipStr, 3),
  ]

  result = ipv4(octets[0], octets[1], octets[2], octets[3])

# ============================================================================
# Accessors
# ============================================================================

proc `[]`*(ip: IpV4, index: range[0 .. 3]): uint8 =
  ## Access individual octets by index (0 = most significant)
  case index
  of 0:
    uint8((ip.value shr 24) and 0xFF)
  of 1:
    uint8((ip.value shr 16) and 0xFF)
  of 2:
    uint8((ip.value shr 8) and 0xFF)
  of 3:
    uint8(ip.value and 0xFF)

proc toU32*(ip: IpV4): uint32 {.inline.} =
  ## Convert IPv4 address to uint32
  ip.value

# ============================================================================
# String conversion
# ============================================================================

proc `$`*(ip: IpV4): string =
  ## Convert an IPv4 address to its string representation in dotted-decimal notation
  fmt"{ip[0]}.{ip[1]}.{ip[2]}.{ip[3]}"

# ============================================================================
# Comparison operators
# ============================================================================

proc `==`*(a, b: IpV4): bool {.inline.} =
  ## Compare two IPv4 addresses for equality
  a.value == b.value

proc `<`*(a, b: IpV4): bool {.inline.} =
  ## Compare two IPv4 addresses numerically
  a.value < b.value

proc `<=`*(a, b: IpV4): bool {.inline.} =
  ## Compare two IPv4 addresses numerically
  a.value <= b.value

proc `>`*(a, b: IpV4): bool {.inline.} =
  ## Compare two IPv4 addresses numerically
  a.value > b.value

proc `>=`*(a, b: IpV4): bool {.inline.} =
  ## Compare two IPv4 addresses numerically
  a.value >= b.value

# ============================================================================
# Bitwise operators
# ============================================================================

proc `and`*(a, b: IpV4): IpV4 {.inline.} =
  ## Bitwise AND operation on two IPv4 addresses
  IpV4(value: a.value and b.value)

proc `or`*(a, b: IpV4): IpV4 {.inline.} =
  ## Bitwise OR operation on two IPv4 addresses
  IpV4(value: a.value or b.value)

proc `not`*(ip: IpV4): IpV4 {.inline.} =
  ## Bitwise NOT operation on an IPv4 address
  IpV4(value: not ip.value)

# ============================================================================
# Arithmetic operators
# ============================================================================

proc next*(ip: IpV4): IpV4 {.inline.} =
  ## Get the next IPv4 address (increment by 1), wraps around at 255.255.255.255
  IpV4(value: ip.value + 1)

proc prev*(ip: IpV4): IpV4 {.inline.} =
  ## Get the previous IPv4 address (decrement by 1), wraps around at 0.0.0.0
  IpV4(value: ip.value - 1)
