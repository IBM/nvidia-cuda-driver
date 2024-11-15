# NVIDIA Driver Install Scripts for IBM VPC

[![Build Status](https://v3.travis.ibm.com/workload-eng-services/nvidia-cuda-driver.svg?token=PSs96f7r2zBFnDeNZoSk&branch=main)](https://v3.travis.ibm.com/workload-eng-services/nvidia-cuda-driver)


:warning: **This project is in beta. Do not use for production.**

:warning: **This warning will be removed when it is safe to use in your workflows.**

These scripts provide automated installation for NVIDIA&reg; drivers using NVIDIA precompiled drivers.
The main install script `install.sh` will discover the distribution, then download and run the
corresponding installer found in the `vpc` directory. Driver versions are matched to the the kernel
version for IBM VPC images and tested to ensure compatibility. By default the latest version of the
[NVIDIA&reg; CUDA&reg; Toolkit](https://developer.nvidia.com/cuda-toolkit) for the driver is also installed.

## Supported Distributions

Because NVIDIA does not supply precompiled drivers for all distributions, not all of the offered
images by IBM VPC are supported. The current supported distributions are:

- RHEL
- Rocky
- Ubuntu
- Debian

See the table in [Supported IBM Images and CUDA Version](#supported-ibm-images-and-cuda-version) for
a complete list of images supported by this version of the installers. Note, each release of this
repository will support the latest, at time of release, image versions for VPC. It is recommended in
your image building pipeline to tag the version matching with the VPC image version you are
installing drivers for.

## Quick Install

To get started run this command on your instance, or add it to your cloud-init.

```
curl -L https://github.com/IBM/nvidia-cuda-driver/releases/latest/download/install.sh | bash
```

## Pinning

For automated workflows and image building, it is recommended to use a tagged release version as the
main branch will change as new versions of the distribution are released for IBM VPC. Note the change
in format from the `latest` path.

```
curl -L https://github.com/IBM/nvidia-cuda-driver/releases/download/v1.0.0/install.sh | bash
```

Replace the version `v1.0.0` above with the release version of this repository you wish to use.

## Startup with cloud-init

To run the install as part of your servers startup using cloud-init, add the following to your
servers user data. Note for [Debian](#debian), you will need to install `curl` first.

```
#cloud-config
runcmd:
  - curl -L https://github.com/IBM/nvidia-cuda-driver/releases/latest/download/install.sh | bash
```

## Advanced Install

You can also choose options when you install. These options will let you manually override
the NVIDIA driver version and the CUDA version. You can also choose not to install the CUDA
toolkit.

```
USAGE: ./install.sh [-cvh]
  -c=CUDA_VERSION             Specify CUDA toolkit version by Major.Minor version (e.g. "12.4" or "11.8").
                              Defaults to latest supported by NVIDIA driver. Use "n" to skip CUDA toolkit install.

  -v=NVIDIA_DRIVER_VERISON    Specify NVIDIA driver version by Major version (e.g. "560" or "470" ).
                              Defaults to latest known good (IBM tested) version for the VPC distro kernel release.

  -h                          Show this help message.
```

### Debian

For Debian, you will need to first install `curl` to execute the installer.

```
apt update
apt install -y curl
```

## IBM Image NVIDIA Driver and CUDA Default Versions

This table shows the default and tested versions of the NVIDIA driver and corresponding CUDA
version for the IBM images supported by this version of the installer. To find older versions
of supported IBM images, view the repository's [releases page](./releases).

| Image | Distribution | Version | Status* |  NVIDIA Driver | CUDA |
|-|-|-|-|-|-|
| ibm-redhat-8-8-minimal-amd64-3 | RHEL | 8.8 | deprecated | 525 | 12.0 |
| ibm-redhat-8-10-minimal-amd64-2 | RHEL | 8.10 | available | 560 | 12.6 |
| ibm-redhat-9-2-minimal-amd64-3 | RHEL | 9.2 | deprecated | 525 | 12.0 |
| ibm-redhat-9-4-minimal-amd64-4 | RHEL | 9.4 | available | 560 | 12.6 |
| ibm-rocky-linux-8-10-minimal-amd64-2 | Rocky | 8.10 | available | 555 | 12.5 |
| ibm-rocky-linux-9-4-minimal-amd64-2 | Rocky | 9.4 | available | 555 | 12.5 |
| ibm-ubuntu-20-04-6-minimal-amd64-6 | Ubuntu | 20.04 | available | 560 | 12.6 |
| ibm-ubuntu-22-04-4-minimal-amd64-4 | Ubuntu | 22.04 | available | 560 | 12.6 |
| ibm-ubuntu-24-04-6-minimal-amd64-1 | Ubuntu | 24.04 | available | 560 | 12.6 |
| ibm-debian-11-9-minimal-amd64-2 | Debian | 11.9 | available | 560 | 12.6 |
| ibm-debian-12-6-minimal-amd64-1 | Debian | 20.04 | available | 565 | 12.6 |


 \* When a newer IBM VPC image version release exists for a distribution version but there are not
    NVIDIA precompiled drivers for the updated kernel, the `deprecated` release of the VPC image
    will be supported until the distribution version is completely obsolete.
