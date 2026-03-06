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
echo "This script helps create an Application Snapshot Replication CR"
echo 

CONTEXTS=$(kubectl config get-contexts --output=name)
echo
echo "Select source application workload cluster or CTRL-C to quit"
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


#Select NDK Snapshot to restore
echo
echo "Select NDK Snapshot to replicate or CTRL-C to quit"
APPSNAPSHOTS=$(kubectl get as -A  --no-headers)
APPSNAPSHOTNAMES=$(echo "$APPSNAPSHOTS" |awk '{print $2}')
if [ -z "$APPSNAPSHOTS" ]; then
    echo "No Application Snapshots found. Please create an Application Snapshot first."
    exit 1
fi
select SNAP in $APPSNAPSHOTS; do 
    echo "you selected application snapshot : ${SNAP}"
    echo 
    break
done

APPSNAPSHOTNAMESPACE=$(echo "$APPSNAPSHOTS" |grep ${SNAP} | awk '{print $1}')
if [ $? -ne 0 ]; then
    echo "Error getting Snapshot $SNAP namespace. Exiting."
    exit 1
fi

echo
echo "Snapshot namespace is $APPSNAPSHOTNAMESPACE"
echo

#select ReplicationTarget in selected namespace
REPLICATIONTARGETS=$(kubectl get replicationtarget -n $APPSNAPSHOTNAMESPACE --no-headers=true |awk '{print $1}' |sort -u)
#check if empty
if [ -z "$REPLICATIONTARGETS" ]; then
    echo "No Replication Targets found in namespace $APPSNAPSHOTNAMESPACE. Please create a Replication Target first."
    exit 1
fi 

echo
echo "Select replication target or CTRL-C to quit"
select REPLICATIONTARGET in $REPLICATIONTARGETS; do 
    echo
    echo "you selected replication target : ${REPLICATIONTARGET}"
    echo 
    break
done

ApplicationSnapshotReplication="apiVersion: dataservices.nutanix.com/v1alpha1
kind: ApplicationSnapshotReplication
metadata:
  name: $SNAP-replication
  namespace: $APPSNAPSHOTNAMESPACE
spec:
  applicationSnapshotName: $SNAP
  replicationTargetName: $REPLICATIONTARGET"
  
YAMLFILE=./yamls/ndk-$SNAP-replication.yaml

echo "$ApplicationSnapshotReplication" | yq e > $YAMLFILE
echo "$YAMLFILE created"
echo 
kubectl apply -f $YAMLFILE
if [ $? -ne 0 ]; then
    echo "Application Snapshot Replication creation failed. Exiting."
    exit 1
fi
echo "Application Snapshot Replication created successfully."
echo
kubectl get -f $YAMLFILE -w
