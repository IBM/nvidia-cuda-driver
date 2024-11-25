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
    ["4.18.0-477.27.1.el8_8.x86_64"]=525            # ibm-redhat-8-8-minimal-amd64-3
    ["4.18.0-553.8.1.el8_10.x86_64"]=555            # ibm-rocky-linux-8-10-minimal-amd64-2
    ["4.18.0-553.16.1.el8_10.x86_64"]="565-dkms"    # ibm-redhat-8-10-minimal-amd64-2
    ["5.14.0-284.30.1.el9_2.x86_64"]=525            # ibm-redhat-9-2-minimal-amd64-3
    ["5.14.0-427.22.1.el9_4.x86_64"]=555            # ibm-rocky-linux-9-4-minimal-amd64-2
    ["5.14.0-427.33.1.el9_4.x86_64"]="565-dkms"     # ibm-redhat-9-4-minimal-amd64-4
)

declare -A cuda_versions=(
    ["4.18.0-553.16.1.el8_10.x86_64"]="12.6"
    ["5.14.0-427.33.1.el9_4.x86_64"]="12.6"
)

while getopts ":c:v:h" opt; do
  case $opt in
    c) cuda_option=$OPTARG
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
rhel_version=$(awk -F'=' '$1 == "VERSION_ID" {gsub(/"/,"",$2); print $2}' /etc/os-release)
major_version=${rhel_version%.*}

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

# Determine if rocky or rhel
distro=$(awk -F'=' '$1 == "ID" {gsub(/"/,"",$2); print $2}' /etc/os-release)

# Install gcc for CUDA only, needed before driver install only for Rocky 9
if [[ -n $cuda_option ]] && [[ $cuda_option != "n" ]]; then
    if [[ $distro == "rocky" ]] && [[ $major_version == "9" ]]; then
        dnf install -y gcc-c++
    fi
fi

# Add repos for driver and CUDA
if [[ $distro == "rhel" ]]; then
    subscription-manager repos --enable="rhel-$major_version-for-x86_64-appstream-rpms"
    subscription-manager repos --enable="rhel-$major_version-for-x86_64-baseos-rpms"
    subscription-manager repos --enable="codeready-builder-for-rhel-$major_version-x86_64-rpms"
fi
dnf config-manager --add-repo="https://developer.download.nvidia.com/compute/cuda/repos/rhel$major_version/x86_64/cuda-rhel$major_version.repo"

if [[ $driver_version =~ "dkms" ]]; then
    rpm --import "http://download.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-$major_version"
    dnf install -y "https://dl.fedoraproject.org/pub/epel/epel-release-latest-$major_version.noarch.rpm"
    dnf install -y "kernel-devel-$kernel_version"
fi

# Install NVIDIA driver
dnf module install -y "nvidia-driver:$driver_version"
rmmod nouveau 2>/dev/null
modprobe nvidia

# Install CUDA
if [[ $cuda_option == "y" ]]; then
    cuda_version=${cuda_versions[$kernel_version]}
    if [[ -z $cuda_version ]]; then
        cuda_version=$(nvidia-smi -q | awk -F': ' '/CUDA Version/ {print $2}')
    fi
    dnf -y install "cuda-toolkit-${cuda_version/./-}"
elif [[ -n $cuda_option ]] && [[ $cuda_option != "n" ]]; then
    dnf -y install "cuda-toolkit-${cuda_option/./-}"
fi

# Display stats for success
nvidia-smi
