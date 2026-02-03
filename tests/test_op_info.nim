# Test suite for info operation

import unittest
import netu/ipaddress
import netu/operations/info

suite "Info Operation - CIDR Info":
  test "basic /24 CIDR info":
    let testCidr = cidr("192.168.1.0/24")
    let info = getCidrInfo(testCidr)

    check info.cidr == testCidr
    check info.networkAddress == ipv4("192.168.1.0")
    check info.broadcastAddress == ipv4("192.168.1.255")
    check info.netmask == ipv4("255.255.255.0")
    check info.hostmask == ipv4("0.0.0.255")
    check info.firstUsableHost == ipv4("192.168.1.1")
    check info.lastUsableHost == ipv4("192.168.1.254")
    check info.totalHosts == 256
    check info.usableHosts == 254

  test "/8 CIDR info":
    let testCidr = cidr("10.0.0.0/8")
    let info = getCidrInfo(testCidr)

    check info.cidr == testCidr
    check info.networkAddress == ipv4("10.0.0.0")
    check info.broadcastAddress == ipv4("10.255.255.255")
    check info.netmask == ipv4("255.0.0.0")
    check info.hostmask == ipv4("0.255.255.255")
    check info.firstUsableHost == ipv4("10.0.0.1")
    check info.lastUsableHost == ipv4("10.255.255.254")
    check info.totalHosts == 16777216
    check info.usableHosts == 16777214

  test "/16 CIDR info":
    let testCidr = cidr("172.16.0.0/16")
    let info = getCidrInfo(testCidr)

    check info.cidr == testCidr
    check info.networkAddress == ipv4("172.16.0.0")
    check info.broadcastAddress == ipv4("172.16.255.255")
    check info.netmask == ipv4("255.255.0.0")
    check info.hostmask == ipv4("0.0.255.255")
    check info.firstUsableHost == ipv4("172.16.0.1")
    check info.lastUsableHost == ipv4("172.16.255.254")
    check info.totalHosts == 65536
    check info.usableHosts == 65534

  test "/32 CIDR info (single host)":
    let testCidr = cidr("192.168.1.1/32")
    let info = getCidrInfo(testCidr)

    check info.cidr == testCidr
    check info.networkAddress == ipv4("192.168.1.1")
    check info.broadcastAddress == ipv4("192.168.1.1")
    check info.netmask == ipv4("255.255.255.255")
    check info.hostmask == ipv4("0.0.0.0")
    check info.totalHosts == 1
    check info.usableHosts == 0

  test "/31 CIDR info (point-to-point)":
    let testCidr = cidr("192.168.1.0/31")
    let info = getCidrInfo(testCidr)

    check info.cidr == testCidr
    check info.networkAddress == ipv4("192.168.1.0")
    check info.broadcastAddress == ipv4("192.168.1.1")
    check info.totalHosts == 2
    check info.usableHosts == 0

  test "/30 CIDR info (small subnet)":
    let testCidr = cidr("192.168.1.0/30")
    let info = getCidrInfo(testCidr)

    check info.cidr == testCidr
    check info.networkAddress == ipv4("192.168.1.0")
    check info.broadcastAddress == ipv4("192.168.1.3")
    check info.firstUsableHost == ipv4("192.168.1.1")
    check info.lastUsableHost == ipv4("192.168.1.2")
    check info.totalHosts == 4
    check info.usableHosts == 2

  test "/0 CIDR info (entire IPv4 space)":
    let testCidr = cidr("0.0.0.0/0")
    let info = getCidrInfo(testCidr)

    check info.cidr == testCidr
    check info.networkAddress == ipv4("0.0.0.0")
    check info.broadcastAddress == ipv4("255.255.255.255")
    check info.netmask == ipv4("0.0.0.0")
    check info.hostmask == ipv4("255.255.255.255")
    check info.totalHosts == 4294967296'u64

suite "Info Operation - IP Info":
  test "private IP info (192.168.x.x)":
    let testIp = ipv4("192.168.1.1")
    let info = getIpInfo(testIp)

    check info.ip == testIp
    check info.decimal == 3232235777'u32
    check info.binary == "11000000101010000000000100000001"
    check info.isPrivate == true
    check info.isLoopback == false
    check info.isMulticast == false
    check info.isLinkLocal == false

  test "private IP info (10.x.x.x)":
    let testIp = ipv4("10.5.10.15")
    let info = getIpInfo(testIp)

    check info.ip == testIp
    check info.decimal == 168102415'u32
    check info.isPrivate == true
    check info.isLoopback == false
    check info.isMulticast == false
    check info.isLinkLocal == false

  test "private IP info (172.16.x.x)":
    let testIp = ipv4("172.16.5.1")
    let info = getIpInfo(testIp)

    check info.ip == testIp
    check info.isPrivate == true
    check info.isLoopback == false
    check info.isMulticast == false
    check info.isLinkLocal == false

  test "public IP info":
    let testIp = ipv4("8.8.8.8")
    let info = getIpInfo(testIp)

    check info.ip == testIp
    check info.decimal == 134744072'u32
    check info.binary == "00001000000010000000100000001000"
    check info.isPrivate == false
    check info.isLoopback == false
    check info.isMulticast == false
    check info.isLinkLocal == false

  test "loopback IP info":
    let testIp = ipv4("127.0.0.1")
    let info = getIpInfo(testIp)

    check info.ip == testIp
    check info.decimal == 2130706433'u32
    check info.binary == "01111111000000000000000000000001"
    check info.isPrivate == false
    check info.isLoopback == true
    check info.isMulticast == false
    check info.isLinkLocal == false

  test "multicast IP info":
    let testIp = ipv4("224.0.0.1")
    let info = getIpInfo(testIp)

    check info.ip == testIp
    check info.isPrivate == false
    check info.isLoopback == false
    check info.isMulticast == true
    check info.isLinkLocal == false

  test "link-local IP info":
    let testIp = ipv4("169.254.1.1")
    let info = getIpInfo(testIp)

    check info.ip == testIp
    check info.isPrivate == false
    check info.isLoopback == false
    check info.isMulticast == false
    check info.isLinkLocal == true

  test "broadcast IP info":
    let testIp = ipv4("255.255.255.255")
    let info = getIpInfo(testIp)

    check info.ip == testIp
    check info.decimal == 4294967295'u32
    check info.binary == "11111111111111111111111111111111"

  test "unspecified IP info":
    let testIp = ipv4("0.0.0.0")
    let info = getIpInfo(testIp)

    check info.ip == testIp
    check info.decimal == 0'u32
    check info.binary == "00000000000000000000000000000000"

suite "Info Operation - Binary Representation":
  test "binary representation has 32 bits":
    let testIp = ipv4("192.168.1.1")
    let info = getIpInfo(testIp)

    check info.binary.len == 32

  test "binary representation for 0.0.0.0":
    let testIp = ipv4("0.0.0.0")
    let info = getIpInfo(testIp)

    check info.binary == "00000000000000000000000000000000"

  test "binary representation for 255.255.255.255":
    let testIp = ipv4("255.255.255.255")
    let info = getIpInfo(testIp)

    check info.binary == "11111111111111111111111111111111"

  test "binary representation for 128.0.0.1":
    let testIp = ipv4("128.0.0.1")
    let info = getIpInfo(testIp)

    check info.binary == "10000000000000000000000000000001"
