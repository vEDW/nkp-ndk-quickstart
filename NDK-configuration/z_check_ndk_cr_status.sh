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
echo "This script helps check NDK CRs status"
echo 

CONTEXTS=$(kubectl config get-contexts --output=name)
echo
echo "Select workload cluster or CTRL-C to quit"
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

#Select source namespace
echo
echo "Listing namespaces with Application CR defined"
echo
NAMESPACES=$(kubectl get application --all-namespaces --no-headers=true |awk '{print $1}' |sort -u)
#check if empty
if [ -z "$NAMESPACES" ]; then
    echo "No namespaces with application found. Please create an Application first."
    echo "Checking for Application Snapsots"
    NAMESPACES=$(kubectl get applicationsnapshots --all-namespaces --no-headers=true |awk '{print $1}' |sort -u)
    if [ -z "$NAMESPACES" ]; then
        echo "No namespaces with Application Snapshots found. Please create an Application Snapshot first."
        exit 1
    fi 
fi

echo
echo "Select namespace to protect or CTRL-C to quit"
select NAMESPACE in $NAMESPACES; do 
    echo "you selected source namespace : ${NAMESPACE}"
    echo 
    SOURCENAMESPACE="${NAMESPACE}"
    break
done

echo
echo "Checking NDK CR status in namespace ${SOURCENAMESPACE}"
echo
echo "StorageCluster:"
kubectl get storagecluster -n $SOURCENAMESPACE
echo
echo "Remote and replicationTarget:"
kubectl get remote,replicationtarget -n $SOURCENAMESPACE
echo
echo "Application:"
kubectl get application -n $SOURCENAMESPACE
echo
echo "ApplicationSnapshot:"
kubectl get applicationsnapshot -n $SOURCENAMESPACE
echo
echo "ApplicationSnapshotRestore:"
kubectl get applicationsnapshotrestore -n $SOURCENAMESPACE
echo
echo "ApplicationSnapshotReplication:"
kubectl get applicationsnapshotreplication -n $SOURCENAMESPACE
echo
echo "ProtectionPlan:"
kubectl get protectionplan -n $SOURCENAMESPACE
echo
echo "JobScheduler:"
kubectl get jobscheduler -n $SOURCENAMESPACE
echo
echo "AppProtectionPlan:"
kubectl get AppProtectionPlan -n $SOURCENAMESPACE
echo
echo "HAA, HAAC:"
kubectl get haa,haac -n $SOURCENAMESPACE
echo
echo "AppPlannedFailover:"
kubectl get AppPlannedFailover -n $SOURCENAMESPACE
echo
echo "AppUnplannedFailover:"
kubectl get AppUnplannedFailover -n $SOURCENAMESPACE



