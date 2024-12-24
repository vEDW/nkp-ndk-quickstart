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


#check if ndkimagerepo file present 
if [[ ! -e "./ndkimagerepo" ]]; then
    echo "ndkimagerepo file not present. please 2-push-k8s-agent.sh first. exiting."
    exit 1
fi

#Get cluster context
CONTEXTS=$(kubectl config get-contexts  --no-headers=true |awk '{print $2}')
echo
echo "Select workload cluster on which to install agent or CTRL-C to quit"
select CONTEXT in $CONTEXTS; do 
    echo "you selected cluster context : ${CONTEXT}"
    echo 
    CLUSTERCTX="${CONTEXT}"
    break
done

kubectl config use-context $CLUSTERCTX

export CLUSTER_NAME=$(kubectl get cm kubeadm-config -n kube-system -o yaml |yq e '.data.ClusterConfiguration' |yq e '.clusterName')
export CLUSTER_UUID=$(kubectl get ns kube-system -o json |jq -r '.metadata.uid') 
echo
echo "about to install nutanix k8s agent on cluster : $CLUSTER_NAME - cluster UID : $CLUSTER_UUID"
echo "press enter to confirm or CTRL-C to cancel"
read

echo "checking k8s agent"
k8sdir=$(ls -d k8s*)
# Check if directory is empty
if [[ ! -d "$k8sdir" ]]; then
    echo "No k8s agent directory. Exiting."
    exit 1
fi

echo "getting k8s agent chart version"
ChartName=$(yq e '.name' $k8sdir/chart/Chart.yaml)
if [ $? -ne 0 ]; then
    echo "Error getting chart name. Exiting."
    exit 1
fi

ChartVersion=$(yq e '.version' $k8sdir/chart/Chart.yaml)
if [ $? -ne 0 ]; then
    echo "Error getting chart version. Exiting."
    exit 1
fi

ReleaseName="$ChartName-$ChartVersion"
echo
echo "Helm chart : $ReleaseName"
echo

#Checking ntnx-system ns presence
kubectl get ns ntnx-system 
if [ $? -ne 0 ]; then
    echo "Namespace ntnx-system not present on cluster. Exiting."
    exit 1
fi

#Getting Nutanix PC creds for agent
CSICREDS=$(kubectl get secret nutanix-csi-credentials -n ntnx-system -o yaml |yq e '.data.key' |base64 -d)
CSIPC=$(echo $CSICREDS |awk -F ':' '{print $1}' )
CSIUSER=$(echo $CSICREDS |awk -F ':' '{print $3}' )
CSIPASSWD=$(echo $CSICREDS |awk -F ':' '{print $4}' )

#Getting Nutanix PC creds for agent
NDKIMGREPO=$(cat "./ndkimagerepo")
IMAGEREGISTRY=$(echo $NDKIMGREPO |awk -F '/' '{print $1}' )
IMAGEREPO=$(echo $NDKIMGREPO |awk -F '/' '{print $2}' )
IMAGEFULL=$(echo $NDKIMGREPO |awk -F '/' '{print $3}')
IMAGE=$(echo $IMAGEFULL |awk -F ':' '{print $1}')
IMAGETAG=$(echo $IMAGEFULL |awk -F ':' '{print $2}')

#Create helm value file
cp $k8sdir/chart/values.yaml $k8sdir/chart/$CLUSTER_NAME-values.yaml 
#Cluster info
CHARTVALUES=$(yq e '.k8sDistribution |="NKP"' $k8sdir/chart/$CLUSTER_NAME-values.yaml)
CHARTVALUES=$(echo "$CHARTVALUES" |CLUSTER_NAME=$CLUSTER_NAME yq e '.k8sClusterName |=env(CLUSTER_NAME)' )
CHARTVALUES=$(echo "$CHARTVALUES" |CLUSTER_UUID=$CLUSTER_UUID yq e '.k8sClusterUUID |=env(CLUSTER_UUID)' )

#image info
CHARTVALUES=$(echo "$CHARTVALUES" |IMAGE=$IMAGE yq e '.agent.image.name |=env(IMAGE)' )
CHARTVALUES=$(echo "$CHARTVALUES" |IMAGETAG=$IMAGETAG yq e '.agent.image.tag |=env(IMAGETAG)' )
CHARTVALUES=$(echo "$CHARTVALUES" |REPOSITORY="$IMAGEREGISTRY/$IMAGEREPO" yq e '.agent.image.repository |=env(REPOSITORY)' )
CHARTVALUES=$(echo "$CHARTVALUES" |yq e '.agent.image.privateRegistry |=false' )
CHARTVALUES=$(echo "$CHARTVALUES" |yq e '.agent.image.imageCredentials.dockerconfig |=""' )

#PC info
CHARTVALUES=$(echo "$CHARTVALUES" |yq e '.pc.insecure |=true' )
CHARTVALUES=$(echo "$CHARTVALUES" |CSIPC=$CSIPC yq e '.pc.endpoint |=env(CSIPC)' )
CHARTVALUES=$(echo "$CHARTVALUES" |CSIUSER=$CSIUSER yq e '.pc.username |=env(CSIUSER)' )
CHARTVALUES=$(echo "$CHARTVALUES" |CSIPASSWD=$CSIPASSWD yq e '.pc.password |=env(CSIPASSWD)' )

#Save value file
echo "$CHARTVALUES" |yq e > $k8sdir/chart/$CLUSTER_NAME-values.yaml 
yq e $k8sdir/chart/$CLUSTER_NAME-values.yaml 
if [ $? -ne 0 ]; then
    echo "value yaml file error. Exiting."
    exit 1
fi

