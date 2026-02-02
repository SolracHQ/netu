## CLI module - Contains all verb implementations for the NETU command-line interface

import ipaddress
import errors
import formats/[json, csv, text]
import std/sets
import std/os
import std/strutils

# ============================================================================
# Helper Functions
# ============================================================================

proc fail(message: string): int =
  ## Helper function to print error message and return failure code
  stderr.writeLine("Error: " & message)
  return 1

proc loadCidrsFromFiles(paths: seq[string]): HashSet[Cidr] =
  ## Load CIDRs from multiple files, automatically detecting format by extension
  ## Supports .json, .csv, and text formats (default for unknown extensions)
  result = initHashSet[Cidr]()

  for path in paths:
    let (_, _, ext) = splitFile(path)
    let loadedCidrs =
      case ext.toLowerAscii()
      of ".json":
        json.loadCidrsFromFile(path)
      of ".csv":
        csv.loadCidrsFromFile(path)
      else:
        text.loadCidrsFromFile(path)

    for cidr in loadedCidrs:
      result.incl(cidr)

# ============================================================================
# Enums for CLI Options
# ============================================================================

type OutputFormat* = enum
  ## Output format options
  formatText = "text" ## Newline-separated text output
  formatJson = "json" ## JSON format
  formatCsv = "csv" ## CSV format

# ============================================================================
# Verb Implementations
# ============================================================================

proc containsCmd*(input: seq[string] = @[], cidr: seq[string] = @[], ip: string): int =
  ## Check if an IP address is contained in any of the input CIDRs
  ##
  ## Examples:
  ##   netu contains --in cidrs.json --ip "192.168.1.1"
  ##   netu contains --in cidrs.txt --in more.json --ip "10.0.0.5"
  ##   netu contains --cidr "192.168.1.0/24" --ip "192.168.1.1"
  ##   netu contains --cidr "10.0.0.0/8" --cidr "172.16.0.0/12" --ip "172.16.5.100"

  if input.len == 0 and cidr.len == 0:
    return fail("At least one input file (--in) or CIDR (--cidr) must be specified")

  result = 1

  try:
    # Parse the IP address
    let ipAddr = ipaddress.ipv4(ip)

    var cidrs = initHashSet[Cidr]()

    # Load from files if provided
    if input.len > 0:
      cidrs = loadCidrsFromFiles(input)

    # Add inline CIDRs if provided
    for cidrStr in cidr:
      try:
        cidrs.incl(ipaddress.cidr(cidrStr))
      except CidrError as e:
        return fail("Invalid CIDR '" & cidrStr & "': " & e.msg)
      except IpV4Error as e:
        return fail("Invalid IP in CIDR '" & cidrStr & "': " & e.msg)

    # Check if IP is contained in any CIDR
    for c in cidrs:
      if ipAddr in c:
        return 0
  except IpV4Error as e:
    return fail("Invalid IP address '" & ip & "': " & e.msg)
  except FileError as e:
    return fail(e.msg)
  except FormatError as e:
    return fail(e.msg)
  except CatchableError as e:
    return fail(e.msg)

  return 0

proc info*(cidr: string = "", ip: string = "", format: OutputFormat = formatText): int =
  ## Show detailed information about a CIDR block or IP address
  ##
  ## Examples:
  ##   netu info --cidr "192.168.1.0/24"
  ##   netu info --ip "192.168.1.1"
  ##   netu info --cidr "10.0.0.0/8" --format json
  discard
  return 0

proc subnet*(cidr: string = "", prefix: int = 0, output: string = ""): int =
  ## Split a CIDR block into smaller subnets with a longer prefix length
  ##
  ## Examples:
  ##   netu subnet --cidr "10.0.0.0/8" --prefix 16
  ##   netu subnet --cidr "192.168.0.0/16" --prefix 24 --output subnets.json
  discard
  return 0

proc supernet*(input: seq[string] = @[], output: string = ""): int =
  ## Perform supernetting on input CIDRs to combine them into larger blocks
  ##
  ## Examples:
  ##   netu supernet --in cidrs.txt --out grouped.json
  ##   netu supernet --in cidrs.json
  discard
  return 0

proc validate*(
    input: seq[string] = @[], strict: bool = false, quiet: bool = false
): int =
  ## Validate CIDR notation and IP addresses from input files
  ##
  ## Examples:
  ##   netu validate --in cidrs.txt
  ##   netu validate --in cidrs.json --strict
  ##   netu validate --in cidrs.txt --quiet
  discard
  return 0

proc overlaps*(
    input: seq[string] = @[], output: string = "", format: OutputFormat = formatText
): int =
  ## Find all overlapping CIDR blocks in the input
  ##
  ## Examples:
  ##   netu overlaps --in cidrs.json
  ##   netu overlaps --in cidrs.txt --output overlaps.json
  ##   netu overlaps --in cidrs.json --format json
  discard
  return 0

proc equals*(input: seq[string] = @[], strict: bool = false): int =
  ## Check if multiple input files contain the same set of IP addresses/CIDRs
  ##
  ## Examples:
  ##   netu equals --in a.json --in b.json
  ##   netu equals --in cidr1.txt --in cidr2.json --in cidr3.csv
  ##   netu equals --in a.json --in b.json --strict
  discard
  return 0

proc expand*(
    input: seq[string] = @[],
    output: string = "",
    usableOnly: bool = false,
    format: OutputFormat = formatText,
): int =
  ## List all IP addresses contained in the input CIDR blocks
  ##
  ## Examples:
  ##   netu expand --in cidrs.json --out ips.txt
  ##   netu expand --in cidrs.txt --usable-only
  ##   netu expand --in cidrs.json --format json
  discard
  return 0

proc hosts*(
    cidr: string = "",
    usableOnly: bool = false,
    output: string = "",
    format: OutputFormat = formatText,
): int =
  ## List all host IP addresses in a CIDR block
  ##
  ## Examples:
  ##   netu hosts --cidr "192.168.1.0/24"
  ##   netu hosts --cidr "10.0.0.0/24" --usable-only
  ##   netu hosts --cidr "172.16.0.0/16" --output hosts.txt
  ##   netu hosts --cidr "192.168.0.0/24" --format json
  discard
  return 0

proc classify*(
    input: seq[string] = @[], output: string = "", format: OutputFormat = formatText
): int =
  ## Classify IP addresses and CIDR blocks (private, public, loopback, multicast, etc.)
  ##
  ## Examples:
  ##   netu classify --in ips.txt
  ##   netu classify --in cidrs.json --output classified.json
  ##   netu classify --in ips.txt --format json
  discard
  return 0

# ============================================================================
# Main CLI Entry Point
# ============================================================================

import cligen

proc main*() =
  ## Main CLI entry point with multi-dispatch

  const version = "0.1.0"
  clCfg.version = version

  dispatchMulti(
    [
      "multi",
      doc = "\nNETU - Networking Utilities v" & version,
      usage =
        """Usage:
  netu {SUBCMD}  [sub-command options & parameters]

where {SUBCMD} is one of:
  help       print comprehensive or per-cmd help
  contains   Check if an IP address is contained in any of the input CIDRs
  info       Show detailed information about a CIDR block or IP address
  subnet     Split a CIDR block into smaller subnets
  supernet   Perform supernetting on input CIDRs to combine them into larger blocks
  validate   Validate CIDR notation and IP addresses from input files
  overlaps   Find all overlapping CIDR blocks in the input
  equals     Check if multiple input files contain the same set of IP addresses/CIDRs
  expand     List all IP addresses contained in the input CIDR blocks
  hosts      List all host IP addresses in a CIDR block
  classify   Classify IP addresses and CIDR blocks by type

Run "netu help" for comprehensive help.
Run "netu {SUBCMD} --help" for help on a specific subcommand.""",
    ],
    [
      cli.containsCmd,
      cmdName = "contains",
      help = {
        "input": "Input files containing CIDRs (JSON, CSV, or newline-separated)",
        "cidr": "CIDR block(s) to check against (can be specified multiple times)",
        "ip": "IP address to check for containment",
      },
      short = {"input": 'i', "cidr": 'c'},
    ],
    [
      cli.info,
      help = {
        "cidr": "CIDR block to get information about",
        "ip": "IP address to get information about",
        "format": "Output format (table, json)",
      },
      short = {"format": 'f'},
    ],
    [
      cli.subnet,
      help = {
        "cidr": "CIDR block to split into subnets",
        "prefix": "New prefix length for subnets",
        "output": "Output file path",
      },
      short = {"output": 'o'},
    ],
    [
      cli.supernet,
      help = {
        "input": "Input files containing CIDRs to combine", "output": "Output file path"
      },
      short = {"input": 'i', "output": 'o'},
    ],
    [
      cli.validate,
      help = {
        "input": "Input files containing CIDRs/IPs to validate",
        "strict": "Enable strict validation (check host bits)",
        "quiet": "Suppress output, only return exit code",
      },
      short = {"input": 'i', "quiet": 'q'},
    ],
    [
      cli.overlaps,
      help = {
        "input": "Input files containing CIDRs to check for overlaps",
        "output": "Output file path",
        "format": "Output format (table, json)",
      },
      short = {"input": 'i', "output": 'o', "format": 'f'},
    ],
    [
      cli.equals,
      help = {
        "input": "Input files to compare (requires at least 2)",
        "strict": "Strict comparison (CIDR notation must match exactly)",
      },
      short = {"input": 'i'},
    ],
    [
      cli.expand,
      help = {
        "input": "Input files containing CIDRs to expand",
        "output": "Output file path",
        "usableOnly": "Only list usable host IPs (exclude network/broadcast)",
        "format": "Output format (text, json)",
      },
      short = {"input": 'i', "output": 'o', "format": 'f'},
    ],
    [
      cli.hosts,
      help = {
        "cidr": "CIDR block to list hosts from",
        "usableOnly": "Only list usable host IPs (exclude network/broadcast)",
        "output": "Output file path",
        "format": "Output format (text, json)",
      },
      short = {"output": 'o', "format": 'f'},
    ],
    [
      cli.classify,
      help = {
        "input": "Input files containing IPs/CIDRs to classify",
        "output": "Output file path",
        "format": "Output format (table, json)",
      },
      short = {"input": 'i', "output": 'o', "format": 'f'},
    ],
  )
