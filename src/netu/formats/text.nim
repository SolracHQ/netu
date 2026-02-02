## Text format support for CIDR lists (newline-separated)

import std/strutils
import std/os
import ../ipaddress
import ../errors

proc loadCidrs*(data: string): seq[Cidr] =
  ## Load CIDRs from newline-separated text string
  ## Each line should contain one CIDR block or IP address
  ## Single IPs are treated as /32
  ## Empty lines and lines starting with # are ignored
  if data.strip().len == 0:
    raise newException(EmptyDataError, "Text data is empty")

  result = newSeq[Cidr]()
  var lineNum = 0
  for line in data.splitLines():
    lineNum += 1
    let trimmed = line.strip()

    if trimmed.len == 0 or trimmed.startsWith("#"):
      continue

    try:
      if '/' in trimmed:
        result.add(cidr(trimmed))
      else:
        result.add(cidr(trimmed & "/32"))
    except CidrError as e:
      raise newException(ParseError, "Line " & $lineNum & ": " & e.msg)
    except IpV4Error as e:
      raise newException(ParseError, "Line " & $lineNum & ": " & e.msg)

  if result.len == 0:
    raise newException(EmptyDataError, "No valid CIDRs found in text data")

proc loadCidrsFromFile*(path: string): seq[Cidr] =
  ## Load CIDRs from text file (newline-separated)
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
  ## Convert CIDRs to newline-separated text string
  result = ""
  for c in cidrs:
    result.add($c)
    result.add("\n")

proc writeCidrsToFile*(cidrs: seq[Cidr], path: string) =
  ## Write CIDRs to text file (newline-separated)
  let textStr = writeCidrs(cidrs)
  try:
    writeFile(path, textStr)
  except IOError as e:
    raise newException(FileWriteError, "Failed to write file " & path & ": " & e.msg)
  except OSError as e:
    raise newException(
      FilePermissionError, "Permission denied writing file " & path & ": " & e.msg
    )
