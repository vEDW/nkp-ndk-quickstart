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

#select NKP Management Cluster kubeconfig context
CONTEXTS=$(kubectl config get-contexts --output=name)
echo
echo "Select management cluster or CTRL-C to quit"
select CONTEXT in $CONTEXTS; do 
    echo "you selected cluster context : ${CONTEXT}"
    echo 
    MGMTCLUSTERCTX="${CONTEXT}"
    break
done

kubectl config use-context $MGMTCLUSTERCTX

#check if this is a NKP Management cluster
KOMANDERCRD=$(kubectl  api-resources |grep cluster.x-k8s.io)
if [[ -z "$KOMANDERCRD" ]]; then
    echo "This is not a NKP Management Cluster. Please select a valid management cluster."
    exit 1
fi

# Get cluster name and UUID
WORKLOADCLUSTERSJSON=$(kubectl get clusters.cluster.x-k8s.io -A -o json)
if [[ -z "$WORKLOADCLUSTERSJSON" ]]; then
    echo "No workload clusters found. Please create a workload cluster first."
    exit 1
fi
CLUSTERS=$(echo "${WORKLOADCLUSTERSJSON}" |jq -r '.items[].metadata.name')
if [[ -z "$CLUSTERS" ]]; then
    echo "No workload clusters found. Please create a workload cluster first."
    exit 1
fi
echo "Select workload cluster to upgrade csi to 3.3.4 or CTRL-C to quit"
select WKCLUSTER in $CLUSTERS; do 
    echo "you selected cluster  : ${WKCLUSTER}"
    echo 
    break
done
CLUSTERNAMESPACE=$(echo "${WORKLOADCLUSTERSJSON}" | jq --arg WKCLUSTER "$WKCLUSTER" -r '.items[].metadata |select (.name ==  $WKCLUSTER) |.namespace')

echo "you selected cluster  : ${WKCLUSTER} is in namespace : ${CLUSTERNAMESPACE}" 

CLUSTERUUID=$(echo "${WORKLOADCLUSTERSJSON}" | jq --arg WKCLUSTER "$WKCLUSTER" -r '.items[].metadata |select (.name ==  $WKCLUSTER) |.annotations."caren.nutanix.com/cluster-uuid"')
echo "cluster ${WKCLUSTER} has uuid : ${CLUSTERUUID}" 

#check current csi version
CSIHCPNAME=$(kubectl get hcp -n $CLUSTERNAMESPACE |grep csi | grep ${CLUSTERUUID}| awk '{print $1}')
if [[ -z "$CSIHCPNAME" ]]; then
    echo "No CSI HCP found for cluster ${WKCLUSTER}. stopping script."
    exit 1
fi

echo "cluster ${WKCLUSTER} has CSIHCPNAME : ${CSIHCPNAME}" 

CSIHCPVERSION=$(kubectl get hcp $CSIHCPNAME -n $CLUSTERNAMESPACE -o json | jq -r '.spec.version')
if [[ -z "$CSIHCPVERSION" ]]; then
    echo "No CSI HCP version found for cluster ${WKCLUSTER}. stopping script."
    exit 1
fi
echo "CSI HCP version for cluster ${WKCLUSTER} is : ${CSIHCPVERSION}"
if [[ "$CSIHCPVERSION" == "3.3.4" ]]; then
    echo "CSI HCP version for cluster ${WKCLUSTER} is already 3.3.4. Nothing to do."
    exit 0
fi
echo "CSI HCP version for cluster ${WKCLUSTER} is not 3.3.4. Proceeding with upgrade."
kubectl patch hcp $CSIHCPNAME -n $CLUSTERNAMESPACE  --type='json' -p='[{"op": "remove", "path": "/spec/tlsConfig"}]'
kubectl patch hcp $CSIHCPNAME -n $CLUSTERNAMESPACE  --type='json' -p='[{"op": "replace", "path": "/spec/repoURL", "value":"https://nutanix.github.io/helm-releases/"}]'
kubectl patch hcp $CSIHCPNAME -n $CLUSTERNAMESPACE  --type='json' -p='[{"op": "replace", "path": "/spec/version", "value":"3.3.4"}]'
if [ $? -ne 0 ]; then
    echo "Error patching secret $SECRET in namespace capa-system. Exiting."
    exit 1
fi
