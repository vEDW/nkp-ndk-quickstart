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
echo "Select workload cluster on which to configure Application Snapshot CR  or CTRL-C to quit"
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
#Select source namespace
echo
echo "Listing namespaces with Application CR defined"
echo
NAMESPACES=$(kubectl get application --all-namespaces --no-headers=true |awk '{print $1}' |sort -u)
#check if empty
if [ -z "$NAMESPACES" ]; then
    echo "No namespaces with application found. Please create an Application first."
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

echo "select application to create snapshot for :"
APPS=$(kubectl get application -n $SOURCENAMESPACE --no-headers=true |awk '{print $1}')
select APP in $APPS; do 
    echo "you selected application : ${APP}"
    echo 
    APPNAME="${APP}"
    break
done
SNAPDATE=$(date '+%Y-%m-%d-%Hh%M')

ApplicationSnapshotYAML="apiVersion: dataservices.nutanix.com/v1alpha1
kind: ApplicationSnapshot
metadata:
  name: $APPNAME-$SNAPDATE
  namespace: $SOURCENAMESPACE
spec:
  source:
    applicationRef:
      name: $APPNAME 
  expiresAfter: 240m"

YAMLFILE=./yamls/appsnapshot-$APPNAME.yaml

echo "$ApplicationSnapshotYAML" | yq e > $YAMLFILE
kubectl apply -f $YAMLFILE
kubectl get -f $YAMLFILE -w
