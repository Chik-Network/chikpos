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
linux_x86_sha256="0b80d7b800ceb1254897ee64d069ba264a7556bb229d76f31026cfc64a7599d7"
macos_arm_sha256="325150951e83be4ee8690be996e6fde0776ff4cca89e39111c97f0aae3f93bf3"
macos_x86_sha256="0bf92038a9a40b1de66ebb91a9f7f290a242612a9b660dae7fd83d51255fc9af"
windows_sha256="29b433f2c20176e5f28c65161c84d0a582e66a90529304b72715d1bc27c47711"
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
