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

echo
echo "This script helps create Replication Target CR"
echo "Before using this script, You should:"
echo " - create a namespace where you plan to deploy your application into."
echo " - create a namespace on the destination cluster."
echo 

CONTEXTS=$(kubectl config get-contexts --output=name)
echo
echo "Select workload cluster on which to configure replication target CR or CTRL-C to quit"
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

PRIMARYNAME=$(echo $PRIMARYCLUSTERCTX | cut -d "@" -f2)

#Select Remote CR on source cluster
echo

REMOTECRS=$(kubectl get remote --no-headers=true |awk '{print $1}')
echo
echo "Select NDK Remote CR or CTRL-C to quit"
select REMOTECR in $REMOTECRS; do 
    echo "you selected remote CR : ${REMOTECR}"
    echo 
    break
done

#Select source namespace
NAMESPACES=$(kubectl get namespace --no-headers=true |awk '{print $1}')
echo
echo "Select namespace to be replicated FROM or CTRL-C to quit"
select NAMESPACE in $NAMESPACES; do 
    echo "you selected source namespace : ${NAMESPACE}"
    echo 
    SOURCENAMESPACE="${NAMESPACE}"
    break
done

#Select Remote Cluster Context
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

#select remote namespace
NAMESPACES=$(kubectl get namespace --no-headers=true |awk '{print $1}')
echo
echo "Select namespace to be replicated TO or CTRL-C to quit"
select NAMESPACE in $NAMESPACES; do 
    echo "you selected target namespace : ${NAMESPACE}"
    echo 
    TARGETNAMESPACE="${NAMESPACE}"
    break
done

# add verification that NDK intercom is running on this cluster ? 

#Create ReplicationTarget CR
kubectl config use-context $PRIMARYCLUSTERCTX

StorageCluster="apiVersion: dataservices.nutanix.com/v1alpha1
kind: ReplicationTarget
metadata:
  name: replication-$REMOTECR
  namespace: $SOURCENAMESPACE
spec:
  namespaceName: $TARGETNAMESPACE
  remoteName: $REMOTECR
  serviceAccountName: default"

YAMLFILE=./yamls/ndk-$PRIMARYNAME-ReplicationTarget.yaml


echo "$StorageCluster" | yq e > $YAMLFILE
echo "$YAMLFILE created"
echo 
echo "run to apply to cluster:"
echo "kubectl apply -f $YAMLFILE "
