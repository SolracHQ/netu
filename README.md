# NETU

Netu stands for Networking Utilities. This is a collection of CLI tools for working with IP addresses and CIDR blocks. You can do subnetting, supernetting, CIDR expansion, CIDR comparisons, and more.

This is a personal project I made to play around with IP addresses and CIDR notation in Nim. If you find it useful and want to contribute, feel free to open a PR.

## What It Does

The tool works with verbs like any modern CLI tool. It supports multiple input and output formats: JSON, CSV, and plain text (newline-separated). You can mix and match formats however you want. Single IP addresses are automatically treated as /32 CIDR blocks.

### Implemented Commands

| Command | Description |
|---------|-------------|
| contains | Check if IP addresses are contained in CIDR blocks |
| info | Show detailed information about a CIDR block or IP address |
| hosts | List all host IP addresses in a CIDR block |
| expand | List all IP addresses contained in input CIDR blocks |
| classify | Classify IP addresses and CIDR blocks by type (private, public, loopback, multicast, etc.) |

### Pending Commands

| Command | Description |
|---------|-------------|
| subnet | Split a CIDR block into smaller subnets with a longer prefix length |
| supernet | Perform supernetting on input CIDRs to combine them into larger blocks |
| validate | Validate CIDR notation and IP addresses from input files |
| overlaps | Find all overlapping CIDR blocks in the input |
| equals | Check if multiple input files contain the same set of IP addresses/CIDRs |

## Building and Running

This project uses [Just](https://github.com/casey/just) as a command runner. If you don't have it installed, you can still use nimble directly.

### Build

```bash
just build
```

Or for a release build:

```bash
just build-release
```

Using watchexec for automatic rebuilds on file changes:

```bash
watchexec -c -e nim just build
```

### Run

```bash
just run -- --help
```

Or directly:

```bash
./netu --help
```

### Test

```bash
just test
```

## Examples

The following examples show how to use the implemented commands:

Check if IP addresses are contained in CIDR blocks:

```bash
netu contains --cidrs cidrs.json --ip "192.168.1.1"
netu contains --cidr "192.168.1.0/24" --ip "192.168.1.1"
netu contains --cidr "10.0.0.0/8" --cidr "172.16.0.0/12" --ip "172.16.5.100" --ip "10.5.5.5"
netu contains --cidr "192.168.0.0/16" --ip "192.168.1.1" --format json
```

Get detailed info about a CIDR or IP:

```bash
netu info --cidr "192.168.1.0/24"
netu info --ip "192.168.1.1"
netu info --ip "192.168.1.1" --format json
```

List all hosts in a network:

```bash
netu hosts --cidr "192.168.1.0/24"
netu hosts --cidr "10.0.0.0/24" --usable-only
netu hosts --cidr "172.16.0.0/16" --output hosts.txt
netu hosts --cidr "192.168.0.0/24" --format json
```

Expand CIDR blocks to IP addresses:

```bash
netu expand --cidrs cidrs.json --output ips.txt
netu expand --cidrs cidrs.txt --usable-only
netu expand --cidr "192.168.1.0/24" --format csv
```

Classify IP addresses and CIDR blocks:

```bash
netu classify --cidrs ips.txt
netu classify --cidrs cidrs.json --output classified.json
netu classify --ip "192.168.1.1" --ip "8.8.8.8" --format table
```

The following commands are planned but not yet implemented:

Split a network into smaller subnets:

```bash
netu subnet --cidr "10.0.0.0/8" --prefix 16
netu subnet --cidr "192.168.0.0/16" --prefix 24 --output subnets.json
```

Combine multiple CIDRs into larger blocks:

```bash
netu supernet --cidrs cidrs.txt --output grouped.json
netu supernet --cidrs cidrs.json
```

Validate CIDR notation:

```bash
netu validate --cidrs cidrs.txt
netu validate --cidrs cidrs.json --strict
```

Find overlapping CIDR blocks:

```bash
netu overlaps --cidrs cidrs.json
netu overlaps --cidrs cidrs.txt --output overlaps.json
```

Check if files contain the same IP addresses:

```bash
netu equals --cidrs a.json --cidrs b.json
netu equals --cidrs cidr1.txt --cidrs cidr2.json --cidrs cidr3.csv
```

Run `netu help` to see all available commands and options.

## Requirements

- Nim >= 2.2.6
- cligen >= 1.9.6
