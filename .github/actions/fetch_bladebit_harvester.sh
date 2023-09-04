#!/usr/bin/env bash
set -eo pipefail
_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
cd "$_dir/../.."

##
# Usage: fetch_bladebit_harvester.sh <linux|macos|windows> <arm64|x86-64>
#
# Use gitbash or similar under Windows.
##
host_os=$1
host_arch=$2

if [[ "${host_os}" != "linux" ]] && [[ "${host_os}" != "macos" ]] && [[ "${host_os}" != "windows" ]]; then
  echo >&2 "Unkonwn OS '${host_os}'"
  exit 1
fi

if [[ "${host_arch}" != "arm64" ]] && [[ "${host_arch}" != "x86-64" ]]; then
  echo >&2 "Unkonwn Architecture '${host_arch}'"
  exit 1
fi

## Change this if including a new bladebit release
artifact_ver="v3.0.0"
artifact_base_url="https://github.com/Chik-Network/bladebit/releases/download/v3.0.0"

linux_arm_sha256="0d0c92514d99e3c0f287fd3c47789e8b8c01484a56fd25c32be090f89d5b5494"
linux_x86_sha256="be99d0707bf02bf7f3244985ee2153414df9082cdb8e15f112d2fa45f00b9b46"
macos_arm_sha256="325150951e83be4ee8690be996e6fde0776ff4cca89e39111c97f0aae3f93bf3"
macos_x86_sha256="e862f87aa93ec473d16ca6a2ebff5e294e4db5e477baa1dcd33b04841441d92f"
windows_sha256="c6b3636b5261cb1345168432e69675e169302cd73d7626841cb6aebf56c98e2b"
## End changes

artifact_ext="tar.gz"
sha_bin="sha256sum"
expected_sha256=

if [[ "$OSTYPE" == "darwin"* ]]; then
  sha_bin="shasum -a 256"
fi

case "${host_os}" in
linux)
  if [[ "${host_arch}" == "arm64" ]]; then
    expected_sha256=$linux_arm_sha256
  else
    expected_sha256=$linux_x86_sha256
  fi
  ;;
macos)
  if [[ "${host_arch}" == "arm64" ]]; then
    expected_sha256=$macos_arm_sha256
  else
    expected_sha256=$macos_x86_sha256
  fi
  ;;
windows)
  expected_sha256=$windows_sha256
  artifact_ext="zip"
  ;;
*)
  echo >&2 "Unexpected OS '${host_os}'"
  exit 1
  ;;
esac

# Download artifact
artifact_name="green_reaper.${artifact_ext}"
curl -L "${artifact_base_url}/green_reaper-${artifact_ver}-${host_os}-${host_arch}.${artifact_ext}" >"${artifact_name}"

# Validate sha256, if one was given
if [ -n "${expected_sha256}" ]; then
  gr_sha256="$(${sha_bin} ${artifact_name} | cut -d' ' -f1)"

  if [[ "${gr_sha256}" != "${expected_sha256}" ]]; then
    echo >&2 "GreenReaper SHA256 mismatch!"
    echo >&2 " Got     : '${gr_sha256}'"
    echo >&2 " Expected: '${expected_sha256}'"
    exit 1
  fi
fi

# Unpack artifact
dst_dir="libs/green_reaper"
mkdir -p "${dst_dir}"
if [[ "${artifact_ext}" == "zip" ]]; then
  unzip -d "${dst_dir}" "${artifact_name}"
else
  pushd "${dst_dir}"
  tar -xzvf "../../${artifact_name}"
  popd
fi
