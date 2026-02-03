# Test suite for contains operation

import unittest
import netu/ipaddress
import netu/operations/contains
import std/sets
import std/tables

suite "Contains Operation - Basic Functionality":
  test "all IPs contained in single CIDR":
    let cidrs = toHashSet([cidr("192.168.1.0/24")])
    let ips =
      toHashSet([ipv4("192.168.1.1"), ipv4("192.168.1.100"), ipv4("192.168.1.254")])

    let result = contains(cidrs, ips)

    check result.allContained == true
    check result.notContained.len == 0
    check result.containMap.len == 3

  test "no IPs contained":
    let cidrs = toHashSet([cidr("192.168.1.0/24")])
    let ips = toHashSet([ipv4("10.0.0.1"), ipv4("172.16.0.1")])

    let result = contains(cidrs, ips)

    check result.allContained == false
    check result.notContained.len == 2
    check ipv4("10.0.0.1") in result.notContained
    check ipv4("172.16.0.1") in result.notContained

  test "some IPs contained, some not":
    let cidrs = toHashSet([cidr("192.168.1.0/24")])
    let ips = toHashSet([ipv4("192.168.1.1"), ipv4("10.0.0.1")])

    let result = contains(cidrs, ips)

    check result.allContained == false
    check result.notContained.len == 1
    check ipv4("10.0.0.1") in result.notContained
    check result.containMap.hasKey(ipv4("192.168.1.1"))

  test "IP contained in multiple CIDRs":
    let cidrs = toHashSet([cidr("192.168.0.0/16"), cidr("192.168.1.0/24")])
    let ips = toHashSet([ipv4("192.168.1.1")])

    let result = contains(cidrs, ips)

    check result.allContained == true
    check result.notContained.len == 0
    check result.containMap[ipv4("192.168.1.1")].len == 2

  test "empty IP set":
    let cidrs = toHashSet([cidr("192.168.1.0/24")])
    let ips: HashSet[IpV4] = initHashSet[IpV4]()

    let result = contains(cidrs, ips)

    check result.allContained == true
    check result.notContained.len == 0

suite "Contains Operation - Edge Cases":
  test "IP at network boundary":
    let cidrs = toHashSet([cidr("192.168.1.0/24")])
    let ips = toHashSet(
      [
        ipv4("192.168.1.0"), # network address
        ipv4("192.168.1.255"), # broadcast address
      ]
    )

    let result = contains(cidrs, ips)

    check result.allContained == true
    check result.notContained.len == 0

  test "IP just outside CIDR range":
    let cidrs = toHashSet([cidr("192.168.1.0/24")])
    let ips = toHashSet(
      [
        ipv4("192.168.0.255"), # one below
        ipv4("192.168.2.0"), # one above
      ]
    )

    let result = contains(cidrs, ips)

    check result.allContained == false
    check result.notContained.len == 2

  test "/32 CIDR contains exact IP":
    let cidrs = toHashSet([cidr("192.168.1.1/32")])
    let ips = toHashSet([ipv4("192.168.1.1")])

    let result = contains(cidrs, ips)

    check result.allContained == true
    check result.notContained.len == 0

  test "/32 CIDR does not contain different IP":
    let cidrs = toHashSet([cidr("192.168.1.1/32")])
    let ips = toHashSet([ipv4("192.168.1.2")])

    let result = contains(cidrs, ips)

    check result.allContained == false
    check result.notContained.len == 1

  test "/0 CIDR contains all IPs":
    let cidrs = toHashSet([cidr("0.0.0.0/0")])
    let ips = toHashSet(
      [ipv4("0.0.0.0"), ipv4("127.0.0.1"), ipv4("192.168.1.1"), ipv4("255.255.255.255")]
    )

    let result = contains(cidrs, ips)

    check result.allContained == true
    check result.notContained.len == 0

suite "Contains Operation - Multiple CIDRs":
  test "IPs distributed across multiple CIDRs":
    let cidrs =
      toHashSet([cidr("10.0.0.0/8"), cidr("172.16.0.0/12"), cidr("192.168.0.0/16")])
    let ips = toHashSet([ipv4("10.1.1.1"), ipv4("172.16.5.5"), ipv4("192.168.100.100")])

    let result = contains(cidrs, ips)

    check result.allContained == true
    check result.notContained.len == 0

  test "overlapping CIDRs":
    let cidrs = toHashSet(
      [cidr("192.168.0.0/16"), cidr("192.168.1.0/24"), cidr("192.168.1.0/28")]
    )
    let ips = toHashSet([ipv4("192.168.1.5")])

    let result = contains(cidrs, ips)

    check result.allContained == true
    # IP should be in all three CIDRs
    check result.containMap[ipv4("192.168.1.5")].len == 3

  test "non-overlapping CIDRs with gaps":
    let cidrs = toHashSet([cidr("192.168.1.0/24"), cidr("192.168.3.0/24")])
    let ips = toHashSet(
      [
        ipv4("192.168.1.1"),
        ipv4("192.168.2.1"), # in the gap
        ipv4("192.168.3.1"),
      ]
    )

    let result = contains(cidrs, ips)

    check result.allContained == false
    check result.notContained.len == 1
    check ipv4("192.168.2.1") in result.notContained

suite "Contains Operation - Contain Map":
  test "containMap has entries for all contained IPs":
    let cidrs = toHashSet([cidr("192.168.1.0/24")])
    let ips = toHashSet([ipv4("192.168.1.1"), ipv4("192.168.1.2")])

    let result = contains(cidrs, ips)

    check result.containMap.hasKey(ipv4("192.168.1.1"))
    check result.containMap.hasKey(ipv4("192.168.1.2"))
    check result.containMap[ipv4("192.168.1.1")].len > 0
    check result.containMap[ipv4("192.168.1.2")].len > 0

  test "containMap shows correct CIDR for each IP":
    let testCidr = cidr("192.168.1.0/24")
    let cidrs = toHashSet([testCidr])
    let ips = toHashSet([ipv4("192.168.1.1")])

    let result = contains(cidrs, ips)

    check result.containMap[ipv4("192.168.1.1")][0] == testCidr
