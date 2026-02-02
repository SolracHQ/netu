# Test suite for IPv4 classification functions
# These tests are for functions to be implemented AFTER CIDR is complete
# Classification functions will use CIDR containment checks

import unittest
import netu/ipaddress

suite "IPv4 - Private address classification":
  test "10.0.0.0/8 range":
    check ipv4("10.0.0.0").isPrivate()
    check ipv4("10.255.255.255").isPrivate()
    check ipv4("10.100.50.25").isPrivate()

  test "172.16.0.0/12 range":
    check ipv4("172.16.0.0").isPrivate()
    check ipv4("172.31.255.255").isPrivate()
    check ipv4("172.20.10.5").isPrivate()

  test "192.168.0.0/16 range":
    check ipv4("192.168.0.0").isPrivate()
    check ipv4("192.168.255.255").isPrivate()
    check ipv4("192.168.1.1").isPrivate()

  test "non-private addresses":
    check not ipv4("8.8.8.8").isPrivate()
    check not ipv4("1.1.1.1").isPrivate()
    check not ipv4("172.15.255.255").isPrivate()
    check not ipv4("172.32.0.0").isPrivate()

suite "IPv4 - Loopback address classification":
  test "loopback addresses":
    check ipv4("127.0.0.1").isLoopback()
    check ipv4("127.0.0.0").isLoopback()
    check ipv4("127.255.255.255").isLoopback()
    check ipv4("127.100.50.25").isLoopback()

  test "non-loopback addresses":
    check not ipv4("128.0.0.0").isLoopback()
    check not ipv4("126.255.255.255").isLoopback()
    check not ipv4("192.168.1.1").isLoopback()

suite "IPv4 - Multicast address classification":
  test "multicast addresses":
    check ipv4("224.0.0.0").isMulticast()
    check ipv4("239.255.255.255").isMulticast()
    check ipv4("230.100.50.25").isMulticast()

  test "non-multicast addresses":
    check not ipv4("223.255.255.255").isMulticast()
    check not ipv4("240.0.0.0").isMulticast()
    check not ipv4("192.168.1.1").isMulticast()

suite "IPv4 - Link-local address classification":
  test "link-local addresses":
    check ipv4("169.254.0.0").isLinkLocal()
    check ipv4("169.254.255.255").isLinkLocal()
    check ipv4("169.254.100.50").isLinkLocal()

  test "non-link-local addresses":
    check not ipv4("169.253.255.255").isLinkLocal()
    check not ipv4("169.255.0.0").isLinkLocal()
    check not ipv4("192.168.1.1").isLinkLocal()
