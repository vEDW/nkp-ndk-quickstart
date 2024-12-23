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

echo "checking k8s agent"
k8sdir=$(ls -d k8s*)
# Check if directory is empty
if [[ ! -d "$k8sdir" ]]; then
    echo "No k8s agent directory. Exiting."
    exit 1
fi

echo "loading k8s agent in docker images"
k8sagenttar=$(ls $k8sdir/k8s-agent-*tar)
if [[ ! -e "$k8sagenttar" ]]; then
    echo "No k8s agent tar found. Exiting."
    exit 1
fi

docker image load -i $k8sagenttar
if [ $? -ne 0 ]; then
    echo "docker image ($k8sagenttar) load. Exiting."
    exit 1
fi
