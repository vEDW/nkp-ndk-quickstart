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

NSS=$(kubectl get ns --no-headers=true |awk '{print $1}')
select NS in $NSS; do 
    echo "you selected namespace : ${NS}"
    echo 
    APPNS="${NS}"
    break
done

APPS=$(kubectl get deployments -n $APPNS --no-headers=true |awk '{print $1}')
select APP in $APPS; do 
    echo "you selected application : ${APP}"
    echo 
    APPNAME="${APP}"
    break
done

SNAPSHOTS=$(kubectl get as -n $APPNS -o yaml |APPNAME=$APPNAME yq e '.items[] |select(.spec.source.applicationRef.name="env(APPNAME)")|.metadata.name')
select SNAP in $SNAPSHOTS; do 
    echo "you selected application snapshot : ${SNAP}"
    echo 
    SNAPNAME="${SNAP}"
    break
done
PVCs=$(kubectl get deploy  -n $APPNS $APPNAME -o yaml |yq e '.spec.template.spec.volumes[].persistentVolumeClaim.claimName')

echo 
echo "Ready to proceed to snapshot restore for application : $APPNAME"
echo "This will delete current application deployment"
echo "and related PVCs : $PVCS"
read -p "press enter to proceed or CTRL-C to cancel" 

#kubectl delete deployment -n $APPNS $APPNAME
if [ $? -ne 0 ]; then
    echo "application deletion failed. Exiting."
    exit 1
fi

for PVC in $PVCs;
do
  echo "deleting PVC : $PVC"
  kubectl delete pvc -n $APPNS $PVC
  if [ $? -ne 0 ]; then
    echo "PVC $PVC deletion failed."
  fi
done

echo
echo "Application and PVC(s) deleted. Proceeding to snapshot restore"
echo

SNAPRESTOREYAML="apiVersion: dataservices.nutanix.com/v1alpha1
kind: ApplicationSnapshotRestore
metadata:
  name: restore-$APPNAME-$SNAPNAME
  namespace: $APPNS
spec:
  applicationSnapshotName: $SNAPNAME"

YAMLFILE=restore-$APPNAME-$SNAPNAME.yaml
echo "$SNAPRESTOREYAML" | yq e > $YAMLFILE
kubectl apply -f $YAMLFILE
kubectl get -n $APPNS deploy,pvc,pod,svc,pv
