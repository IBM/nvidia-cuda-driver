#!/bin/bash

show_usage() {
  echo "USAGE: $0 [-cvh]"
  echo -e '  -c=CUDA_VERSION             Specify NVIDIA\u00AE CUDA\u00AE Toolkit version by Major.Minor version (e.g. "12.4" or "11.8").'
  echo    '                              Defaults to latest supported by NVIDIA driver. Use "n" to skip CUDA toolkit install.'
  echo
  echo -e '  -v=NVIDIA_DRIVER_VERISON    Specify NVIDIA\u00AE driver version by Major version (e.g. "560" or "470" ).'
  echo    '                              Defaults to latest known good (IBM tested) version for the VPC distro kernel release.'
  echo
  echo    '  -h                          Show this help message.'
  echo
}

# Defaults
# To specify a specific release add the minor version eg 12.4 or 12.0
# If a version of cuda is requested that exceeds the driver version
# The OS installer (/vpc/<os_id>.sh) will error. The installers
# will use the latest driver version unless `driver_version` (-v) is specified)
declare -A cuda_driver=(
  ["11.4"]=470
  ["11.5"]=495
  ["11.6"]=510
  ["11.7"]=515
  ["11.8"]=520
  ["12.0"]=525
  ["12.1"]=530
  ["12.2"]=535
  ["12.3"]=545
  ["12.4"]=550
  ["12.5"]=555
  ["12.6"]=560
)

# Location the script is downloaded and executed from on the instance
tmp_sh="/tmp/ibm_gpu_install.sh"
supported_distros=("rhel" "debian" "ubuntu" "rocky")

# Overrides
while getopts ":c:v:b:u:p:h" opt; do
  case $opt in
    c) cuda_version=$OPTARG
    ;;
    v) driver_version=$OPTARG
    ;;
    b) alt_branch=$OPTARG
    ;;
    u) alt_repo_url=$OPTARG
    ;;
    p) alt_repo_pat=$OPTARG
    ;;
    h) show_usage; exit
    ;;
    \?) echo "Invalid option -$OPTARG" >&2; show_usage; exit 1
    ;;
  esac
done

# Always install CUDA by default, use version if given, check driver compatabilty
if [[ -z $cuda_version ]]; then
  cuda_version="y"
elif [[ $cuda_version != "n" ]]; then
  if [[ -z ${cuda_driver[$cuda_version]} ]]; then
      echo "CUDA version $cuda_version not supported"; exit 1
  elif [[ -n $driver_version ]] && [[ ${cuda_driver[$cuda_version]} -gt $driver_version ]]; then
      echo "CUDA version $cuda_version is greater than driver version $driver_version supports"; exit 1
  fi
fi

# Attempt to detect NVIDIA GPU
if [[ $(which lspci &>/dev/null; echo $?) -eq 0 ]] && [[ $(lspci | grep NVIDIA &>/dev/null; echo $?) -ne 0 ]]; then
  echo "NVIDIA GPU not detected. Aborting driver install!"; exit 1
fi

# Determine the git location of the GPU drivers
# branch is replaced when attached to the github release by CD
branch=main
repo_url="https://raw.githubusercontent.com/IBM/nvidia-cuda-driver"
if [[ -n $alt_branch ]]; then
  branch=$alt_branch
fi
if [[ -n $alt_repo_url ]]; then
  repo_url=$alt_repo_url
fi

# Script downloader from repository by branch
function download_install_script() {
  url_sh=$repo_url/$branch/$1
  if [[ -n $alt_repo_pat ]]; then
    curl -L -H "Authorization: Token $alt_repo_pat" -o "$tmp_sh" "$url_sh"
  else
    curl -L -o "$tmp_sh" "$url_sh"
  fi
  chmod +x "$tmp_sh"
}

# Determine OS distro and validate
distro=$(awk -F'=' '$1 == "ID" {gsub(/"/,"",$2); print $2}' /etc/os-release)
if [[ ! " ${supported_distros[*]} " =~ [[:space:]]${distro}[[:space:]] ]]; then
  echo "OS distribution $distro not supported"; exit 1
fi

# Use rhel installer for rocky
if [[ $distro == "rocky" ]]; then
  distro="rhel"
fi

# Download installer
download_install_script "vpc/${distro}.sh"

# Generate install command
echo "Starting GPU install"
cmd="$tmp_sh -c $cuda_version"
if [[ -n $driver_version ]]; then
   cmd="$cmd -v $driver_version"
fi

# Run installer
if $cmd; then
  echo "GPU install complete!"
else
  echo "GPU install FAILED!"; exit 1
fi
