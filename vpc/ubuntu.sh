#!/bin/bash

show_usage() {
  echo "USAGE: $0 [-cvh]"
  echo -e '  -c=CUDA_VERSION             Specify NVIDIA\u00AE CUDA\u00AE Toolkit version by Major.Minor version (e.g. "12.4" or "11.8").'
  echo    '                              Use "y" to install latest toolkit version supported by NVIDIA driver installed.'
  echo
  echo -e '  -v=NVIDIA_DRIVER_VERISON    Specify NVIDIA\u00AE driver version by Major version (e.g. "560" or "470" ).'
  echo    '                              Defaults to latest known good (IBM tested) version for the VPC distro kernel release.'
  echo
  echo    '  -h                          Show this help message.'
  echo
}

declare -A driver_versions=(
  ["5.15.0-1061-ibm"]=560
  ["6.8.0-1011-ibm"]=560
)

while getopts ":c:v:h" opt; do
  case $opt in
    c) cuda_version=$OPTARG
    ;;
    v) version_override=$OPTARG
    ;;
    h) show_usage; exit
    ;;
    \?) echo "Invalid option -$OPTARG" >&2; show_usage; exit 1
    ;;
  esac
done

# Determine OS Version
ubuntu_version=$(awk -F'=' '$1 == "VERSION_ID" {gsub(/"/,"",$2); print $2}' /etc/os-release)

# Determine Kernel Version
kernel_version=$(uname -r)

# Use the driver_version array to find OS version id's Nvidia driver
# Override version with version_override (-v)
if [[ -z $version_override ]]; then
    driver_version=${driver_versions[$kernel_version]}
else
    driver_version=$version_override
fi
if [[ -z $driver_version ]]; then
    echo "OS version not supported, use -v to override"; exit 1
fi

# Get nvidia repo apt ready
wget "https://developer.download.nvidia.com/compute/cuda/repos/ubuntu${ubuntu_version/./}/x86_64/cuda-keyring_1.1-1_all.deb"
sudo dpkg -i cuda-keyring_1.1-1_all.deb
apt update

# Install NVIDIA driver
NEEDRESTART_MODE=a apt install -y "nvidia-headless-$driver_version" "nvidia-utils-$driver_version"

# Install CUDA
if [[ $cuda_version == "y" ]]; then
    supported_version=$(nvidia-smi -q | awk -F': ' '/CUDA Version/ {print $2}')
    apt install -y "cuda-toolkit-${supported_version/./-}"
elif [[ -n $cuda_version ]] && [[ $cuda_version != "n" ]]; then
    apt install -y "cuda-toolkit-${cuda_version/./-}"
fi

# Display stats for success
nvidia-smi
