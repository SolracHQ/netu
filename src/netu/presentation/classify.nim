## Presentation layer for classify operation
## Handles formatting and displaying classification results

import ../operations/classify as classifyOp
import ../ipaddress
import std/json
import std/strutils
import std/tables
import std/terminal

type ClassifyOutputFormat* = enum
  ## Output format options for classify
  formatText = "text" ## Human-readable text output
  formatJson = "json" ## JSON format
  formatTable = "table" ## Pretty-printed table format

proc formatAsText(classifyResult: ClassifyResult): string =
  ## Format classification result as text
  var output = ""

  for class, ips in classifyResult.classifications.pairs:
    if ips.len > 0:
      output.add($class & ":\n")
      for ip in ips:
        output.add("  " & $ip & "\n")
      output.add("\n")

  return output.strip()

proc formatAsJson(classifyResult: ClassifyResult): string =
  ## Format classification result as JSON
  var jsonObj = newJObject()

  for class, ips in classifyResult.classifications.pairs:
    var ipArray = newJArray()
    for ip in ips:
      ipArray.add(%($ip))
    jsonObj[$class] = ipArray

  return $jsonObj

proc formatAsTable(classifyResult: ClassifyResult): string =
  ## Format classification result as table
  var output = ""

  # Calculate column widths
  var maxClassLen = 14 # "classification" header length
  var maxIpLen = 2 # "ip" header length

  for class, ips in classifyResult.classifications.pairs:
    let classLen = ($class).len
    if classLen > maxClassLen:
      maxClassLen = classLen

    for ip in ips:
      let ipLen = ($ip).len
      if ipLen > maxIpLen:
        maxIpLen = ipLen

  # Add padding
  let classWidth = maxClassLen + 2
  let ipWidth = maxIpLen + 2

  # Check terminal width if available
  try:
    let termWidth = terminalWidth()
    let totalWidth = classWidth + ipWidth + 7
    if totalWidth > termWidth and termWidth > 20:
      let availableWidth = termWidth - 7
      if availableWidth > 30:
        # Distribute space proportionally
        let classMinWidth = min(maxClassLen + 2, 20)
        let ipMinWidth = availableWidth - classMinWidth
        if ipMinWidth > 10:
          discard # Use calculated widths
  except:
    discard

  # Build header
  output.add(
    "| " & "classification".alignLeft(classWidth) & " | " & "ip".alignLeft(ipWidth) &
      " |\n"
  )
  output.add("|" & "-".repeat(classWidth + 2) & "|" & "-".repeat(ipWidth + 2) & "|\n")

  # Build rows - one row per IP with its classification
  for class, ips in classifyResult.classifications.pairs:
    if ips.len > 0:
      for ip in ips:
        let classStr = ($class).alignLeft(classWidth)
        let ipStr = ($ip).alignLeft(ipWidth)
        output.add("| " & classStr & " | " & ipStr & " |\n")

  return output.strip()

proc presentClassifyResult*(
    classifyResult: ClassifyResult, format: ClassifyOutputFormat
): string =
  ## Format classify result according to the specified output format
  ##
  ## Args:
  ##   classifyResult: The ClassifyResult from the classify operation
  ##   format: The desired output format
  ##
  ## Returns:
  ##   Formatted string representation of the result

  case format
  of formatText:
    return formatAsText(classifyResult)
  of formatJson:
    return formatAsJson(classifyResult)
  of formatTable:
    return formatAsTable(classifyResult)

proc writeClassifyResult*(
    classifyResult: ClassifyResult,
    format: ClassifyOutputFormat,
    outputFile: string = "",
) =
  ## Write classify result to stdout or file in the specified format
  ##
  ## Args:
  ##   classifyResult: The ClassifyResult from the classify operation
  ##   format: The desired output format
  ##   outputFile: Optional file path to write to (empty = stdout)

  let output = presentClassifyResult(classifyResult, format)
  if output.len > 0:
    if outputFile.len > 0:
      let f = open(outputFile, fmWrite)
      try:
        f.writeLine(output)
      finally:
        f.close()
    else:
      stdout.writeLine(output)
