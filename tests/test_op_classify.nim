# Test suite for classify operation

import unittest
import netu/ipaddress
import netu/operations/classify
import std/tables

suite "Classify Operation - Single IP Classification":
  test "classify private IP (192.168.x.x)":
    let testIp = ipv4("192.168.1.1")
    let class = classifyIp(testIp)

    check class == classPrivate

  test "classify private IP (10.x.x.x)":
    let testIp = ipv4("10.5.10.15")
    let class = classifyIp(testIp)

    check class == classPrivate

  test "classify private IP (172.16.x.x)":
    let testIp = ipv4("172.16.5.1")
    let class = classifyIp(testIp)

    check class == classPrivate

  test "classify public IP":
    let testIp = ipv4("8.8.8.8")
    let class = classifyIp(testIp)

    check class == classPublic

  test "classify loopback IP":
    let testIp = ipv4("127.0.0.1")
    let class = classifyIp(testIp)

    check class == classLoopback

  test "classify multicast IP":
    let testIp = ipv4("224.0.0.1")
    let class = classifyIp(testIp)

    check class == classMulticast

  test "classify link-local IP":
    let testIp = ipv4("169.254.1.1")
    let class = classifyIp(testIp)

    check class == classLinkLocal

  test "classify unspecified IP":
    let testIp = ipv4("0.0.0.0")
    let class = classifyIp(testIp)

    check class == classUnspecified

  test "classify broadcast IP":
    let testIp = ipv4("255.255.255.255")
    let class = classifyIp(testIp)

    check class == classBroadcast

suite "Classify Operation - Multiple IPs":
  test "classify mixed IP list":
    let ips =
      @[ipv4("192.168.1.1"), ipv4("8.8.8.8"), ipv4("127.0.0.1"), ipv4("224.0.0.1")]

    let result = classify(ips)

    check result.classifications[classPrivate].len == 1
    check result.classifications[classPublic].len == 1
    check result.classifications[classLoopback].len == 1
    check result.classifications[classMulticast].len == 1

  test "classify all private IPs":
    let ips = @[ipv4("192.168.1.1"), ipv4("10.0.0.1"), ipv4("172.16.0.1")]

    let result = classify(ips)

    check result.classifications[classPrivate].len == 3
    check result.classifications[classPublic].len == 0

  test "classify all public IPs":
    let ips = @[ipv4("8.8.8.8"), ipv4("1.1.1.1"), ipv4("208.67.222.222")]

    let result = classify(ips)

    check result.classifications[classPublic].len == 3
    check result.classifications[classPrivate].len == 0

  test "classify empty IP list":
    let ips: seq[IpV4] = @[]

    let result = classify(ips)

    check result.classifications[classPrivate].len == 0
    check result.classifications[classPublic].len == 0
    check result.classifications[classLoopback].len == 0

suite "Classify Operation - Private IP Ranges":
  test "classify 10.0.0.0/8 range boundaries":
    let ips =
      @[
        ipv4("10.0.0.0"),
        ipv4("10.0.0.1"),
        ipv4("10.255.255.254"),
        ipv4("10.255.255.255"),
      ]

    let result = classify(ips)

    check result.classifications[classPrivate].len == 4

  test "classify 172.16.0.0/12 range boundaries":
    let ips =
      @[
        ipv4("172.16.0.0"),
        ipv4("172.16.0.1"),
        ipv4("172.31.255.254"),
        ipv4("172.31.255.255"),
      ]

    let result = classify(ips)

    check result.classifications[classPrivate].len == 4

  test "classify 192.168.0.0/16 range boundaries":
    let ips =
      @[
        ipv4("192.168.0.0"),
        ipv4("192.168.0.1"),
        ipv4("192.168.255.254"),
        ipv4("192.168.255.255"),
      ]

    let result = classify(ips)

    check result.classifications[classPrivate].len == 4

  test "IPs just outside private ranges are public":
    let ips =
      @[
        ipv4("9.255.255.255"), # Just before 10.0.0.0/8
        ipv4("11.0.0.0"), # Just after 10.0.0.0/8
        ipv4("172.15.255.255"), # Just before 172.16.0.0/12
        ipv4("172.32.0.0"), # Just after 172.16.0.0/12
        ipv4("192.167.255.255"), # Just before 192.168.0.0/16
        ipv4("192.169.0.0"), # Just after 192.168.0.0/16
      ]

    let result = classify(ips)

    check result.classifications[classPublic].len == 6
    check result.classifications[classPrivate].len == 0

suite "Classify Operation - Loopback Range":
  test "classify loopback range boundaries":
    let ips =
      @[
        ipv4("127.0.0.0"),
        ipv4("127.0.0.1"),
        ipv4("127.255.255.254"),
        ipv4("127.255.255.255"),
      ]

    let result = classify(ips)

    check result.classifications[classLoopback].len == 4

  test "IPs just outside loopback range":
    let ips = @[ipv4("126.255.255.255"), ipv4("128.0.0.0")]

    let result = classify(ips)

    check result.classifications[classLoopback].len == 0
    check result.classifications[classPublic].len == 2

suite "Classify Operation - Multicast Range":
  test "classify multicast range boundaries":
    let ips =
      @[
        ipv4("224.0.0.0"),
        ipv4("224.0.0.1"),
        ipv4("239.255.255.254"),
        ipv4("239.255.255.255"),
      ]

    let result = classify(ips)

    check result.classifications[classMulticast].len == 4

  test "IPs just outside multicast range":
    let ips = @[ipv4("223.255.255.255"), ipv4("240.0.0.0")]

    let result = classify(ips)

    check result.classifications[classMulticast].len == 0

suite "Classify Operation - Link-Local Range":
  test "classify link-local range boundaries":
    let ips =
      @[
        ipv4("169.254.0.0"),
        ipv4("169.254.0.1"),
        ipv4("169.254.255.254"),
        ipv4("169.254.255.255"),
      ]

    let result = classify(ips)

    check result.classifications[classLinkLocal].len == 4

  test "IPs just outside link-local range":
    let ips = @[ipv4("169.253.255.255"), ipv4("169.255.0.0")]

    let result = classify(ips)

    check result.classifications[classLinkLocal].len == 0
    check result.classifications[classPublic].len == 2

suite "Classify Operation - Special Addresses":
  test "classify special addresses":
    let ips =
      @[
        ipv4("0.0.0.0"), # Unspecified
        ipv4("255.255.255.255"), # Broadcast
      ]

    let result = classify(ips)

    check result.classifications[classUnspecified].len == 1
    check result.classifications[classBroadcast].len == 1

suite "Classify Operation - Result Structure":
  test "result has all classification categories":
    let ips = @[ipv4("8.8.8.8")]

    let result = classify(ips)

    check result.classifications.hasKey(classPrivate)
    check result.classifications.hasKey(classPublic)
    check result.classifications.hasKey(classLoopback)
    check result.classifications.hasKey(classMulticast)
    check result.classifications.hasKey(classLinkLocal)
    check result.classifications.hasKey(classUnspecified)
    check result.classifications.hasKey(classBroadcast)

  test "empty categories have empty sequences":
    let ips = @[ipv4("8.8.8.8")]

    let result = classify(ips)

    check result.classifications[classPrivate].len == 0
    check result.classifications[classLoopback].len == 0
    check result.classifications[classMulticast].len == 0

  test "IPs appear in correct category":
    let testIp = ipv4("192.168.1.1")
    let ips = @[testIp]

    let result = classify(ips)

    check testIp in result.classifications[classPrivate]
    check testIp notin result.classifications[classPublic]

suite "Classify Operation - Large IP Sets":
  test "classify many IPs efficiently":
    var ips: seq[IpV4] = @[]
    for i in 0 ..< 1000:
      ips.add(ipv4(167772160'u32 + uint32(i))) # 10.0.0.0 and onwards

    let result = classify(ips)

    check result.classifications[classPrivate].len == 1000

  test "classify diverse IP set":
    var ips: seq[IpV4] = @[]
    ips.add(ipv4("192.168.1.1")) # Private
    ips.add(ipv4("8.8.8.8")) # Public
    ips.add(ipv4("127.0.0.1")) # Loopback
    ips.add(ipv4("224.0.0.1")) # Multicast
    ips.add(ipv4("169.254.1.1")) # Link-local
    ips.add(ipv4("0.0.0.0")) # Unspecified
    ips.add(ipv4("255.255.255.255")) # Broadcast

    let result = classify(ips)

    check result.classifications[classPrivate].len == 1
    check result.classifications[classPublic].len == 1
    check result.classifications[classLoopback].len == 1
    check result.classifications[classMulticast].len == 1
    check result.classifications[classLinkLocal].len == 1
    check result.classifications[classUnspecified].len == 1
    check result.classifications[classBroadcast].len == 1
