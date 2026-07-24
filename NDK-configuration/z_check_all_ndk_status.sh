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

echo
echo "Checking NDK CR status in all namespaces"
echo
echo "StorageCluster:"
kubectl get storagecluster -A
echo
echo "Remote and replicationTarget:"
kubectl get remote,replicationtarget -A
echo
echo "Application:"
kubectl get application -A
echo
echo "ApplicationSnapshot:"
kubectl get applicationsnapshot -A
echo
echo "ApplicationSnapshotRestore:"
kubectl get applicationsnapshotrestore -A   
echo
echo "ApplicationSnapshotReplication:"
kubectl get applicationsnapshotreplication -A
echo
echo "ProtectionPlan:"
kubectl get protectionplan -A
echo
echo "JobScheduler:"
kubectl get jobscheduler -A
echo
echo "AppProtectionPlan:"
kubectl get AppProtectionPlan -A
echo
echo "HAA, HAAC:"
kubectl get haa,haac -A
echo
echo "AppPlannedFailover:"
kubectl get AppPlannedFailover -A
echo
echo "AppUnplannedFailover:"
kubectl get AppUnplannedFailover -A



