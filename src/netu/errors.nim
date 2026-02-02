## Error types for NETU - Networking Utilities

type
  # ============================================================================
  # IPv4 Errors
  # ============================================================================
  IpV4Error* = object of CatchableError ## Base error type for IPv4-related errors

  MalformedIpV4Error* = object of IpV4Error ## Error for malformed IPv4 strings

  OutOfRangeIpV4Error* = object of IpV4Error ## Error for out-of-range IPv4 values

  # ============================================================================
  # CIDR Errors
  # ============================================================================
  CidrError* = object of CatchableError ## Base error type for CIDR-related errors

  MalformedCidrError* = object of CidrError ## Error for malformed CIDR strings

  InvalidPrefixLenError* = object of CidrError ## Error for invalid prefix length

  HostBitsSetError* = object of CidrError
    ## Error when host bits are set in network address (strict mode)

  # ============================================================================
  # File I/O Errors
  # ============================================================================
  FileError* = object of CatchableError ## Base error type for file-related errors

  FileNotFoundError* = object of FileError ## Error when a file cannot be found

  FilePermissionError* = object of FileError
    ## Error when file permissions prevent read/write

  FileReadError* = object of FileError ## Error when reading a file fails

  FileWriteError* = object of FileError ## Error when writing a file fails

  # ============================================================================
  # Format Errors
  # ============================================================================
  FormatError* = object of CatchableError ## Base error type for format parsing errors

  InvalidFormatError* = object of FormatError ## Error when data format is invalid

  ParseError* = object of FormatError ## Error when parsing data fails

  EmptyDataError* = object of FormatError
    ## Error when input data is empty or contains no valid entries
