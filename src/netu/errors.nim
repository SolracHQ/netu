## Error types for NETU - Networking Utilities
##
## This module defines a hierarchical error system with structured data:
## - Low-level errors (IP/CIDR) contain technical details
## - Mid-level errors (Loader) add file/line context
## - High-level errors (CLI) provide user-friendly messages

type
  # ============================================================================
  # IPv4 Errors - Low-level technical errors with specific details
  # ============================================================================
  IpV4Error* = object of CatchableError ## Base error type for IPv4-related errors
    ipString*: string ## The original IP string that caused the error

  MalformedIpV4Error* = object of IpV4Error
    ## Error for malformed IPv4 strings
    ## Contains details about what went wrong during parsing
    octetIndex*: int ## Which octet failed (0-3), or -1 if N/A
    octetValue*: string ## The problematic octet value
    reason*: string ## Why it failed (e.g., "not a number", "contains letters")

  OutOfRangeIpV4Error* = object of IpV4Error ## Error for out-of-range IPv4 values
    octetIndex*: int ## Which octet is out of range (0-3)
    octetValue*: int ## The actual value that was out of range
    minValue*: int ## Minimum allowed value (0)
    maxValue*: int ## Maximum allowed value (255)

  # ============================================================================
  # CIDR Errors - Low-level technical errors for CIDR notation
  # ============================================================================
  CidrError* = object of CatchableError ## Base error type for CIDR-related errors
    cidrString*: string ## The original CIDR string that caused the error

  MalformedCidrError* = object of CidrError ## Error for malformed CIDR strings
    reason*: string ## Why it's malformed
    underlyingIpError*: ref IpV4Error ## If the IP part failed, the underlying error

  InvalidPrefixLenError* = object of CidrError ## Error for invalid prefix length
    prefixValue*: int ## The invalid prefix value
    minValue*: int ## Minimum allowed (0)
    maxValue*: int ## Maximum allowed (32)

  HostBitsSetError* = object of CidrError
    ## Error when host bits are set in network address (strict mode)
    expectedIp*: string ## What the IP should be with host bits cleared
    actualIp*: string ## What was actually provided

  # ============================================================================
  # Loader Errors - Mid-level errors that add file/line context
  # ============================================================================
  LoaderError* = object of CatchableError
    ## Base error for loader-related errors
    ## These errors wrap lower-level errors and add context about where they occurred

  CidrLoadError* = object of LoaderError ## Error loading a CIDR from a file or input
    source*: string ## Source of the error ("file:path" or "argument:--cidr")
    lineNumber*: int ## Line number in file (0 if from argument)
    rawValue*: string ## The raw string that failed to parse
    underlyingError*: ref CidrError ## The underlying CIDR parsing error

  IpLoadError* = object of LoaderError ## Error loading an IP from a file or input
    source*: string ## Source of the error ("file:path" or "argument:--ip")
    lineNumber*: int ## Line number in file (0 if from argument)
    rawValue*: string ## The raw string that failed to parse
    underlyingError*: ref IpV4Error ## The underlying IP parsing error

  # ============================================================================
  # File I/O Errors
  # ============================================================================
  FileError* = object of CatchableError ## Base error type for file-related errors
    filePath*: string ## The file path that caused the error

  FileNotFoundError* = object of FileError ## Error when a file cannot be found

  FilePermissionError* = object of FileError
    ## Error when file permissions prevent read/write

  FileReadError* = object of FileError ## Error when reading a file fails
    reason*: string ## Why the read failed

  FileWriteError* = object of FileError ## Error when writing a file fails
    reason*: string ## Why the write failed

  # ============================================================================
  # Format Errors
  # ============================================================================
  FormatError* = object of CatchableError ## Base error type for format parsing errors
    filePath*: string ## File being parsed (empty if from argument)

  InvalidFormatError* = object of FormatError ## Error when data format is invalid
    detectedFormat*: string ## What format was detected
    expectedFormats*: seq[string] ## What formats are supported

  ParseError* = object of FormatError ## Error when parsing data fails
    lineNumber*: int ## Line number where parsing failed
    reason*: string ## Why parsing failed

  EmptyDataError* = object of FormatError
    ## Error when input data is empty or contains no valid entries

# ============================================================================
# Helper Procs for Creating User-Friendly Messages
# ============================================================================

proc shortMessage*(e: ref MalformedIpV4Error): string =
  ## Generate a short, user-friendly message for malformed IP errors
  "invalid IP address format"

proc shortMessage*(e: ref OutOfRangeIpV4Error): string =
  ## Generate a short, user-friendly message for out-of-range IP errors
  "IP octet out of valid range (0-255)"

proc shortMessage*(e: ref IpV4Error): string =
  ## Generate a short, user-friendly message for base IP errors
  if e of MalformedIpV4Error:
    shortMessage(cast[ref MalformedIpV4Error](e))
  elif e of OutOfRangeIpV4Error:
    shortMessage(cast[ref OutOfRangeIpV4Error](e))
  else:
    "invalid IP address"

proc shortMessage*(e: ref MalformedCidrError): string =
  ## Generate a short, user-friendly message for malformed CIDR errors
  if e.underlyingIpError != nil:
    "malformed IP address in CIDR notation"
  else:
    "malformed CIDR notation"

proc shortMessage*(e: ref InvalidPrefixLenError): string =
  ## Generate a short, user-friendly message for invalid prefix errors
  "invalid CIDR prefix length (must be 0-32)"

proc shortMessage*(e: ref HostBitsSetError): string =
  ## Generate a short, user-friendly message for host bits errors
  "CIDR has host bits set (use strict mode to validate)"

proc shortMessage*(e: ref CidrError): string =
  ## Generate a short, user-friendly message for base CIDR errors
  if e of MalformedCidrError:
    shortMessage(cast[ref MalformedCidrError](e))
  elif e of InvalidPrefixLenError:
    shortMessage(cast[ref InvalidPrefixLenError](e))
  elif e of HostBitsSetError:
    shortMessage(cast[ref HostBitsSetError](e))
  else:
    "invalid CIDR notation"

proc shortMessage*(e: ref CidrLoadError): string =
  ## Generate a user-friendly message for CIDR load errors
  if e.lineNumber > 0:
    result = "Error in " & e.source & " at line " & $e.lineNumber
  else:
    result = "Error at argument \"--cidr"
    if e.rawValue.len > 0:
      result &= " '" & e.rawValue & "'"
    result &= "\""

  if e.underlyingError != nil:
    result &= ": " & shortMessage(e.underlyingError)
  else:
    result &= ": failed to parse CIDR"

proc shortMessage*(e: ref IpLoadError): string =
  ## Generate a user-friendly message for IP load errors
  if e.lineNumber > 0:
    result = "Error in " & e.source & " at line " & $e.lineNumber
  else:
    result = "Error at argument \"--ip"
    if e.rawValue.len > 0:
      result &= " '" & e.rawValue & "'"
    result &= "\""

  if e.underlyingError != nil:
    result &= ": " & shortMessage(e.underlyingError)
  else:
    result &= ": failed to parse IP address"

proc detailedMessage*(e: ref MalformedIpV4Error): string =
  ## Generate a detailed technical message (for --verbose mode)
  result = "Malformed IPv4 address: " & e.ipString
  if e.octetIndex >= 0:
    result &= "\n  Octet " & $e.octetIndex & " ('" & e.octetValue & "'): " & e.reason

proc detailedMessage*(e: ref OutOfRangeIpV4Error): string =
  ## Generate a detailed technical message (for --verbose mode)
  "IPv4 octet " & $e.octetIndex & " out of range: " & $e.octetValue & " (must be " &
    $e.minValue & "-" & $e.maxValue & ")"

proc detailedMessage*(e: ref IpV4Error): string =
  ## Generate a detailed technical message for base IP errors
  if e of MalformedIpV4Error:
    detailedMessage(cast[ref MalformedIpV4Error](e))
  elif e of OutOfRangeIpV4Error:
    detailedMessage(cast[ref OutOfRangeIpV4Error](e))
  else:
    "IPv4 error: " & e.msg

proc detailedMessage*(e: ref MalformedCidrError): string =
  ## Generate a detailed technical message (for --verbose mode)
  result = "Malformed CIDR: " & e.cidrString & "\n  " & e.reason
  if e.underlyingIpError != nil:
    result &= "\n  " & detailedMessage(e.underlyingIpError)

proc detailedMessage*(e: ref InvalidPrefixLenError): string =
  ## Generate a detailed technical message (for --verbose mode)
  "Invalid prefix length: " & $e.prefixValue & " (must be " & $e.minValue & "-" &
    $e.maxValue & ")"
