# Test suite for IPv4 utility functions
# Tests for bitwise operations, comparisons, and next/prev operations

import unittest
import netu/ipaddress

suite "IPv4 - String representation":
  test "convert IPv4 to string":
    var ip: IpV4
    ip.octets = [192'u8, 168'u8, 1'u8, 1'u8]
    check $ip == "192.168.1.1"

  test "convert 0.0.0.0 to string":
    var ip: IpV4
    ip.octets = [0'u8, 0'u8, 0'u8, 0'u8]
    check $ip == "0.0.0.0"

  test "convert 255.255.255.255 to string":
    var ip: IpV4
    ip.octets = [255'u8, 255'u8, 255'u8, 255'u8]
    check $ip == "255.255.255.255"

suite "IPv4 - Bitwise AND operation":
  test "AND with subnet mask":
    let ip = ipv4("192.168.1.100")
    let mask = ipv4("255.255.255.0")
    let result = ip and mask
    check result == ipv4("192.168.1.0")

  test "AND with 0.0.0.0":
    let ip = ipv4("192.168.1.1")
    let zero = ipv4("0.0.0.0")
    let result = ip and zero
    check result == zero

  test "AND with 255.255.255.255":
    let ip = ipv4("192.168.1.1")
    let ones = ipv4("255.255.255.255")
    let result = ip and ones
    check result == ip

suite "IPv4 - Bitwise OR operation":
  test "OR with host mask":
    let network = ipv4("192.168.1.0")
    let hostmask = ipv4("0.0.0.255")
    let result = network or hostmask
    check result == ipv4("192.168.1.255")

  test "OR with 0.0.0.0":
    let ip = ipv4("192.168.1.1")
    let zero = ipv4("0.0.0.0")
    let result = ip or zero
    check result == ip

  test "OR with itself":
    let ip = ipv4("192.168.1.1")
    let result = ip or ip
    check result == ip

suite "IPv4 - Bitwise NOT operation":
  test "NOT of subnet mask":
    let mask = ipv4("255.255.255.0")
    let result = not mask
    check result == ipv4("0.0.0.255")

  test "NOT of 0.0.0.0":
    let zero = ipv4("0.0.0.0")
    let result = not zero
    check result == ipv4("255.255.255.255")

  test "NOT of 255.255.255.255":
    let ones = ipv4("255.255.255.255")
    let result = not ones
    check result == ipv4("0.0.0.0")

suite "IPv4 - Comparison operators":
  test "less than":
    let ip1 = ipv4("192.168.1.1")
    let ip2 = ipv4("192.168.1.2")
    check ip1 < ip2
    check not (ip2 < ip1)
    check not (ip1 < ip1)

  test "less than or equal":
    let ip1 = ipv4("192.168.1.1")
    let ip2 = ipv4("192.168.1.2")
    check ip1 <= ip2
    check ip1 <= ip1
    check not (ip2 <= ip1)

  test "greater than":
    let ip1 = ipv4("192.168.1.2")
    let ip2 = ipv4("192.168.1.1")
    check ip1 > ip2
    check not (ip2 > ip1)
    check not (ip1 > ip1)

  test "greater than or equal":
    let ip1 = ipv4("192.168.1.2")
    let ip2 = ipv4("192.168.1.1")
    check ip1 >= ip2
    check ip1 >= ip1
    check not (ip2 >= ip1)

  test "compare across octets":
    let ip1 = ipv4("10.255.255.255")
    let ip2 = ipv4("11.0.0.0")
    check ip1 < ip2

suite "IPv4 - Next/Previous operations":
  test "next IP address":
    let ip = ipv4("192.168.1.1")
    check ip.next() == ipv4("192.168.1.2")

  test "next with octet overflow":
    let ip = ipv4("192.168.1.255")
    check ip.next() == ipv4("192.168.2.0")

  test "next at max":
    let ip = ipv4("255.255.255.255")
    check ip.next() == ipv4("0.0.0.0")

  test "previous IP address":
    let ip = ipv4("192.168.1.2")
    check ip.prev() == ipv4("192.168.1.1")

  test "previous with octet underflow":
    let ip = ipv4("192.168.2.0")
    check ip.prev() == ipv4("192.168.1.255")

  test "previous at min":
    let ip = ipv4("0.0.0.0")
    check ip.prev() == ipv4("255.255.255.255")
