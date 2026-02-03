## Info operation - Business logic for getting IP and CIDR information

import ../ipaddress
import std/strutils

type
  CidrInfo* = object ## Information about a CIDR block
    cidr*: Cidr
    networkAddress*: IpV4
    broadcastAddress*: IpV4
    netmask*: IpV4
    hostmask*: IpV4
    firstUsableHost*: IpV4
    lastUsableHost*: IpV4
    totalHosts*: uint64
    usableHosts*: uint64

  IpInfo* = object ## Information about an IP address
    ip*: IpV4
    decimal*: uint32
    binary*: string
    isPrivate*: bool
    isLoopback*: bool
    isMulticast*: bool
    isLinkLocal*: bool

proc getCidrInfo*(cidr: Cidr): CidrInfo =
  ## Get detailed information about a CIDR block
  result.cidr = cidr
  result.networkAddress = cidr.networkAddress()
  result.broadcastAddress = cidr.broadcastAddress()
  result.netmask = cidr.netmask()
  result.hostmask = cidr.hostmask()
  result.firstUsableHost = cidr.firstUsableHost()
  result.lastUsableHost = cidr.lastUsableHost()
  result.totalHosts = cidr.numHosts()
  result.usableHosts = cidr.numUsableHosts()

proc getIpInfo*(ip: IpV4): IpInfo =
  ## Get detailed information about an IP address
  result.ip = ip
  result.decimal = ip.toU32()
  result.binary = BiggestInt(ip.toU32()).toBin(32)
  result.isPrivate = ip.isPrivate()
  result.isLoopback = ip.isLoopback()
  result.isMulticast = ip.isMulticast()
  result.isLinkLocal = ip.isLinkLocal()
