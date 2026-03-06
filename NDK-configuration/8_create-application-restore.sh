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
echo "This script helps create an Application Snapshot Restore CR"
echo

CONTEXTS=$(kubectl config get-contexts --output=name)
echo
echo "Select workload cluster with snapshot to restore or CTRL-C to quit"
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

#Select NDK Snapshot to restore
echo
echo "Select NDK Snapshot to restore or CTRL-C to quit"
APPSNAPSHOTS=$(kubectl get as -A  --no-headers |awk '{print $2}')
select SNAP in $APPSNAPSHOTS; do 
    echo "you selected application snapshot : ${SNAP}"
    echo 
    break
done

#Verify content of snapshot is deleted before restore.
SNAPSHOTNAMESPACE=$(kubectl get as -A  --no-headers |grep ${SNAP} |awk '{print $1}')
if [ $? -ne 0 ]; then
    echo "Error getting Snapshot $SNAP namespace. Exiting."
    exit 1
fi

#Get SnapshotJSON
SNAPJSON=$(kubectl get as $SNAP -n $SNAPSHOTNAMESPACE -o json)
if [ $? -ne 0 ]; then
    echo "Snapshot $SNAP not found. Exiting."
    exit 1
fi

#
SNAPSHOTARTIFACTS=$(echo $SNAPJSON |jq -r '.status.summary.snapshotArtifacts|keys[]')
if [ $? -ne 0 ]; then
    echo "Error getting Snapshot $SNAP artifacts. Exiting."
    exit 1
fi  
for ARTIFACT in $SNAPSHOTARTIFACTS; do
  echo "Snapshot artifact : $ARTIFACT"
  SHORTARTIFACT=$(echo $ARTIFACT |rev | cut -d'/' -f1 |rev)

  ARTIFACTSLIST=$(echo $SNAPJSON |jq --arg ARTIFACT $ARTIFACT -r '.status.summary.snapshotArtifacts[$ARTIFACT][].name')
  if [ $? -ne 0 ]; then
      echo "Error getting Snapshot $SNAP artifact $ARTIFACT list. Exiting."
      exit 1
  fi
  for ARTIFACTNAME in $ARTIFACTSLIST; do

    echo "  Snapshot artifact $SHORTARTIFACT : $ARTIFACTNAME"
    #Check if artifact is deleted
    ARTIFACTCOUNT=$(kubectl get $SHORTARTIFACT $ARTIFACTNAME -n $SNAPSHOTNAMESPACE --no-headers)
    if [ $? -ne 0 ]; then
        echo "      Artifact $SHORTARTIFACT : $ARTIFACTNAME not found. It is deleted."
    else
        echo
        echo "Artifact $SHORTARTIFACT : $ARTIFACTNAME is still present."
        read -p "Press enter to delete or CTRL-C to cancel"
        kubectl delete $SHORTARTIFACT $ARTIFACTNAME -n $SNAPSHOTNAMESPACE
        if [ $? -ne 0 ]; then
            echo "Artifact $SHORTARTIFACT : $ARTIFACTNAME deletion failed."
            exit 1
        fi
    fi
  done
  echo
  echo "All artifacts of type $SHORTARTIFACT are deleted."
  echo
done

echo 
echo "Ready to proceed to snapshot restore for application : $APPNAME"

SNAPRESTOREYAML="apiVersion: dataservices.nutanix.com/v1alpha1
kind: ApplicationSnapshotRestore
metadata:
  name: restore-$SNAP
  namespace: $SNAPSHOTNAMESPACE
spec:
  applicationSnapshotName: $SNAP"

YAMLFILE=./yamls/restore-$SNAP.yaml
echo "$SNAPRESTOREYAML" | yq e > $YAMLFILE
echo "Snapshot restore YAML file created : $YAMLFILE"
kubectl apply -f $YAMLFILE
if [ $? -ne 0 ]; then
    echo "Snapshot restore failed. Exiting."
    exit 1
fi
kubectl get -f $YAMLFILE -w
