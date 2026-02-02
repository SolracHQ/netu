## Tests for format modules (JSON, Text, CSV)

import unittest
import std/strutils
import ../src/netu/ipaddress
import ../src/netu/formats/json
import ../src/netu/formats/text
import ../src/netu/formats/csv

const
  exampleDir = "examples/"
  jsonFile = exampleDir & "cidrs.json"
  textFile = exampleDir & "cidrs.txt"
  csvFile = exampleDir & "cidrs.csv"

suite "JSON Format Tests":
  test "load CIDRs from JSON file":
    let cidrs = json.loadCidrsFromFile(jsonFile)
    check cidrs.len == 5
    check cidrs[0] == cidr("192.168.1.0/24")
    check cidrs[1] == cidr("10.0.0.0/8")

  test "write CIDRs to JSON string":
    let cidrs = @[cidr("192.168.1.0/24"), cidr("10.0.0.0/8")]
    let jsonStr = json.writeCidrs(cidrs)
    check jsonStr.len > 0

suite "Text Format Tests":
  test "load CIDRs from text file":
    let cidrs = text.loadCidrsFromFile(textFile)
    check cidrs.len == 5
    check cidrs[0] == cidr("192.168.1.0/24")
    check cidrs[1] == cidr("10.0.0.0/8")

  test "write CIDRs to text string":
    let cidrs = @[cidr("192.168.1.0/24"), cidr("10.0.0.0/8")]
    let textStr = text.writeCidrs(cidrs)
    check textStr.find("192.168.1.0/24") >= 0
    check textStr.find("10.0.0.0/8") >= 0

  test "load single IP as /32 CIDR":
    let testData = "192.168.1.1\n10.0.0.5"
    let cidrs = text.loadCidrs(testData)
    check cidrs.len == 2
    check cidrs[0] == cidr("192.168.1.1/32")
    check cidrs[1] == cidr("10.0.0.5/32")

suite "CSV Format Tests":
  test "load CIDRs from CSV file":
    let cidrs = csv.loadCidrsFromFile(csvFile)
    check cidrs.len == 5
    check cidrs[0] == cidr("192.168.1.0/24")
    check cidrs[1] == cidr("10.0.0.0/8")

  test "write CIDRs to CSV string":
    let cidrs = @[cidr("192.168.1.0/24"), cidr("10.0.0.0/8")]
    let csvStr = csv.writeCidrs(cidrs)
    check csvStr.find("192.168.1.0/24") >= 0
    check csvStr.find("10.0.0.0/8") >= 0
    check csvStr.find(',') >= 0

  test "load single IPs as /32 CIDRs from CSV":
    let testData = "192.168.1.1,10.0.0.5"
    let cidrs = csv.loadCidrs(testData)
    check cidrs.len == 2
    check cidrs[0] == cidr("192.168.1.1/32")
    check cidrs[1] == cidr("10.0.0.5/32")

suite "Format Integration Tests":
  test "all formats produce same CIDR list":
    let jsonCidrs = json.loadCidrsFromFile(jsonFile)
    let textCidrs = text.loadCidrsFromFile(textFile)
    let csvCidrs = csv.loadCidrsFromFile(csvFile)

    check jsonCidrs == textCidrs
    check textCidrs == csvCidrs
