## CLI module - Presentation layer for NETU command-line interface
## Only handles parsing inputs and formatting outputs

import ipaddress
import loaders
import errors
import operations/contains as containsOp
import operations/info as infoOp
import operations/hosts as hostsOp
import operations/classify as classifyOp
import presentation/contains as containsPresentation
import presentation/info as infoPresentation
export infoPresentation.InfoOutputFormat
import presentation/iplist
import presentation/classify as classifyPresentation
export classifyPresentation.ClassifyOutputFormat
import std/strutils
import std/sets

# ============================================================================
# Helper Functions
# ============================================================================

proc fail(message: string): int =
  ## Helper function to print error message and return failure code
  stderr.writeLine("Error: " & message)
  return 1

template quietEcho(quiet: bool, message: varargs[string, `$`]) =
  ## Helper template to conditionally echo messages based on quiet flag
  if not quiet:
    for msg in message:
      stdout.write(msg)
    stdout.writeLine("")

# ============================================================================
# Enums for CLI Options
# ============================================================================

# Re-export OutputFormat from presentation layer
import presentation/contains except writeContainsResult, presentContainsResult

# ============================================================================
# Verb Implementations
# ============================================================================

proc containsCmd*(
    cidrs: seq[string] = @[],
    cidr: seq[string] = @[],
    ips: seq[string] = @[],
    ip: seq[string] = @[],
    format: ContainsOutputFormat = formatTable,
): int =
  ## Check if all IP addresses are contained in at least one CIDR
  ##
  ## Examples:
  ##   netu contains --cidrs cidrs.json --ip "192.168.1.1"
  ##   netu contains --cidr "192.168.1.0/24" --ip "192.168.1.1"
  ##   netu contains --cidrs cidrs.txt --ips ips.json
  ##   netu contains --cidr "10.0.0.0/8" --cidr "172.16.0.0/12" --ip "172.16.5.100" --ip "10.5.5.5"
  ##   netu contains --cidr "192.168.0.0/16" --ip "192.168.1.1" --format json

  # Parse and validate arguments
  if cidrs.len == 0 and cidr.len == 0:
    return fail("At least one CIDR must be specified (--cidrs or --cidr)")

  if ips.len == 0 and ip.len == 0:
    return fail("At least one IP must be specified (--ips or --ip)")

  try:
    # Load CIDRs from files and inline strings
    let cidrSet = loadCidrs(cidrs, cidr)

    # Load IPs from files and inline strings
    let ipSet = loadIps(ips, ip)

    # Call logic function
    let res = containsOp.contains(cidrSet, ipSet)

    # Call presentation with results
    containsPresentation.writeContainsResult(res, format)

    # Return exit code based on result
    if res.allContained:
      return 0
    else:
      return 1
  except CidrLoadError as e:
    return fail(shortMessage(e))
  except IpLoadError as e:
    return fail(shortMessage(e))
  except FileError as e:
    return fail("File error: " & e.filePath)
  except FormatError as e:
    return fail("Format error in " & e.filePath)
  except CatchableError as e:
    return fail("Unexpected error: " & e.msg)

proc info*(
    cidr: string = "", ip: string = "", format: InfoOutputFormat = formatText
): int =
  ## Show detailed information about a CIDR block or IP address
  ##
  ## Examples:
  ##   netu info --cidr "192.168.1.0/24"
  ##   netu info --ip "192.168.1.1"
  ##   netu info --ip "192.168.1.1" --format json

  # Parse and validate arguments
  if cidr.len == 0 and ip.len == 0:
    return fail("Either --cidr or --ip must be specified")

  if cidr.len > 0 and ip.len > 0:
    return fail("Cannot specify both --cidr and --ip")

  try:
    if cidr.len > 0:
      # Parse CIDR
      let cidrBlock = ipaddress.cidr(cidr)

      # Call logic function
      let cidrInfo = infoOp.getCidrInfo(cidrBlock)

      # Call presentation with results
      infoPresentation.writeCidrInfo(cidrInfo, format)
    else:
      # Parse IP
      let ipAddr = ipaddress.ipv4(ip)

      # Call logic function
      let ipInfo = infoOp.getIpInfo(ipAddr)

      # Call presentation with results
      infoPresentation.writeIpInfo(ipInfo, format)

    return 0
  except CatchableError as e:
    return fail("Error: " & e.msg)

proc subnet*(cidr: string = "", prefix: int = 0, output: string = ""): int =
  ## Split a CIDR block into smaller subnets with a longer prefix length
  ##
  ## Examples:
  ##   netu subnet --cidr "10.0.0.0/8" --prefix 16
  ##   netu subnet --cidr "192.168.0.0/16" --prefix 24 --output subnets.json
  discard
  return 0

proc supernet*(cidrs: seq[string] = @[], output: string = ""): int =
  ## Perform supernetting on input CIDRs to combine them into larger blocks
  ##
  ## Examples:
  ##   netu supernet --cidrs cidrs.txt --output grouped.json
  ##   netu supernet --cidrs cidrs.json
  discard
  return 0

proc validate*(
    cidrs: seq[string] = @[], strict: bool = false, quiet: bool = false
): int =
  ## Validate CIDR notation and IP addresses from input files
  ##
  ## Examples:
  ##   netu validate --cidrs cidrs.txt
  ##   netu validate --cidrs cidrs.json --strict
  ##   netu validate --cidrs cidrs.txt --quiet
  discard
  return 0

proc overlaps*(
    cidrs: seq[string] = @[],
    output: string = "",
    format: ContainsOutputFormat = formatText,
): int =
  ## Find all overlapping CIDR blocks in the input
  ##
  ## Examples:
  ##   netu overlaps --cidrs cidrs.json
  ##   netu overlaps --cidrs cidrs.txt --output overlaps.json
  ##   netu overlaps --cidrs cidrs.json --format json
  discard
  return 0

proc equals*(cidrs: seq[string] = @[], strict: bool = false): int =
  ## Check if multiple input files contain the same set of IP addresses/CIDRs
  ##
  ## Examples:
  ##   netu equals --cidrs a.json --cidrs b.json
  ##   netu equals --cidrs cidr1.txt --cidrs cidr2.json --cidrs cidr3.csv
  ##   netu equals --cidrs a.json --cidrs b.json --strict
  discard
  return 0

proc expand*(
    cidrs: seq[string] = @[],
    cidr: seq[string] = @[],
    output: string = "",
    usableOnly: bool = false,
    format: IpListOutputFormat = formatText,
): int =
  ## List all IP addresses contained in the input CIDR blocks
  ##
  ## Examples:
  ##   netu expand --cidrs cidrs.json --output ips.txt
  ##   netu expand --cidrs cidrs.txt --usable-only
  ##   netu expand --cidrs cidrs.json --format json
  ##   netu expand --cidr "192.168.1.0/24" --format csv

  # Parse and validate arguments
  if cidrs.len == 0 and cidr.len == 0:
    return fail("At least one CIDR must be specified (--cidrs or --cidr)")

  try:
    # Load CIDRs from files and inline strings
    let cidrSet = loadCidrs(cidrs, cidr)

    # Call logic function - collect all IPs from all CIDRs
    var ips: seq[IpV4] = @[]
    for cidrBlock in cidrSet.items:
      if usableOnly:
        let usableIps = hostsOp.getUsableHosts(cidrBlock)
        ips.add(usableIps)
      else:
        let allIps = hostsOp.getAllHosts(cidrBlock)
        ips.add(allIps)

    # Call presentation with results
    writeIpList(ips, format, output)

    return 0
  except CidrLoadError as e:
    return fail(shortMessage(e))
  except FileError as e:
    return fail("File error: " & e.filePath)
  except FormatError as e:
    return fail("Format error in " & e.filePath)
  except CatchableError as e:
    return fail("Unexpected error: " & e.msg)

proc hosts*(
    cidr: string = "",
    usableOnly: bool = false,
    output: string = "",
    format: IpListOutputFormat = formatText,
): int =
  ## List all host IP addresses in a CIDR block
  ##
  ## Examples:
  ##   netu hosts --cidr "192.168.1.0/24"
  ##   netu hosts --cidr "10.0.0.0/24" --usable-only
  ##   netu hosts --cidr "172.16.0.0/16" --output hosts.txt
  ##   netu hosts --cidr "192.168.0.0/24" --format json

  # Parse and validate arguments
  if cidr.len == 0:
    return fail("CIDR block must be specified (--cidr)")

  try:
    # Parse the CIDR
    let cidrBlock = ipaddress.cidr(cidr)

    # Call logic function
    let ips =
      if usableOnly:
        hostsOp.getUsableHosts(cidrBlock)
      else:
        hostsOp.getAllHosts(cidrBlock)

    # Call presentation with results
    writeIpList(ips, format, output)

    return 0
  except CatchableError as e:
    return fail("Error: " & e.msg)

proc classify*(
    cidrs: seq[string] = @[],
    cidr: seq[string] = @[],
    ips: seq[string] = @[],
    ip: seq[string] = @[],
    output: string = "",
    format: ClassifyOutputFormat = formatText,
): int =
  ## Classify IP addresses and CIDR blocks (private, public, loopback, multicast, etc.)
  ##
  ## Examples:
  ##   netu classify --cidrs ips.txt
  ##   netu classify --cidrs cidrs.json --output classified.json
  ##   netu classify --cidrs ips.txt --format json
  ##   netu classify --ip "192.168.1.1" --ip "8.8.8.8" --format table

  # Parse and validate arguments
  if cidrs.len == 0 and cidr.len == 0 and ips.len == 0 and ip.len == 0:
    return fail("At least one IP or CIDR must be specified")

  try:
    # Load IPs and CIDRs from files and inline strings
    var allIps: seq[IpV4] = @[]

    # Load IPs from files and inline strings
    if ips.len > 0 or ip.len > 0:
      let ipSet = loadIps(ips, ip)
      for ipAddr in ipSet:
        allIps.add(ipAddr)

    # Load CIDRs and expand them to IPs
    if cidrs.len > 0 or cidr.len > 0:
      let cidrSet = loadCidrs(cidrs, cidr)
      for cidrBlock in cidrSet:
        for ipAddr in cidrBlock.hosts():
          allIps.add(ipAddr)

    # Call logic function
    let clasifyResult = classifyOp.classify(allIps)

    # Call presentation with results
    classifyPresentation.writeClassifyResult(clasifyResult, format, output)

    return 0
  except CidrLoadError as e:
    return fail(shortMessage(e))
  except IpLoadError as e:
    return fail(shortMessage(e))
  except FileError as e:
    return fail("File error: " & e.filePath)
  except FormatError as e:
    return fail("Format error in " & e.filePath)
  except CatchableError as e:
    return fail("Unexpected error: " & e.msg)

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
  contains   Check if all IP addresses are contained in at least one CIDR
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
        "cidrs": "Files containing CIDRs (JSON, CSV, or newline-separated)",
        "cidr": "CIDR block(s) to check against (can be specified multiple times)",
        "ips": "Files containing IP addresses",
        "ip":
          "IP address(es) to check (string or uint32, can be specified multiple times)",
        "format": "Output format (text, json, table, none)",
      },
      short = {"cidrs": 's', "cidr": 'c', "ips": 'S', "ip": 'i', "format": 'f'},
    ],
    [
      cli.info,
      help = {
        "cidr": "CIDR block to get information about",
        "ip": "IP address to get information about",
        "format": "Output format (text, json)",
      },
      short = {"cidr": 'c', "ip": 'i', "format": 'f'},
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
        "cidrs": "Input files containing CIDRs to combine", "output": "Output file path"
      },
      short = {"cidrs": 's', "output": 'o'},
    ],
    [
      cli.validate,
      help = {
        "cidrs": "Input files containing CIDRs/IPs to validate",
        "strict": "Enable strict validation (check host bits)",
        "quiet": "Suppress output, only return exit code",
      },
      short = {"cidrs": 's', "quiet": 'q'},
    ],
    [
      cli.overlaps,
      help = {
        "cidrs": "Input files containing CIDRs to check for overlaps",
        "output": "Output file path",
        "format": "Output format (text, json)",
      },
      short = {"cidrs": 's', "output": 'o', "format": 'f'},
    ],
    [
      cli.equals,
      help = {
        "cidrs": "Input files to compare (requires at least 2)",
        "strict": "Strict comparison (CIDR notation must match exactly)",
      },
      short = {"cidrs": 's'},
    ],
    [
      cli.expand,
      help = {
        "cidrs": "Input files containing CIDRs to expand",
        "cidr": "CIDR block(s) to expand (can be specified multiple times)",
        "output": "Output file path",
        "usableOnly": "Only list usable host IPs (exclude network/broadcast)",
        "format": "Output format (text, csv, json, table)",
      },
      short = {"cidrs": 's', "cidr": 'c', "output": 'o', "format": 'f'},
    ],
    [
      cli.hosts,
      help = {
        "cidr": "CIDR block to list hosts from",
        "usableOnly": "Only list usable host IPs (exclude network/broadcast)",
        "output": "Output file path",
        "format": "Output format (text, csv, json, table)",
      },
      short = {"output": 'o', "format": 'f'},
    ],
    [
      cli.classify,
      help = {
        "cidrs": "Input files containing IPs/CIDRs to classify",
        "cidr": "CIDR block(s) to classify (can be specified multiple times)",
        "ips": "Input files containing IP addresses to classify",
        "ip": "IP address(es) to classify (can be specified multiple times)",
        "output": "Output file path",
        "format": "Output format (text, json, table)",
      },
      short =
        {"cidrs": 's', "cidr": 'c', "ips": 'S', "ip": 'i', "output": 'o', "format": 'f'},
    ],
  )
