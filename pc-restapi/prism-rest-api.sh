#!/bin/bash

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

AUTH_HEADER="`echo $PCADMIN:$PCPASSWD | base64`"

call_curl(){
    REQUEST=${1} # GET,POST,PATCH
    APIURL=${2} # format : "/v2/boards"
    CALLDATA=${3}  # json post data

    #make the curl more readable
    URL="https://${PCIPADDRESS}:9440/api/"
    
    #URL="https://${PCIPADDRESS}:9440/PrismGateway/services/rest"
    

    case $REQUEST in
        GET)
            RESPONSE=$(curl -s -k -w '####%{response_code}' -u "$PCADMIN:$PCPASSWD" --header 'accept: application/json' --request GET  -H 'X-Nutanix-Client-Type: ui' --url ${URL}${APIURL})
            ;;
        POST)
            if [[ "$CALLDATA" == "" ]]
            then
                echo "call_curl - CALLDATA not set"
                exit 1
            fi
            RESPONSE=$(curl -s -k -w '####%{response_code}' -u "$PCADMIN:$PCPASSWD"  --header 'accept: application/json' -H 'X-Nutanix-Client-Type: ui' --request POST --header 'content-type: application/json' --data "${CALLDATA}" --url ${URL}${APIURL})
            ;;
    esac
    #returns json
    # echo ${RESPONSE} > response.txt
    # echo "${RESPONSE}" |awk -F '####' '{print $1}' > response.json

    HTTPSTATUS=$(echo ${RESPONSE} |awk -F '####' '{print $2}'|xargs)
	case $HTTPSTATUS in
		2[0-9][0-9])    
			RETURNEDJSON=$(echo "${RESPONSE}" |awk -F '####' '{print $1}')
			echo "${RETURNEDJSON}"
			;;
		3[0-9][0-9])    
   			echo "{\"httpStatus\": \"$HTTPSTATUS - Bad Request\"}"
            echo ${RESPONSE} 
			;;
		4[0-9][0-9])    
   			echo "{\"httpStatus\": \"$HTTPSTATUS - Bad Request\"}"
            echo "$REQUEST"
            echo "$APIURL"
            echo "$CALLDATA"
            echo ${RESPONSE}
			;;
		5[0-9][0-9])    
   			echo "{\"httpStatus\": \"$HTTPSTATUS - Server Error \"}"
			;;
		*)      
   			echo "{\"httpStatus\": \"$HTTPSTATUS - unknown Status \"}"
			;;
	esac
}

get_clusters_v4() {
    RESPONSEJSON=$(call_curl "GET" "/clustermgmt/v4.0.b2/config/clusters")
    echo $RESPONSEJSON > clusters.json
    echo $RESPONSEJSON
}

get_aos_clusters(){
    CLUSTERS=$(get_clusters_v4 |jq '.data[]| select(.config.clusterFunction[] == "AOS")|.name,.extId')
    echo $CLUSTERS
}

get_PC_clusters(){
    CLUSTERS=$(get_clusters_v4 |jq '.data[]| select(.config.clusterFunction[] == "PRISM_CENTRAL")|.name,.extId')
    AOSCLUSTERS=$(echo "$CLUSTERS" | jq .)
}