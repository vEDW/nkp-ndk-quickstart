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
echo "Select workload cluster on which to install agent or CTRL-C to quit"
select CONTEXT in $CONTEXTS; do 
    echo "you selected cluster context : ${CONTEXT}"
    echo 
    CLUSTERCTX="${CONTEXT}"
    break
done

kubectl config use-context $CLUSTERCTX
if [ $? -ne 0 ]; then
    echo "kubectl context error. Exiting."
    exit 1
fi

CSICREDS=$(kubectl get secret nutanix-csi-credentials -n ntnx-system -o yaml |yq e '.data.key' |base64 -d)
CSIPC=$(echo $CSICREDS |awk -F ':' '{print $1}' )
CSIUSER=$(echo $CSICREDS |awk -F ':' '{print $3}' )
CSIPASSWD=$(echo $CSICREDS |awk -F ':' '{print $4}' )
export PCADMIN=$CSIUSER
export PCPASSWD=$CSIPASSWD
export PCIPADDRESS=$CSIPC

source ../pc-restapi/prism-rest-api.sh
echo echo "getting aos clusters"
PENAMES=$(get_aos_clusters_name) 
select PENAME in $PENAMES; do 
    echo "you selected PE Cluster : ${PENAME}"
    echo 
    PENAME="${PENAME}"
    PENAMELOWERCASE=$(echo "${PENAME}"| tr '[:upper:]' '[:lower:]' )
    break
done

echo $PENAME
echo
PEUUID=$(get_aos_clusters_uuid $PENAME)
if [ "$PEUUID" == "" ]; then
    echo "getting PE $PENAME UUID error. Exiting."
    exit 1
fi

echo $PEUUID
echo
echo "getting PC clusters"

PCUUID=$(get_PC_clusters_uuid)
if [ "$PCUUID" == "" ]; then
    echo "getting PC UUID error. Exiting."
    exit 1
fi

echo $PCUUID
echo

SCS=$(kubectl get sc -A|grep nutanix |awk '{print $1}')

StorageCluster="apiVersion: dataservices.nutanix.com/v1alpha1
kind: StorageCluster
metadata:
 name: $PENAMELOWERCASE
spec:
 storageServerUuid: $PEUUID
 managementServerUuid: $PCUUID"

YAMLFILE=applicationcr-$PENAME.yaml

echo "$StorageCluster" | yq e > storagecluster-$PENAME.yaml
echo "storagecluster-$PENAME.yaml created"
echo 
echo "run : kubectl apply -f storagecluster-$PENAMELOWERCASE.yaml to apply to cluster"
