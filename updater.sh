#!/bin/bash

# Version 1.7
directory_name="bitcoin"
arch=$(uname -m)
directory=$(printf "%q\n" "$(pwd)" | sed 's/\/\<'"$directory_name"'\>//g')
working_directory="$directory/$directory_name"
temp_directory="$directory/tmp-btc-$$"
offline=0
backup=1
version=""

# CLI flags
while test "$#" -gt 0; do
  case "$1" in
    -h|--help)
      echo "  -h,  --help                    show this help"
      echo "  -d,  --directory /path/to/dir  manually set directory path"
      echo "  -n,  --name dirName            manually set directory name"
      echo "  -v,  --version number          target version (e.g. 32.1)"
      echo "  -s,  --skip                    no input needed (for auto updaters)"
      echo "  -o,  --offline                 offline mode (files must be next to script)"
      exit 0
      ;;
    -n|--name)
      shift
      [ "$#" -gt 0 ] && export directory_name="$1" || { echo "No name specified"; exit 1; }
      shift ;;
    -d|--directory)
      shift
      if [ -d "$1" ]; then
        [ "$#" -gt 0 ] && directory="${1%/}" || { echo "No directory specified"; exit 1; }
      else
        echo "$1 does not exist"; exit 1
      fi
      shift ;;
    -v|--version)
      shift
      [ "$#" -gt 0 ] && export version="$1" || { echo "No version specified"; exit 1; }
      shift ;;
    -s|--skip)
      shift
      export no_input=1
      shift ;;
    -o|--offline)
      shift
      export offline=1
      shift ;;
    *)
      echo "Unrecognized flag \"$1\""; exit 1 ;;
  esac
done

# Auto-detect latest version from bitcoincore.org
if [ -z "$version" ]; then
  if [ "$offline" = "0" ]; then
    version=$(curl -s https://bitcoincore.org/bin/ | grep -oP 'bitcoin-core-\K[0-9]+\.[0-9]+(\.[0-9]+)?(?=/)' | sort -V | tail -1)
    if [ -z "$version" ]; then
      echo "Failed to detect latest version"
      exit 1
    fi
  else
    echo "Offline mode: must specify version with -v"
    exit 1
  fi
fi

# Architecture mapping
if [ "$arch" = "x86_64" ]; then
  arch_suffix="x86_64-linux-gnu"
elif [ "$arch" = "aarch64" ]; then
  arch_suffix="aarch64-linux-gnu"
elif [ "$arch" = "armv7l" ]; then
  arch_suffix="armv7-linux-gnueabihf"
else
  echo "Unsupported architecture: $arch"
  exit 1
fi

binary_name="bitcoin-${version}-${arch_suffix}.tar.gz"
base_url="https://bitcoincore.org/bin/bitcoin-core-${version}"
binary_url="${base_url}/${binary_name}"
sha256sums_url="${base_url}/SHA256SUMS"

# Dependencies
for cmd in wget tar sha256sum curl rsync; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "$cmd not installed"
    exit 1
  fi
done

print () {
  no_color='\033[0m'
  if [ "$2" = "green" ]; then     color='\033[1;32m'
  elif [ "$2" = "yellow" ]; then  color='\033[1;33m'
  elif [ "$2" = "red" ]; then     color='\033[1;31m'
  fi
  echo -e "${color}$1${no_color}"
}

get_sha256sums () {
  print "Downloading SHA256SUMS..." yellow
  if [ "$net" = "1" ]; then
    wget -q -O "$temp_directory/SHA256SUMS" "$sha256sums_url" || {
      print "Failed to download SHA256SUMS" red
      fail
    }
  fi

  print "Extracting expected hash..." yellow
  expected_hash=$(grep "$binary_name" "$temp_directory/SHA256SUMS" | awk '{print $1}')
  if [ -z "$expected_hash" ]; then
    print "Could not find hash for $binary_name in SHA256SUMS" red
    fail
  fi
  print "  Expected: $expected_hash" yellow
  check_0=1
  print "Hash retrieved" green
}

get_binary () {
  print "Downloading ${binary_name}..." yellow
  if [ "$net" = "1" ]; then
    wget -q -O "$temp_directory/${binary_name}" "$binary_url" || {
      print "Failed to download binary" red
      fail
    }
  fi

  print "Verifying binary hash..." yellow
  binary_hash=$(sha256sum "$temp_directory/${binary_name}" | awk '{print $1}')
  print "  Actual:   $binary_hash" yellow
  if [ "$expected_hash" = "$binary_hash" ]; then
    check_1=1
    print "Binary hash matches" green
  else
    print "Binary hash MISMATCH" red
    fail
  fi
}

updater () {
  if [ "$backup" = "1" ]; then
    print "Backing up current installation..." yellow
    rm -rf "$working_directory.bk"
    rsync -a --exclude='node_modules' --exclude='data' --exclude='bin' --exclude='libexec' --exclude='ckpool' --exclude='ckstats' "$working_directory/" "$working_directory.bk/"
  fi

  print "Extracting new binary to $working_directory" yellow
  mkdir -p "$working_directory"
  tar -xzf "$temp_directory/${binary_name}" -C "$working_directory" --strip-components=1

  if [ "$net" = "1" ]; then
    print "Cleaning up temp files..."
    rm -rf "$temp_directory"
  fi
}

fail () {
  print "Verification failed - NOT updating" red
  if [ "$no_input" = "1" ]; then
    print "Removing temp files (no-input mode)" red
    rm -rf "$temp_directory"
  else
    print "Temp files at: $temp_directory" yellow
    print "  Hash check:     $check_0" yellow
    print "  Binary check:   $check_1" yellow
    read -r -p "Remove temp files? [N/y]: " output
    if [ "$output" = 'Y' ] || [ "$output" = 'y' ]; then
      rm -rf "$temp_directory"
    fi
  fi
  exit 1
}

main () {
  check_0=0
  check_1=0
  expected_hash=""

  if wget -q --spider http://github.com 2>/dev/null && [ "$offline" = "0" ]; then
    network_stat="Online"
    net=1
  else
    network_stat="Offline"
    net=0
    temp_directory=$(pwd)
    if [ -f "$temp_directory/${binary_name}" ]; then
      print "Offline files found in: $temp_directory/" green
    else
      print "Offline mode: binary not found" red
      exit 1
    fi
  fi

  print "=== Bitcoin Node Updater ===" green
  print "  Version:      $version" yellow
  print "  Architecture: $arch ($arch_suffix)" yellow
  print "  Network:      $network_stat" yellow
  print "  Install dir:  $working_directory" yellow
  print "  Temp dir:     $temp_directory" yellow
  [ "$backup" = "1" ] && print "  Backup:       ON ($working_directory.bk)" yellow

  if [ "$no_input" = "1" ]; then
    output=Y
  else
    read -r -p "Proceed with install? [Y/n]: " output
  fi

  if [ "$output" = 'N' ] || [ "$output" = 'n' ]; then
    exit 0
  fi

  mkdir -p "$temp_directory"
  get_sha256sums
  get_binary

  if [ "$check_0" = "1" ] && [ "$check_1" = "1" ]; then
    print "All checks passed - installing" green
    updater
    rm -rf "$working_directory.bk"
    print "Done. Restart with: pm2 start bitcoin" green
  else
    fail
  fi
}

main
