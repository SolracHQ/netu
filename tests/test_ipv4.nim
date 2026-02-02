# Test suite for IPv4 module
# Tests for intoIpv4 function with string and integer inputs

import unittest
import netu/ipaddress

suite "IPv4 - ipv4 from string":
  test "parse valid IPv4 string":
    let ip = ipv4("192.168.1.1")
    check ip.octets == [192'u8, 168'u8, 1'u8, 1'u8]

  test "parse IPv4 with zeros":
    let ip = ipv4("10.0.0.1")
    check ip.octets == [10'u8, 0'u8, 0'u8, 1'u8]

  test "parse maximum IPv4 values":
    let ip = ipv4("255.255.255.255")
    check ip.octets == [255'u8, 255'u8, 255'u8, 255'u8]

  test "parse minimum IPv4 values":
    let ip = ipv4("0.0.0.0")
    check ip.octets == [0'u8, 0'u8, 0'u8, 0'u8]

  test "parse localhost":
    let ip = ipv4("127.0.0.1")
    check ip.octets == [127'u8, 0'u8, 0'u8, 1'u8]

suite "IPv4 - ipv4 from integer":
  test "convert u32 to IPv4 (big endian/network order)":
    # 192.168.1.1 = 0xC0A80101 = 3232235777
    let ip = ipv4(3232235777'u32)
    check ip.octets == [192'u8, 168'u8, 1'u8, 1'u8]

  test "convert zero to IPv4":
    let ip = ipv4(0'u32)
    check ip.octets == [0'u8, 0'u8, 0'u8, 0'u8]

  test "convert max u32 to IPv4":
    let ip = ipv4(4294967295'u32)
    check ip.octets == [255'u8, 255'u8, 255'u8, 255'u8]

  test "convert localhost to IPv4":
    # 127.0.0.1 = 0x7F000001 = 2130706433
    let ip = ipv4(2130706433'u32)
    check ip.octets == [127'u8, 0'u8, 0'u8, 1'u8]

  test "convert 10.0.0.1 to IPv4":
    # 10.0.0.1 = 0x0A000001 = 167772161
    let ip = ipv4(167772161'u32)
    check ip.octets == [10'u8, 0'u8, 0'u8, 1'u8]

suite "IPv4 - toU32 conversion":
  test "convert IPv4 to u32 (network byte order)":
    var ip: IpV4
    ip.octets = [192'u8, 168'u8, 1'u8, 1'u8]
    check ip.toU32() == 3232235777'u32

  test "convert 0.0.0.0 to u32":
    var ip: IpV4
    ip.octets = [0'u8, 0'u8, 0'u8, 0'u8]
    check ip.toU32() == 0'u32

  test "convert 255.255.255.255 to u32":
    var ip: IpV4
    ip.octets = [255'u8, 255'u8, 255'u8, 255'u8]
    check ip.toU32() == 4294967295'u32

suite "IPv4 - round trip conversions":
  test "string -> IPv4 -> u32":
    let ip = ipv4("192.168.1.1")
    check ip.toU32() == 3232235777'u32

  test "u32 -> IPv4 -> u32":
    let ip = ipv4(3232235777'u32)
    check ip.toU32() == 3232235777'u32

  test "u32 -> IPv4 -> string -> IPv4":
    let ip1 = ipv4(3232235777'u32)
    let ipStr = $ip1 # assuming $ operator for string conversion
    let ip2 = ipv4(ipStr)
    check ip1.octets == ip2.octets
