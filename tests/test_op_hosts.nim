# Test suite for hosts operation

import unittest
import netu/ipaddress
import netu/operations/hosts

suite "Hosts Operation - getAllHosts":
  test "get all hosts from /24 CIDR":
    let testCidr = cidr("192.168.1.0/24")
    let hosts = getAllHosts(testCidr)

    check hosts.len == 256
    check hosts[0] == ipv4("192.168.1.0")
    check hosts[255] == ipv4("192.168.1.255")

  test "get all hosts from /30 CIDR":
    let testCidr = cidr("192.168.1.0/30")
    let hosts = getAllHosts(testCidr)

    check hosts.len == 4
    check hosts[0] == ipv4("192.168.1.0")
    check hosts[1] == ipv4("192.168.1.1")
    check hosts[2] == ipv4("192.168.1.2")
    check hosts[3] == ipv4("192.168.1.3")

  test "get all hosts from /32 CIDR (single host)":
    let testCidr = cidr("192.168.1.5/32")
    let hosts = getAllHosts(testCidr)

    check hosts.len == 1
    check hosts[0] == ipv4("192.168.1.5")

  test "get all hosts from /31 CIDR":
    let testCidr = cidr("192.168.1.0/31")
    let hosts = getAllHosts(testCidr)

    check hosts.len == 2
    check hosts[0] == ipv4("192.168.1.0")
    check hosts[1] == ipv4("192.168.1.1")

  test "get all hosts from /29 CIDR":
    let testCidr = cidr("10.0.0.0/29")
    let hosts = getAllHosts(testCidr)

    check hosts.len == 8
    check hosts[0] == ipv4("10.0.0.0")
    check hosts[7] == ipv4("10.0.0.7")

  test "get all hosts from /28 CIDR":
    let testCidr = cidr("172.16.0.0/28")
    let hosts = getAllHosts(testCidr)

    check hosts.len == 16
    check hosts[0] == ipv4("172.16.0.0")
    check hosts[15] == ipv4("172.16.0.15")

suite "Hosts Operation - getUsableHosts":
  test "get usable hosts from /24 CIDR":
    let testCidr = cidr("192.168.1.0/24")
    let hosts = getUsableHosts(testCidr)

    check hosts.len == 254
    check hosts[0] == ipv4("192.168.1.1")
    check hosts[253] == ipv4("192.168.1.254")
    # Should not include network address (192.168.1.0)
    # Should not include broadcast address (192.168.1.255)

  test "get usable hosts from /30 CIDR":
    let testCidr = cidr("192.168.1.0/30")
    let hosts = getUsableHosts(testCidr)

    check hosts.len == 2
    check hosts[0] == ipv4("192.168.1.1")
    check hosts[1] == ipv4("192.168.1.2")

  test "get usable hosts from /32 CIDR (no usable hosts)":
    let testCidr = cidr("192.168.1.5/32")
    let hosts = getUsableHosts(testCidr)

    check hosts.len == 0

  test "get usable hosts from /31 CIDR (no usable hosts)":
    let testCidr = cidr("192.168.1.0/31")
    let hosts = getUsableHosts(testCidr)

    check hosts.len == 0

  test "get usable hosts from /29 CIDR":
    let testCidr = cidr("10.0.0.0/29")
    let hosts = getUsableHosts(testCidr)

    check hosts.len == 6
    check hosts[0] == ipv4("10.0.0.1")
    check hosts[5] == ipv4("10.0.0.6")

  test "get usable hosts from /28 CIDR":
    let testCidr = cidr("172.16.0.0/28")
    let hosts = getUsableHosts(testCidr)

    check hosts.len == 14
    check hosts[0] == ipv4("172.16.0.1")
    check hosts[13] == ipv4("172.16.0.14")

  test "get usable hosts from /16 CIDR":
    let testCidr = cidr("192.168.0.0/16")
    let hosts = getUsableHosts(testCidr)

    check hosts.len == 65534
    check hosts[0] == ipv4("192.168.0.1")
    check hosts[65533] == ipv4("192.168.255.254")

suite "Hosts Operation - Sequential IPs":
  test "all hosts are sequential":
    let testCidr = cidr("192.168.1.0/28")
    let hosts = getAllHosts(testCidr)

    for i in 0 ..< hosts.len - 1:
      check hosts[i + 1].toU32() == hosts[i].toU32() + 1

  test "usable hosts are sequential":
    let testCidr = cidr("192.168.1.0/28")
    let hosts = getUsableHosts(testCidr)

    for i in 0 ..< hosts.len - 1:
      check hosts[i + 1].toU32() == hosts[i].toU32() + 1

suite "Hosts Operation - Boundary Cases":
  test "first IP in /24 is network address":
    let testCidr = cidr("192.168.1.0/24")
    let allHosts = getAllHosts(testCidr)
    let usableHosts = getUsableHosts(testCidr)

    check allHosts[0] == ipv4("192.168.1.0")
    check usableHosts[0] == ipv4("192.168.1.1")

  test "last IP in /24 is broadcast address":
    let testCidr = cidr("192.168.1.0/24")
    let allHosts = getAllHosts(testCidr)
    let usableHosts = getUsableHosts(testCidr)

    check allHosts[allHosts.len - 1] == ipv4("192.168.1.255")
    check usableHosts[usableHosts.len - 1] == ipv4("192.168.1.254")

  test "usable hosts excludes network and broadcast":
    let testCidr = cidr("10.0.0.0/29")
    let allHosts = getAllHosts(testCidr)
    let usableHosts = getUsableHosts(testCidr)

    check allHosts.len == usableHosts.len + 2
    check ipv4("10.0.0.0") notin usableHosts
    check ipv4("10.0.0.7") notin usableHosts

suite "Hosts Operation - Different Network Sizes":
  test "/27 CIDR (32 addresses)":
    let testCidr = cidr("192.168.1.0/27")
    let allHosts = getAllHosts(testCidr)
    let usableHosts = getUsableHosts(testCidr)

    check allHosts.len == 32
    check usableHosts.len == 30

  test "/26 CIDR (64 addresses)":
    let testCidr = cidr("192.168.1.0/26")
    let allHosts = getAllHosts(testCidr)
    let usableHosts = getUsableHosts(testCidr)

    check allHosts.len == 64
    check usableHosts.len == 62

  test "/25 CIDR (128 addresses)":
    let testCidr = cidr("192.168.1.0/25")
    let allHosts = getAllHosts(testCidr)
    let usableHosts = getUsableHosts(testCidr)

    check allHosts.len == 128
    check usableHosts.len == 126
