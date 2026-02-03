## Presentation layer for IP list outputs
## Handles formatting IP lists in different output formats

import ../ipaddress
import std/json
import std/strutils
import std/terminal

type IpListOutputFormat* = enum
  ## Output format options for IP lists
  formatText = "text" ## Newline-separated text output
  formatCsv = "csv" ## Comma-separated values
  formatJson = "json" ## JSON array format
  formatTable = "table" ## Pretty-printed table format

proc formatAsText(ips: seq[IpV4]): string =
  ## Format IP list as newline-separated text
  var output = ""
  for ip in ips:
    output.add($ip & "\n")
  return output.strip()

proc formatAsCsv(ips: seq[IpV4]): string =
  ## Format IP list as comma-separated values
  var parts: seq[string] = @[]
  for ip in ips:
    parts.add($ip)
  return parts.join(", ")

proc formatAsJson(ips: seq[IpV4]): string =
  ## Format IP list as JSON array
  var jsonArray = newJArray()
  for ip in ips:
    jsonArray.add(%($ip))
  return $jsonArray

proc formatAsTable(ips: seq[IpV4]): string =
  ## Format IP list as a table
  var output = ""

  # Calculate column width based on longest IP
  var maxLen = 2 # "ip" header length
  for ip in ips:
    let ipLen = ($ip).len
    if ipLen > maxLen:
      maxLen = ipLen

  # Add some padding
  let colWidth = maxLen + 2

  # Check terminal width if available
  try:
    let termWidth = terminalWidth()
    let totalWidth = colWidth + 4 # 4 for pipes and spaces
    if totalWidth > termWidth and termWidth > 10:
      # Use terminal width minus borders
      let availableWidth = termWidth - 4
      if availableWidth > 8: # Minimum reasonable width
        maxLen = min(maxLen, availableWidth - 2)
  except:
    discard

  let finalWidth = maxLen + 2

  # Header
  output.add("|" & "-".repeat(finalWidth + 2) & "|\n")
  output.add("| " & "ip".alignLeft(finalWidth) & " |\n")
  output.add("|" & "-".repeat(finalWidth + 2) & "|\n")

  # Rows
  for ip in ips:
    let ipStr = ($ip).alignLeft(finalWidth)
    output.add("| " & ipStr & " |\n")

  output.add("|" & "-".repeat(finalWidth + 2) & "|\n")

  return output.strip()

proc presentIpList*(ips: seq[IpV4], format: IpListOutputFormat): string =
  ## Format an IP list according to the specified output format
  ##
  ## Args:
  ##   ips: The list of IPv4 addresses
  ##   format: The desired output format
  ##
  ## Returns:
  ##   Formatted string representation of the IP list

  case format
  of formatText:
    return formatAsText(ips)
  of formatCsv:
    return formatAsCsv(ips)
  of formatJson:
    return formatAsJson(ips)
  of formatTable:
    return formatAsTable(ips)

proc writeIpList*(ips: seq[IpV4], format: IpListOutputFormat, outputFile: string = "") =
  ## Write an IP list to stdout or file in the specified format
  ##
  ## Args:
  ##   ips: The list of IPv4 addresses
  ##   format: The desired output format
  ##   outputFile: Optional file path to write to (empty = stdout)

  let output = presentIpList(ips, format)
  if output.len > 0:
    if outputFile.len > 0:
      let f = open(outputFile, fmWrite)
      try:
        f.writeLine(output)
      finally:
        f.close()
    else:
      stdout.writeLine(output)
