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


# Prompt the user for the registry server name
echo
read -p "Enter private registry: " registry < /dev/tty
echo
read -p "Enter private registry repository: " registryrepo < /dev/tty
echo
read -p "Enter private registry username : " registryuser < /dev/tty
echo
read -sp "Enter private registry password: " registrypasswd < /dev/tty
echo

echo $registrypasswd | docker login $registry --username $registryuser --password-stdin

if [ $? -ne 0 ]; then
    echo "docker login failed. Exiting."
    exit 1
fi

agentjson=$(docker images -f reference=k8s-agent --format json | jq .)
if [ $? -ne 0 ]; then
    echo "docker image not loaded. Exiting."
    exit 1
fi
agenttag=$(docker images -f reference=k8s-agent --format json | jq -r '.Tag')

docker image tag k8s-agent:$agenttag  $registry/$registryrepo/k8s-agent:$agenttag
docker push $registry/$registryrepo/k8s-agent:$agenttag

if [ $? -ne 0 ]; then
    echo "docker image push error. Exiting."
    exit 1
fi
