#!/bin/bash

# QA has a new process to test Terraform using RCs. We will not publish RCs
# onto the Terraform registry because Hashicorp could potentially block our
# testing by being slow to publish.

# Instead, we will test using a downloaded binary from the RC. This script
# sets up the correct binary using a defined <provider> <version> to test
# updates locally.

# ./setup-provider.sh <provider> <version>

# Example
# ./setup-provider.sh rancher2 v3.0.0-rc1

set -e 

# Validate user input

if [ $# -ne 2 ]; then
  echo "Usage: $0 <provider> <version>"
  exit 1
fi

# Set global vars

PROVIDER=$1
VERSION=$2
VERSION_TAG=$(echo $2 | cut -c 2-)

# # Install gzip

# # Function to install unzip using apt
# install_unzip_apt() {
#     sudo apt update
#     sudo apt install -y unzip
# }

# # Function to install unzip using yum
# install_unzip_yum() {
#     sudo yum install -y unzip
# }

# # Function to install unzip using zypper
# install_unzip_zypper() {
#     sudo zypper install -y unzip
# }

# # Check if unzip is installed
# if ! command -v unzip &> /dev/null; then
#     echo "unzip not found. Attempting to install..."

#     # Identify the Linux distribution and use the appropriate package manager
#     if [ -f /etc/os-release ]; then
#         . /etc/os-release
#         case $ID in
#             ubuntu|debian)
#                 install_unzip_apt
#                 ;;
#             centos|fedora|rhel)
#                 install_unzip_yum
#                 ;;
#             opensuse*|sles)
#                 install_unzip_zypper
#                 ;;
#             *)
#                 echo "Unsupported distribution. Please install unzip manually."
#                 exit 1
#                 ;;
#         esac
#     else
#         echo "Unable to identify the distribution. Please install unzip manually."
#         exit 1
#     fi
# fi

if ! command -v "gzip" &> /dev/null; then
  echo "Missing gzip. Installing..."
  brew install gzip
fi

# Download binary

OS_PLATFORM=$(uname -sp | tr '[:upper:] ' '[:lower:]_' | sed 's/x86_64/amd64/' | sed 's/i386/amd64/' | sed 's/arm/arm64/')

DIR=~/.terraform.d/plugins/terraform.local/local/${PROVIDER}/${VERSION_TAG}/${OS_PLATFORM}
sudo mkdir -p $DIR
curl -sfL https://github.com/rancher/terraform-provider-${PROVIDER}/releases/download/${VERSION}/terraform-provider-${PROVIDER}_${VERSION_TAG}_${OS_PLATFORM}.zip | gunzip -c - > ${DIR}/terraform-provider-${PROVIDER}
# curl -sfLo "${DIR}/terraform-provider-${PROVIDER}_${VERSION_TAG}_${OS_PLATFORM}.zip" "https://github.com/rancher/terraform-provider-${PROVIDER}/releases/download/${VERSION}/terraform-provider-${PROVIDER}_${VERSION_TAG}_${OS_PLATFORM}.zip"
# unzip -o "${DIR}/terraform-provider-${PROVIDER}_${VERSION_TAG}_${OS_PLATFORM}.zip" -d ${DIR}

# Mod binary
chmod +x ${DIR}/terraform-provider-${PROVIDER}

echo -e "Terraform provider ${PROVIDER} ${VERSION} is ready to test!
Please update the required_providers block in your Terraform config file

terraform {
  required_providers {
    rancher2 = {
      source = "terraform.local/local/${PROVIDER}"
      version = "${VERSION_TAG}"
    }
  }
}"