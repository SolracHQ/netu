# Test suite for CIDR module
# Tests for CIDR parsing, operations, and utilities

import unittest
import netu/ipaddress

suite "CIDR - Parsing from string":
  test "parse valid CIDR notation":
    let cidr = cidr("192.168.1.0/24")
    check cidr.network == ipv4("192.168.1.0")
    check cidr.prefixLen == 24

  test "parse /32 CIDR (single host)":
    let cidr = cidr("192.168.1.1/32")
    check cidr.network == ipv4("192.168.1.1")
    check cidr.prefixLen == 32

  test "parse /0 CIDR (entire internet)":
    let cidr = cidr("0.0.0.0/0")
    check cidr.network == ipv4("0.0.0.0")
    check cidr.prefixLen == 0

  test "parse /8 CIDR":
    let cidr = cidr("10.0.0.0/8")
    check cidr.network == ipv4("10.0.0.0")
    check cidr.prefixLen == 8

  test "parse /16 CIDR":
    let cidr = cidr("172.16.0.0/16")
    check cidr.network == ipv4("172.16.0.0")
    check cidr.prefixLen == 16

suite "CIDR - Creation from IPv4 and prefix":
  test "create CIDR from IPv4 and prefix length":
    let cidr = cidr(ipv4("192.168.1.0"), 24)
    check cidr.network == ipv4("192.168.1.0")
    check cidr.prefixLen == 24

  test "create /32 CIDR":
    let cidr = cidr(ipv4("8.8.8.8"), 32)
    check cidr.prefixLen == 32

suite "CIDR - Network address normalization":
  test "network address is always normalized (host bits cleared)":
    let cidr1 = cidr("192.168.1.100/24")
    check cidr1.network == ipv4("192.168.1.0")

    let cidr2 = cidr(ipv4("10.0.5.25"), 8)
    check cidr2.network == ipv4("10.0.0.0")

    let cidr3 = cidr("172.16.99.88/16")
    check cidr3.network == ipv4("172.16.0.0")

  test "strict mode raises error when host bits are set (string)":
    expect HostBitsSetError:
      discard cidr("192.168.1.100/24", strict = true)

  test "strict mode raises error when host bits are set (IPv4 and prefix)":
    expect HostBitsSetError:
      discard cidr(ipv4("192.168.1.100"), 24, strict = true)

  test "allow correct network address in strict mode":
    let cidr1 = cidr("192.168.1.0/24", strict = true)
    check cidr1.network == ipv4("192.168.1.0")

    let cidr2 = cidr(ipv4("10.0.0.0"), 8, strict = true)
    check cidr2.network == ipv4("10.0.0.0")

  test "strict mode with /32 allows any address":
    let cidr1 = cidr("192.168.1.100/32", strict = true)
    check cidr1.network == ipv4("192.168.1.100")

  test "strict mode with various prefix lengths":
    expect HostBitsSetError:
      discard cidr("172.16.5.1/16", strict = true)

    expect HostBitsSetError:
      discard cidr("10.1.2.3/8", strict = true)

suite "CIDR - String representation":
  test "convert CIDR to string":
    let cidr = cidr("192.168.1.0/24")
    check $cidr == "192.168.1.0/24"

  test "convert /32 to string":
    let cidr = cidr("10.0.0.1/32")
    check $cidr == "10.0.0.1/32"

  test "convert /0 to string":
    let cidr = cidr("0.0.0.0/0")
    check $cidr == "0.0.0.0/0"

suite "CIDR - Equality":
  test "equal CIDR blocks":
    let cidr1 = cidr("192.168.1.0/24")
    let cidr2 = cidr("192.168.1.0/24")
    check cidr1 == cidr2

  test "different networks":
    let cidr1 = cidr("192.168.1.0/24")
    let cidr2 = cidr("192.168.2.0/24")
    check cidr1 != cidr2

  test "different prefix lengths":
    let cidr1 = cidr("192.168.1.0/24")
    let cidr2 = cidr("192.168.1.0/25")
    check cidr1 != cidr2

suite "CIDR - Network address":
  test "get network address for /24":
    let cidr = cidr("192.168.1.0/24")
    check cidr.networkAddress() == ipv4("192.168.1.0")

  test "network address normalizes non-zero host bits":
    let cidr = cidr("192.168.1.100/24")
    check cidr.networkAddress() == ipv4("192.168.1.0")

suite "CIDR - Broadcast address":
  test "broadcast address for /24":
    let cidr = cidr("192.168.1.0/24")
    check cidr.broadcastAddress() == ipv4("192.168.1.255")

  test "broadcast address for /16":
    let cidr = cidr("172.16.0.0/16")
    check cidr.broadcastAddress() == ipv4("172.16.255.255")

  test "broadcast address for /32":
    let cidr = cidr("192.168.1.1/32")
    check cidr.broadcastAddress() == ipv4("192.168.1.1")

  test "broadcast address for /8":
    let cidr = cidr("10.0.0.0/8")
    check cidr.broadcastAddress() == ipv4("10.255.255.255")

suite "CIDR - Usable host range":
  test "first usable host in /24":
    let cidr = cidr("192.168.1.0/24")
    check cidr.firstUsableHost() == ipv4("192.168.1.1")

  test "last usable host in /24":
    let cidr = cidr("192.168.1.0/24")
    check cidr.lastUsableHost() == ipv4("192.168.1.254")

  test "first usable host in /30":
    let cidr = cidr("192.168.1.0/30")
    check cidr.firstUsableHost() == ipv4("192.168.1.1")

  test "last usable host in /30":
    let cidr = cidr("192.168.1.0/30")
    check cidr.lastUsableHost() == ipv4("192.168.1.2")

suite "CIDR - Netmask and Hostmask":
  test "netmask for /24":
    let cidr = cidr("192.168.1.0/24")
    check cidr.netmask() == ipv4("255.255.255.0")

  test "netmask for /16":
    let cidr = cidr("172.16.0.0/16")
    check cidr.netmask() == ipv4("255.255.0.0")

  test "netmask for /8":
    let cidr = cidr("10.0.0.0/8")
    check cidr.netmask() == ipv4("255.0.0.0")

  test "netmask for /32":
    let cidr = cidr("192.168.1.1/32")
    check cidr.netmask() == ipv4("255.255.255.255")

  test "netmask for /0":
    let cidr = cidr("0.0.0.0/0")
    check cidr.netmask() == ipv4("0.0.0.0")

  test "hostmask for /24":
    let cidr = cidr("192.168.1.0/24")
    check cidr.hostmask() == ipv4("0.0.0.255")

  test "hostmask for /16":
    let cidr = cidr("172.16.0.0/16")
    check cidr.hostmask() == ipv4("0.0.255.255")

suite "CIDR - Host count":
  test "number of hosts in /24":
    let cidr = cidr("192.168.1.0/24")
    check cidr.numHosts() == 256

  test "number of usable hosts in /24":
    let cidr = cidr("192.168.1.0/24")
    check cidr.numUsableHosts() == 254

  test "number of hosts in /16":
    let cidr = cidr("172.16.0.0/16")
    check cidr.numHosts() == 65536

  test "number of usable hosts in /16":
    let cidr = cidr("172.16.0.0/16")
    check cidr.numUsableHosts() == 65534

  test "number of hosts in /32":
    let cidr = cidr("192.168.1.1/32")
    check cidr.numHosts() == 1

  test "number of usable hosts in /32":
    let cidr = cidr("192.168.1.1/32")
    check cidr.numUsableHosts() == 0

  test "number of hosts in /30":
    let cidr = cidr("192.168.1.0/30")
    check cidr.numHosts() == 4

  test "number of usable hosts in /30":
    let cidr = cidr("192.168.1.0/30")
    check cidr.numUsableHosts() == 2

suite "CIDR - Contains (using contains)":
  test "IP is in CIDR block":
    let cidr = cidr("192.168.1.0/24")
    check cidr.contains(ipv4("192.168.1.1"))
    check cidr.contains(ipv4("192.168.1.100"))
    check cidr.contains(ipv4("192.168.1.255"))

  test "IP is not in CIDR block":
    let cidr = cidr("192.168.1.0/24")
    check not cidr.contains(ipv4("192.168.2.1"))
    check not cidr.contains(ipv4("192.168.0.255"))
    check not cidr.contains(ipv4("10.0.0.1"))

  test "network address is in CIDR":
    let cidr = cidr("192.168.1.0/24")
    check cidr.contains(ipv4("192.168.1.0"))

  test "broadcast address is in CIDR":
    let cidr = cidr("192.168.1.0/24")
    check cidr.contains(ipv4("192.168.1.255"))

suite "CIDR - Contains (using 'in' operator)":
  test "IP in CIDR using 'in' operator":
    let cidr = cidr("192.168.1.0/24")
    check ipv4("192.168.1.1") in cidr
    check ipv4("192.168.1.100") in cidr
    check ipv4("192.168.1.255") in cidr

  test "IP not in CIDR using 'in' operator":
    let cidr = cidr("192.168.1.0/24")
    check ipv4("192.168.2.1") notin cidr
    check ipv4("10.0.0.1") notin cidr

suite "CIDR - Overlaps":
  test "identical CIDR blocks overlap":
    let cidr1 = cidr("192.168.1.0/24")
    let cidr2 = cidr("192.168.1.0/24")
    check cidr1.overlaps(cidr2)

  test "larger CIDR contains smaller":
    let cidr1 = cidr("192.168.0.0/16")
    let cidr2 = cidr("192.168.1.0/24")
    check cidr1.overlaps(cidr2)
    check cidr2.overlaps(cidr1)

  test "non-overlapping CIDR blocks":
    let cidr1 = cidr("192.168.1.0/24")
    let cidr2 = cidr("192.168.2.0/24")
    check not cidr1.overlaps(cidr2)

  test "adjacent CIDR blocks do not overlap":
    let cidr1 = cidr("192.168.0.0/24")
    let cidr2 = cidr("192.168.1.0/24")
    check not cidr1.overlaps(cidr2)

suite "CIDR - Supernet":
  test "supernet from /24 to /16":
    let cidr = cidr("192.168.1.0/24")
    let super = cidr.supernet(16)
    check super.network == ipv4("192.168.0.0")
    check super.prefixLen == 16

  test "supernet from /24 to /23":
    let cidr = cidr("192.168.1.0/24")
    let super = cidr.supernet(23)
    check super.prefixLen == 23

  test "supernet from /16 to /8":
    let cidr = cidr("172.16.0.0/16")
    let super = cidr.supernet(8)
    check super.network == ipv4("172.0.0.0")
    check super.prefixLen == 8

suite "CIDR - Subnets":
  test "split /24 into /25 subnets":
    let cidr = cidr("192.168.1.0/24")
    let subs = cidr.subnets(25)
    check subs.len == 2
    check subs[0] == cidr("192.168.1.0/25")
    check subs[1] == cidr("192.168.1.128/25")

  test "split /24 into /26 subnets":
    let cidr = cidr("192.168.1.0/24")
    let subs = cidr.subnets(26)
    check subs.len == 4
    check subs[0] == cidr("192.168.1.0/26")
    check subs[1] == cidr("192.168.1.64/26")
    check subs[2] == cidr("192.168.1.128/26")
    check subs[3] == cidr("192.168.1.192/26")

  test "split /22 into /24 subnets":
    let cidr = cidr("192.168.0.0/22")
    let subs = cidr.subnets(24)
    check subs.len == 4
    check subs[0] == cidr("192.168.0.0/24")
    check subs[1] == cidr("192.168.1.0/24")
    check subs[2] == cidr("192.168.2.0/24")
    check subs[3] == cidr("192.168.3.0/24")

suite "CIDR - Iterator hosts":
  test "iterate over /30 hosts":
    let cidr = cidr("192.168.1.0/30")
    var hosts: seq[IpV4] = @[]
    for ip in cidr.hosts():
      hosts.add(ip)
    check hosts.len == 4
    check hosts[0] == ipv4("192.168.1.0")
    check hosts[1] == ipv4("192.168.1.1")
    check hosts[2] == ipv4("192.168.1.2")
    check hosts[3] == ipv4("192.168.1.3")

  test "iterate over /32 hosts":
    let cidr = cidr("192.168.1.1/32")
    var hosts: seq[IpV4] = @[]
    for ip in cidr.hosts():
      hosts.add(ip)
    check hosts.len == 1
    check hosts[0] == ipv4("192.168.1.1")

suite "CIDR - Iterator usableHosts":
  test "iterate over /30 usable hosts":
    let cidr = cidr("192.168.1.0/30")
    var hosts: seq[IpV4] = @[]
    for ip in cidr.usableHosts():
      hosts.add(ip)
    check hosts.len == 2
    check hosts[0] == ipv4("192.168.1.1")
    check hosts[1] == ipv4("192.168.1.2")

  test "iterate over /32 usable hosts (none)":
    let cidr = cidr("192.168.1.1/32")
    var hosts: seq[IpV4] = @[]
    for ip in cidr.usableHosts():
      hosts.add(ip)
    check hosts.len == 0

  test "iterate over /29 usable hosts":
    let cidr = cidr("192.168.1.0/29")
    var hosts: seq[IpV4] = @[]
    for ip in cidr.usableHosts():
      hosts.add(ip)
    check hosts.len == 6
    check hosts[0] == ipv4("192.168.1.1")
    check hosts[5] == ipv4("192.168.1.6")
