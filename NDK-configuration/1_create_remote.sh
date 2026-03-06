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


CONTEXTS=$(kubectl config get-contexts --output=name)
echo
echo "Select workload cluster on which to configure remote CR or CTRL-C to quit"
select CONTEXT in $CONTEXTS; do 
    echo "you selected cluster context : ${CONTEXT}"
    echo 
    PRIMARYCLUSTERCTX="${CONTEXT}"
    break
done

kubectl config use-context $PRIMARYCLUSTERCTX
if [ $? -ne 0 ]; then
    echo "kubectl $PRIMARYCLUSTERCTX context error. Exiting."
    exit 1
fi

CONTEXTS=$(kubectl config get-contexts --output=name)
echo
echo "Select REMOTE workload cluster or CTRL-C to quit"
select CONTEXT in $CONTEXTS; do 
    echo "you selected cluster context : ${CONTEXT}"
    echo 
    REMOTECLUSTERCTX="${CONTEXT}"
    break
done

kubectl config use-context $REMOTECLUSTERCTX
if [ $? -ne 0 ]; then
    echo "kubectl $REMOTECLUSTERCTX context error. Exiting."
    exit 1
fi


PRIMARYNAME=$(echo $PRIMARYCLUSTERCTX | cut -d "@" -f2)
REMOTENAME=$(echo $REMOTECLUSTERCTX | cut -d "@" -f2)

REMOTELBIP=$(kubectl get svc ndk-intercom-service -n ntnx-system -o json |jq -r '.status.loadBalancer.ingress[].ip')
#check if REMOTELBIP is empty
if [ -z "$REMOTELBIP" ]; then
    echo "Remote LoadBalancer IP not found. Please check if NDK is installed on remote cluster."
    exit 1
fi

kubectl config use-context $PRIMARYCLUSTERCTX


StorageCluster="apiVersion: dataservices.nutanix.com/v1alpha1
kind: Remote
metadata:
  name: $REMOTENAME-remote
spec:
  ndkServiceIp: $REMOTELBIP
  ndkServicePort: 2021
  tlsConfig:
    skipTLSVerify: true"

YAMLFILE=./yamls/ndk-$PRIMARYNAME-remote.yaml


echo "$StorageCluster" | yq e > $YAMLFILE
echo "$YAMLFILE created"
echo 
echo "run to apply to cluster:"
echo "kubectl apply -f $YAMLFILE"
