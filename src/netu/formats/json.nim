## JSON format support for CIDR lists

import std/json
import std/strutils
import std/os
import ../ipaddress
import ../errors

proc loadCidrs*(data: string): seq[Cidr] =
  ## Load CIDRs from JSON string
  ## Expects array of strings: ["192.168.1.0/24", "10.0.0.0/8"]
  ## Single IPs are treated as /32
  if data.strip().len == 0:
    raise newException(EmptyDataError, "JSON data is empty")

  var jsonNode: JsonNode
  try:
    jsonNode = parseJson(data)
  except JsonParsingError as e:
    raise newException(InvalidFormatError, "Invalid JSON format: " & e.msg)

  if jsonNode.kind != JArray:
    raise newException(InvalidFormatError, "Expected JSON array, got " & $jsonNode.kind)

  if jsonNode.len == 0:
    raise newException(EmptyDataError, "JSON array is empty")

  result = newSeq[Cidr]()
  for i, item in jsonNode.elems:
    if item.kind != JString:
      raise newException(ParseError, "Element at index " & $i & " is not a string")

    let cidrStr = item.getStr().strip()
    if cidrStr.len == 0:
      continue

    try:
      if '/' in cidrStr:
        result.add(cidr(cidrStr))
      else:
        result.add(cidr(cidrStr & "/32"))
    except CidrError as e:
      raise
        newException(ParseError, "Failed to parse CIDR at index " & $i & ": " & e.msg)
    except IpV4Error as e:
      raise newException(ParseError, "Failed to parse IP at index " & $i & ": " & e.msg)

proc loadCidrsFromFile*(path: string): seq[Cidr] =
  ## Load CIDRs from JSON file
  ## Single IPs are treated as /32
  if not fileExists(path):
    raise newException(FileNotFoundError, "File not found: " & path)

  var data: string
  try:
    data = readFile(path)
  except IOError as e:
    raise newException(FileReadError, "Failed to read file " & path & ": " & e.msg)
  except OSError as e:
    raise newException(
      FilePermissionError, "Permission denied reading file " & path & ": " & e.msg
    )

  try:
    result = loadCidrs(data)
  except FormatError as e:
    raise newException(FormatError, "Error in file " & path & ": " & e.msg)

proc writeCidrs*(cidrs: seq[Cidr]): string =
  ## Convert CIDRs to JSON string (array of strings)
  var jsonArray = newJArray()
  for c in cidrs:
    jsonArray.add(newJString($c))
  result = $jsonArray

proc writeCidrsToFile*(cidrs: seq[Cidr], path: string) =
  ## Write CIDRs to JSON file
  let jsonStr = writeCidrs(cidrs)
  try:
    writeFile(path, jsonStr)
  except IOError as e:
    raise newException(FileWriteError, "Failed to write file " & path & ": " & e.msg)
  except OSError as e:
    raise newException(
      FilePermissionError, "Permission denied writing file " & path & ": " & e.msg
    )
