# NETU

Netu stands for Networking Utilities. This is a collection of CLI tools for working with IP addresses and CIDR blocks. You can do subnetting, supernetting, CIDR expansion, CIDR comparisons, and more.

This is a personal project I made to play around with IP addresses and CIDR notation in Nim. If you find it useful and want to contribute, feel free to open a PR.

## What It Does

The tool works with verbs like any modern CLI tool. You can check if an IP is in a CIDR range, split networks into subnets, combine CIDRs into supernets, validate CIDR notation, find overlapping ranges, and more.

It supports multiple input and output formats: JSON, CSV, and plain text (newline-separated). You can mix and match formats however you want. Single IP addresses are automatically treated as /32 CIDR blocks.

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

Check if an IP is in any CIDR from a file:

```bash
netu contains --in cidrs.json --ip "192.168.1.1"
```

Split a network into smaller subnets:

```bash
netu subnet --cidr "10.0.0.0/8" --prefix 16
```

Combine multiple CIDRs into larger blocks:

```bash
netu supernet --in cidrs.txt --out grouped.json
```

Get detailed info about a CIDR:

```bash
netu info --cidr "192.168.1.0/24"
```

List all hosts in a network:

```bash
netu hosts --cidr "192.168.1.0/24" --usable-only
```

Run `netu help` to see all available commands and options.

## Requirements

- Nim >= 2.2.6
- cligen >= 1.9.6
