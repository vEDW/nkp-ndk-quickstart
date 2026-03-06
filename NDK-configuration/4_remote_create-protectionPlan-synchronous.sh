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
echo "This script helps create Sync Protection Plan CR"
echo 

CONTEXTS=$(kubectl config get-contexts --output=name)
echo
echo "Select workload cluster on which to configure Sync Protection Plan CR or CTRL-C to quit"
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
echo "Listing namespaces with Replication Target defined"
echo
NAMESPACES=$(kubectl get replicationtarget --all-namespaces --no-headers=true |awk '{print $1}' |sort -u)
#check if empty
if [ -z "$NAMESPACES" ]; then
    echo "No namespaces with Replication Target found. Please create a Replication Target first."
    exit 1
fi

echo
echo "Select namespace to protect or CTRL-C to quit"
select NAMESPACE in $NAMESPACES; do 
    echo "you selected source namespace : ${NAMESPACE}"
    echo 
    SOURCENAMESPACE="${NAMESPACE}"
    break
done

#select ReplicationTarget in selected namespace
REPLICATIONTARGETS=$(kubectl get replicationtarget -n $SOURCENAMESPACE --no-headers=true |awk '{print $1}' |sort -u)
#check if empty
if [ -z "$REPLICATIONTARGETS" ]; then
    echo "No Replication Targets found in namespace $SOURCENAMESPACE. Please create a Replication Target first."
    exit 1
fi 

echo
echo "Select replication target or CTRL-C to quit"
select REPLICATIONTARGET in $REPLICATIONTARGETS; do 
    echo "you selected replication target : ${REPLICATIONTARGET}"
    echo 
    break
done
#Select Replication Target in namespace

PROTECTIONPLAN="apiVersion: dataservices.nutanix.com/v1alpha1
kind: ProtectionPlan
metadata: 
 name: $SOURCENAMESPACE-sync-protection-plan
 namespace: $SOURCENAMESPACE
spec: 
 protectionType: sync
 replicationConfigs:
   - replicationTargetName: $REPLICATIONTARGET"

YAMLFILE=./yamls/ndk-$SOURCENAMESPACE-$REPLICATIONTARGET-ProtectionPlan.yaml


echo "$PROTECTIONPLAN" | yq e > $YAMLFILE
echo "$YAMLFILE created"
echo 
echo "run to apply to cluster:"
echo "kubectl apply -f $YAMLFILE "
