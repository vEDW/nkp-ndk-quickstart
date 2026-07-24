#!/usr/bin/env bash

#------------------------------------------------------------------------------

# Copyright 2024 Nutanix, Inc
#
# Licensed under the MIT License;
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”),
# to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#------------------------------------------------------------------------------

# Maintainer:   Eric De Witte (eric.dewitte@nutanix.com)
# Contributors: 

#------------------------------------------------------------------------------

NDKVERSION="2.0.0"

# check if ndk-$NDKVERSION-airgapped.tar was created
if [ ! -f "ndk-$NDKVERSION-airgapped.tar" ]; then
    echo "ndk-$NDKVERSION-airgapped.tar not found. Exiting."
    echo "Run script 0-create-nkp-ndk-catalogue.sh to create the catalogue bundle first."
    exit 1
fi

# Prompt the user for the registry server name
echo
read -p "Enter private registry (no https prefix): " registry < /dev/tty
echo
read -p "Enter private registry repository: " registryrepo < /dev/tty
echo
read -p "Enter private registry username : " REGISTRY_USERNAME < /dev/tty
echo
read -sp "Enter private registry password: " REGISTRY_PASSWORD < /dev/tty
echo

REGISTRY_URL="${registry}/${registryrepo}"
nkp push bundle --bundle ndk-$NDKVERSION-airgapped.tar \
    --to-registry-mirror-url=${REGISTRY_URL} \
    --to-registry-mirror-username=${REGISTRY_USERNAME} \
    --to-registry-mirror-password=${REGISTRY_PASSWORD}

#check if nkp push was successful
if [ $? -ne 0 ]; then
    echo "nkp push failed. Exiting."
    exit 1
fi
echo 
echo "Bundle pushed to ${REGISTRY_URL} successfully."
echo

echo "Creating NDK catalogue application in Kommander workspace"

nkp create catalog-application --url oci://$REGISTRY_URL/nkp-nutanix-product-catalog/ndk --tag "$NDKVERSION" --workspace kommander-workspace
if [ $? -ne 0 ]; then
    echo "nkp create catalog-application failed. Exiting."
    exit 1
fi
echo
echo "NDK catalogue application created successfully in Kommander workspace."

