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
echo "This script helps create an Application UN-Planned Failover CR"
echo 
echo "This means that the application failover is initiated from the DR site without prior notification to the primary site."
echo "This is typically used in disaster recovery scenarios where the primary site is unavailable."
echo
echo "This applies only to applications protected with SYNCHRONOUS replication."
echo
echo "Proceed only if you understand the implications of an un-planned failover."
echo

CONTEXTS=$(kubectl config get-contexts --output=name)
echo
echo "Select workload cluster on which the application to failover is running (aka source cluster) or CTRL-C to quit"
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
APPLICATIONSJSON=$(kubectl get application --all-namespaces -o json)
if [[ -z "$APPLICATIONSJSON" ]]; then
    echo "No Application CR found in any namespace. Select a different cluster or create an Application CR first."
    exit 1
fi

#
APPLICATIONNAMES=$(echo "$APPLICATIONSJSON" | jq -r '.items[].metadata.name')
echo
echo "Select Application CR or CTRL-C to quit"
select APPLICATION in $APPLICATIONNAMES; do 
    echo "you selected Application CR : ${APPLICATION}"
    echo 
    break
done

#Get application Namespace
APPLICATIONNAMESPACE=$(echo "$APPLICATIONSJSON" | jq -r '.items[].metadata | select(.name == "'"$APPLICATION"'") |.namespace')
#Select ProtectionPlan in namespace

#find related replication target
REPLICATIONTARGETJSON=$(kubectl get replicationtarget -n $APPLICATIONNAMESPACE -o json)
if [[ -z "$REPLICATIONTARGETJSON" ]]; then
    echo "No Replication Target found in namespace $APPLICATIONNAMESPACE. Please create a Replication Target first."
    exit 1
fi
REPLICATIONTARGETNAME=$(echo "$REPLICATIONTARGETJSON" | jq -r '.items[].metadata.name')
if [[ -z "$REPLICATIONTARGETNAME" ]]; then
    echo "No Replication Target found in namespace $APPLICATIONNAMESPACE. Please create a Replication Target first."
    exit 1
fi

REPLICATIONTARGETNAMEREMOTENAMESPACE=$(echo "$REPLICATIONTARGETJSON" | jq -r '.items[].spec.namespaceName')
if [[ -z "$REPLICATIONTARGETNAMEREMOTENAMESPACE" ]]; then
    echo "No Replication Target remote namespace found in $REPLICATIONTARGETNAME. Please verify Replication Target."
    exit 1
fi  

CONTEXTS=$(kubectl config get-contexts --output=name)
echo
echo "Select workload cluster on which the application to failover is running (aka DR cluster) or CTRL-C to quit"
select CONTEXT in $CONTEXTS; do 
    echo "you selected cluster context : ${CONTEXT}"
    echo 
    DRCLUSTERCTX="${CONTEXT}"
    break
done

kubectl config use-context $DRCLUSTERCTX
if [ $? -ne 0 ]; then
    echo "kubectl $DRCLUSTERCTX context error. Exiting."
    exit 1
fi

#Check if namespace exists in DR cluster
DRNAMESPACES=$(kubectl get namespaces --no-headers=true | awk '{print $1}' | grep $REPLICATIONTARGETNAMEREMOTENAMESPACE)
if [[ -z "$DRNAMESPACES" ]]; then
    echo "No namespace $REPLICATIONTARGETNAMEREMOTENAMESPACE found in cluster $DRCLUSTERCTX. Please select correct cluster context."
    exit 1
fi

APPPLANNEDFAILOVER="apiVersion: dataservices.nutanix.com/v1alpha1
kind: AppUnplannedFailover
metadata:
  name: $APPLICATION-upfo
  namespace: $REPLICATIONTARGETNAMEREMOTENAMESPACE
spec:
  applicationName: $APPLICATION"

YAMLFILE=./yamls/ndk-$APPLICATION-AppPlannedFailover.yaml


echo "$APPPLANNEDFAILOVER" | yq e > $YAMLFILE
echo "$YAMLFILE created"
echo 
echo "run to apply to cluster:"
echo "kubectl apply -f $YAMLFILE "
