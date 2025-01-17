#!/usr/bin/env bash
source $(dirname "$0")/sweagle.env

##########################################################################
#############
#############   UPLOAD A CONFIG FILE TO SWEAGLE IN SPECIFIC PATH
#############
############# Input: 1- Path to upload to, defined by each of the node names separated by ,
############# Input: 2- Config file to upload
############# Output: 0 if no errors, 1 + Details of errors if any
##########################################################################
if [ "$#" -lt "2" ]; then
    echo "********** ERROR: NOT ENOUGH ARGUMENTS SUPPLIED"
    echo "********** YOU SHOULD PROVIDE 1-NODEPATH AND 2-FILE TO UPLOAD"
    exit 1
fi
argNodePath=$1
argFile=$2

if ! [[ -f "${argFile}" ]] ; then
    echo "********** ERROR: Argument $argFile is not a file, exiting";
    exit 1
fi

function apiUrl() {
cat <<EOF
$sweagleURL/api/v1/data/bulk-operations/dataLoader/upload?nodePath=$argNodePath&format=$argFormat&allowDelete=$argDeleteData&autoApprove=$argDcsApprove&storeSnapshotResults=$argSnapshotCreate&validationLevel=$argSnapshotLevel
EOF
}

function loadDefaultSettings () {
    #general settings for the REST data upload
    argDeleteData="false"
    argDcsApprove="true"
    # don't store snapshot now to be able to validate with custom validators later
    argSnapshotCreate="false"
    argSnapshotLevel="warn"
    # Possible values validOnly | warn | error
    # Automatically store the snaphot depending on validation status
    # cf. https://support.sweagle.com/t/36fkd5/2017-09-08-release
}

echo "*** Define config format based on file extension"
filename=$(basename "$argFile")
extension="${filename##*.}"
#file name without extension if you want to add it to node path
#filename=$(basename "${argFile%.*}")
if [ "$extension" == "json" ]; then
  argFormat="json"
  argContentType="application/json"
elif [ "$extension" == "xml" ]; then
  argFormat="xml"
  argContentType="application/xml"
elif [ "$extension" == "yml" ] || [ "$extension" == "yaml" ]; then
  argFormat="yml"
  argContentType="application/x-yaml"
else
  # if not identified, consider file as property file
  argFormat="properties"
  argContentType="text/x-java-properties"
fi
echo "File extension detected is: "$argFormat

echo "load API default settings..."
loadDefaultSettings
#set the values for each of the configuration data items
#deployDateTime=$( date '+%F %H:%M:%S' )

echo -e "\n**********"
echo "*** Call Sweagle API to upload configuration data & store snapshot for file: $filename"
# For debugging purpose only, use echo below
#echo "(curl -s -X POST '$(apiUrl)' -H '$(apiToken)' -H 'Content-Type: $argContentType' --data-binary '@$argFile')"
response=$(curl -s -X POST "$(apiUrl)" -H "$(apiToken)" -H "Content-Type: $argContentType" --data-binary "@$argFile")
echo "Sweagle response: "$response
if [[ $response = "{\"error\":"* ]]; then
 	echo -e "\n********** ERROR: Unable to upload configuration file: $filename\n"
  exit 1
fi
