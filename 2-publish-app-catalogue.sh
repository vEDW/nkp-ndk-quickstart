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
# check if ndk-registry-url.env exists
if [ ! -f "ndk-registry-url.env" ]; then
    echo "ndk-registry-url.env not found. Exiting."
    exit 1
fi

# read the registry URL from the environment file
REGISTRY_URL=$(cat ndk-registry-url.env)

echo "Creating NDK catalogue application in Kommander workspace"

nkp create catalog-application --url oci://$REGISTRY_URL/nkp-nutanix-product-catalog/ndk --tag "$NDKVERSION" --workspace kommander-workspace
if [ $? -ne 0 ]; then
    echo "nkp create catalog-application failed. Exiting."
    exit 1
fi
echo
echo "NDK catalogue application created successfully in Kommander workspace."

