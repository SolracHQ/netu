## Presentation layer for info operation
## Handles formatting and displaying CIDR and IP information

import ../operations/info as infoOp
import ../ipaddress
import std/json
import std/strutils

type InfoOutputFormat* = enum
  ## Output format options for info
  formatText = "text" ## Human-readable text output
  formatJson = "json" ## JSON format

proc formatCidrAsText(info: CidrInfo): string =
  ## Format CIDR information as text
  var output = ""
  output.add("CIDR: " & $info.cidr & "\n")
  output.add("Network Address: " & $info.networkAddress & "\n")
  output.add("Broadcast Address: " & $info.broadcastAddress & "\n")
  output.add("Netmask: " & $info.netmask & "\n")
  output.add("Hostmask: " & $info.hostmask & "\n")
  output.add("First Usable Host: " & $info.firstUsableHost & "\n")
  output.add("Last Usable Host: " & $info.lastUsableHost & "\n")
  output.add("Total Hosts: " & $info.totalHosts & "\n")
  output.add("Usable Hosts: " & $info.usableHosts & "\n")
  return output.strip()

proc formatCidrAsJson(info: CidrInfo): string =
  ## Format CIDR information as JSON
  var jsonObj =
    %*{
      "cidr": $info.cidr,
      "networkAddress": $info.networkAddress,
      "broadcastAddress": $info.broadcastAddress,
      "netmask": $info.netmask,
      "hostmask": $info.hostmask,
      "firstUsableHost": $info.firstUsableHost,
      "lastUsableHost": $info.lastUsableHost,
      "totalHosts": info.totalHosts,
      "usableHosts": info.usableHosts,
    }
  return $jsonObj

proc formatIpAsText(info: IpInfo): string =
  ## Format IP information as text
  var output = ""
  output.add("IP Address: " & $info.ip & "\n")
  output.add("Decimal: " & $info.decimal & "\n")
  output.add("Binary: " & info.binary & "\n")
  output.add("Private: " & $info.isPrivate & "\n")
  output.add("Loopback: " & $info.isLoopback & "\n")
  output.add("Multicast: " & $info.isMulticast & "\n")
  output.add("Link-Local: " & $info.isLinkLocal & "\n")
  return output.strip()

proc formatIpAsJson(info: IpInfo): string =
  ## Format IP information as JSON
  var jsonObj =
    %*{
      "ip": $info.ip,
      "decimal": info.decimal,
      "binary": info.binary,
      "private": info.isPrivate,
      "loopback": info.isLoopback,
      "multicast": info.isMulticast,
      "linkLocal": info.isLinkLocal,
    }
  return $jsonObj

proc presentCidrInfo*(info: CidrInfo, format: InfoOutputFormat): string =
  ## Format CIDR information according to the specified output format
  case format
  of formatText:
    return formatCidrAsText(info)
  of formatJson:
    return formatCidrAsJson(info)

proc presentIpInfo*(info: IpInfo, format: InfoOutputFormat): string =
  ## Format IP information according to the specified output format
  case format
  of formatText:
    return formatIpAsText(info)
  of formatJson:
    return formatIpAsJson(info)

proc writeCidrInfo*(info: CidrInfo, format: InfoOutputFormat) =
  ## Write CIDR information to stdout
  let output = presentCidrInfo(info, format)
  if output.len > 0:
    stdout.writeLine(output)

proc writeIpInfo*(info: IpInfo, format: InfoOutputFormat) =
  ## Write IP information to stdout
  let output = presentIpInfo(info, format)
  if output.len > 0:
    stdout.writeLine(output)
