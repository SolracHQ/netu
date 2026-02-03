## Presentation layer for contains operation
## Handles formatting and displaying results in different output formats

import ../operations/contains as containsOp
import ../ipaddress
import std/json
import std/strutils
import std/tables
import std/terminal

type ContainsOutputFormat* = enum
  ## Output format options
  formatText = "text" ## Human-readable text output
  formatJson = "json" ## JSON format
  formatTable = "table" ## Pretty-printed table format
  formatNone = "none" ## No output, only exit code

proc formatAsText(containsResult: ContainsResult): string =
  ## Format the contains result as human-readable text
  if containsResult.allContained:
    return "All IPs are contained"
  else:
    var output = "Not all IPs are contained. Missing:\n"
    for ip in containsResult.notContained:
      output.add("  " & $ip & "\n")
    return output.strip()

proc formatAsJson(containsResult: ContainsResult): string =
  ## Format the contains result as JSON
  var jsonObj =
    %*{
      "allContained": containsResult.allContained,
      "notContained": newJArray(),
      "containMap": newJObject(),
    }

  for ip in containsResult.notContained:
    jsonObj["notContained"].add(%($ip))

  for ip, cidrs in containsResult.containMap.pairs:
    var cidrArray = newJArray()
    for cidr in cidrs:
      cidrArray.add(%($cidr))
    jsonObj["containMap"][$ip] = cidrArray

  return $jsonObj

proc formatAsTable(containsResult: ContainsResult): string =
  ## Format the contains result as a table
  var output = ""

  # Calculate maximum widths based on actual content
  var maxIpLen = 2 # "ip" header length
  var maxCidrsLen = 5 # "cidrs" header length

  # Check all IPs
  for ip in containsResult.notContained:
    let ipLen = ($ip).len
    if ipLen > maxIpLen:
      maxIpLen = ipLen

  for ip, cidrs in containsResult.containMap.pairs:
    if cidrs.len == 0:
      continue
    let ipLen = ($ip).len
    if ipLen > maxIpLen:
      maxIpLen = ipLen

    var cidrStrs: seq[string] = @[]
    for cidr in cidrs:
      cidrStrs.add($cidr)
    let cidrsLen = cidrStrs.join(", ").len
    if cidrsLen > maxCidrsLen:
      maxCidrsLen = cidrsLen

  # Cap widths to reasonable maximums
  const maxIpWidth = 39 # Max IPv4 is "255.255.255.255" = 15 chars, add some padding
  const maxCidrsWidth = 100
  const presentWidth = 9 # "present" header length + 2 for padding

  var ipWidth = min(maxIpLen + 2, maxIpWidth)
  var cidrsWidth = min(maxCidrsLen + 2, maxCidrsWidth)

  # Check terminal width if available
  try:
    let termWidth = terminalWidth()
    let totalNeededWidth = ipWidth + presentWidth + cidrsWidth + 7
      # 7 for pipes and spaces
    if totalNeededWidth > termWidth:
      # Reduce cidrs column width to fit
      let availableForCidrs = termWidth - ipWidth - presentWidth - 7
      if availableForCidrs > 20: # Minimum reasonable width
        cidrsWidth = availableForCidrs
  except:
    # If we can't get terminal width, use calculated values
    discard

  # Build header
  output.add(
    "| " & "ip".alignLeft(ipWidth) & " | " & "present".alignLeft(presentWidth) & " | " &
      "cidrs".alignLeft(cidrsWidth) & " |\n"
  )
  output.add(
    "|" & "-".repeat(ipWidth + 2) & "|" & "-".repeat(presentWidth + 2) & "|" &
      "-".repeat(cidrsWidth + 2) & "|\n"
  )

  # Rows for contained IPs
  for ip, cidrs in containsResult.containMap.pairs:
    if cidrs.len == 0:
      continue
    let ipStr = ($ip).alignLeft(ipWidth)
    let presentStr = "yes".alignLeft(presentWidth)
    var cidrStrs: seq[string] = @[]
    for cidr in cidrs:
      cidrStrs.add($cidr)
    let cidrsStr = cidrStrs.join(", ")
    let cidrsFormatted =
      if cidrsStr.len > cidrsWidth:
        cidrsStr[0 .. cidrsWidth - 4] & "..."
      else:
        cidrsStr.alignLeft(cidrsWidth)
    output.add("| " & ipStr & " | " & presentStr & " | " & cidrsFormatted & " |\n")

  # Rows for not contained IPs
  for ip in containsResult.notContained:
    let ipStr = ($ip).alignLeft(ipWidth)
    let presentStr = "no".alignLeft(presentWidth)
    let cidrsStr = "".alignLeft(cidrsWidth)
    output.add("| " & ipStr & " | " & presentStr & " | " & cidrsStr & " |\n")

  return output.strip()

proc presentContainsResult*(
    containsResult: ContainsResult, format: ContainsOutputFormat
): string =
  ## Format the contains operation result according to the specified output format
  ##
  ## Args:
  ##   containsResult: The ContainsResult from the contains operation
  ##   format: The desired output format
  ##
  ## Returns:
  ##   Formatted string representation of the result

  case format
  of formatNone:
    return ""
  of formatText:
    return formatAsText(containsResult)
  of formatJson:
    return formatAsJson(containsResult)
  of formatTable:
    return formatAsTable(containsResult)

proc writeContainsResult*(
    containsResult: ContainsResult, format: ContainsOutputFormat
) =
  ## Write the contains result to stdout in the specified format
  ##
  ## Args:
  ##   containsResult: The ContainsResult from the contains operation
  ##   format: The desired output format

  let output = presentContainsResult(containsResult, format)
  if output.len > 0:
    stdout.writeLine(output)
