## CSV format support for CIDR lists

import std/strutils
import std/os
import ../ipaddress
import ../errors

proc loadCidrs*(data: string): seq[Cidr] =
  ## Load CIDRs from CSV string
  ## Single IPs are treated as /32
  ## Example: 192.168.1.0/24,10.0.0.0/8,172.16.0.0/12
  if data.strip().len == 0:
    raise newException(EmptyDataError, "CSV data is empty")

  result = newSeq[Cidr]()
  let items = data.split(',')

  for i, item in items:
    let trimmed = item.strip()
    if trimmed.len == 0:
      continue

    try:
      if '/' in trimmed:
        result.add(cidr(trimmed))
      else:
        result.add(cidr(trimmed & "/32"))
    except CidrError as e:
      raise newException(
        ParseError, "Failed to parse CIDR at position " & $i & ": " & e.msg
      )
    except IpV4Error as e:
      raise
        newException(ParseError, "Failed to parse IP at position " & $i & ": " & e.msg)

  if result.len == 0:
    raise newException(EmptyDataError, "No valid CIDRs found in CSV data")

proc loadCidrsFromFile*(path: string): seq[Cidr] =
  ## Load CIDRs from CSV file
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
  ## Convert CIDRs to CSV string
  result = ""
  for i, c in cidrs:
    if i > 0:
      result.add(",")
    result.add($c)

proc writeCidrsToFile*(cidrs: seq[Cidr], path: string) =
  ## Write CIDRs to CSV file
  let csvStr = writeCidrs(cidrs)
  try:
    writeFile(path, csvStr)
  except IOError as e:
    raise newException(FileWriteError, "Failed to write file " & path & ": " & e.msg)
  except OSError as e:
    raise newException(
      FilePermissionError, "Permission denied writing file " & path & ": " & e.msg
    )
