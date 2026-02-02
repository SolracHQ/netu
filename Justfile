# Justfile for netu project

# Default recipe - show available commands
default:
    @just --list

# Run all tests
test:
    nimble test

# Build the project
build *PARAMS:
    nimble build {{ PARAMS }}

# Run the project
run *PARAMS:
    nimble run {{ PARAMS }}

# Build in release mode
build-release:
    nimble build -d:release

# Clean build artifacts
clean:
    nimble clean
    rm -rf bin/
    rm -rf netu

# Run tests with verbose output
test-verbose:
    nimble test --verbose

# Check code without building
check:
    nim check src/netu.nim

# Format code (requires nimpretty)
fmt:
    nph src
