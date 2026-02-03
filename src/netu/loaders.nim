## Loaders module - Load CIDRs and IPs from various sources

import ipaddress
import errors
import formats/[json, csv, text]
import std/sets
import std/os
import std/strutils

proc loadCidrsFromFile*(path: string): seq[Cidr] =
  ## Load CIDRs from a file, automatically detecting format by extension
  ## Supports .json, .csv, and text formats (default for unknown extensions)
  let (_, _, ext) = splitFile(path)

  case ext.toLowerAscii()
  of ".json":
    result = json.loadCidrsFromFile(path)
  of ".csv":
    result = csv.loadCidrsFromFile(path)
  else:
    result = text.loadCidrsFromFile(path)

proc loadCidrsFromFiles*(paths: seq[string]): HashSet[Cidr] =
  ## Load CIDRs from multiple files
  ## Raises: FileError, FormatError
  result = initHashSet[Cidr]()

  for path in paths:
    let cidrs = loadCidrsFromFile(path)
    for cidr in cidrs:
      result.incl(cidr)

proc loadCidrsFromStrings*(cidrStrs: seq[string]): HashSet[Cidr] =
  ## Load CIDRs from string representations
  ## Raises: CidrLoadError
  result = initHashSet[Cidr]()

  for cidrStr in cidrStrs:
    try:
      result.incl(cidr(cidrStr))
    except CidrError as e:
      var err = newException(CidrLoadError, "")
      err.source = "argument:--cidr"
      err.lineNumber = 0
      err.rawValue = cidrStr
      err.underlyingError = cast[ref CidrError](e)
      raise err

proc loadCidrs*(files: seq[string], inlineCidrs: seq[string]): HashSet[Cidr] =
  ## Load CIDRs from both files and inline strings
  ## Raises: FileError, FormatError, CidrError, IpV4Error
  result = initHashSet[Cidr]()

  # Load from files
  if files.len > 0:
    let fileCidrs = loadCidrsFromFiles(files)
    for cidr in fileCidrs:
      result.incl(cidr)

  # Load from inline strings
  if inlineCidrs.len > 0:
    let strCidrs = loadCidrsFromStrings(inlineCidrs)
    for cidr in strCidrs:
      result.incl(cidr)

proc loadIpsFromFile*(path: string): seq[IpV4] =
  ## Load IP addresses from a file, automatically detecting format by extension
  ## IPs in files are treated as /32 CIDRs
  let cidrs = loadCidrsFromFile(path)
  result = newSeq[IpV4]()

  for c in cidrs:
    # Extract the network address from each CIDR
    result.add(c.network)

proc loadIpsFromFiles*(paths: seq[string]): HashSet[IpV4] =
  ## Load IP addresses from multiple files
  ## Raises: FileError, FormatError
  result = initHashSet[IpV4]()

  for path in paths:
    let ips = loadIpsFromFile(path)
    for ip in ips:
      result.incl(ip)

proc loadIpsFromStrings*(ipStrs: seq[string]): HashSet[IpV4] =
  ## Load IP addresses from string representations
  ## Supports both dotted notation and uint32
  ## Raises: IpLoadError
  result = initHashSet[IpV4]()

  for ipStr in ipStrs:
    let trimmed = ipStr.strip()
    # Try to parse as uint32 first, then as dotted notation
    try:
      try:
        let val = parseUInt(trimmed)
        result.incl(ipv4(uint32(val)))
      except ValueError:
        result.incl(ipv4(trimmed))
    except IpV4Error as e:
      var err = newException(IpLoadError, "")
      err.source = "argument:--ip"
      err.lineNumber = 0
      err.rawValue = ipStr
      err.underlyingError = cast[ref IpV4Error](e)
      raise err

proc loadIps*(files: seq[string], inlineIps: seq[string]): HashSet[IpV4] =
  ## Load IP addresses from both files and inline strings
  ## Raises: FileError, FormatError, IpV4Error
  result = initHashSet[IpV4]()

  # Load from files
  if files.len > 0:
    let fileIps = loadIpsFromFiles(files)
    for ip in fileIps:
      result.incl(ip)

  # Load from inline strings
  if inlineIps.len > 0:
    let strIps = loadIpsFromStrings(inlineIps)
    for ip in strIps:
      result.incl(ip)
