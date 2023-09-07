#!/bin/bash
set -ue

source ._make_overrides || true


get_zone() {
    zone=$(aws route53 list-hosted-zones | jq -r --arg d "${TF_VAR_domain_name}." '.HostedZones[] | select(.Name==$d) | .Id' | tr -d '\/hostedzone\/')
    echo "Hosted zone ID: ${zone}! 🌐"
}


get_record_data() {
    record_data=$(aws route53 list-resource-record-sets --hosted-zone-id "${zone}" --query "ResourceRecordSets[?Name == '${fullrecord}']")
    record_count=$(echo "${record_data}" | jq '. | length')
}

generate_json() {
echo """{
  \"Comment\": \"Automated update to Route53 record\",
  \"Changes\": [
    {
      \"Action\": \"DELETE\",
      \"ResourceRecordSet\": ${record}
    }
  ]
}""" > "${PWD}"/.TemporaryItems/r53.json.json
}

delete_record() {
    aws route53 change-resource-record-sets --hosted-zone-id "${zone}" --change-batch file://"${PWD}"/.TemporaryItems/r53.json.json
    
    if [[ $? -eq 0 ]] ; then
      echo "Success! ${fullrecord} record change is in the bag. 🚀"
    else
      echo "Oh no! ${fullrecord} record change got the cold shoulder. ❌"
      exitcode=1
    fi
}


r53sweep() {
    exitcode=0
    get_zone
    mkdir -p .TemporaryItems
    for fullrecord in $(aws route53 list-resource-record-sets --hosted-zone-id ${zone} | jq -r '.ResourceRecordSets[].Name'| grep ".${TF_VAR_stack_name}.${TF_VAR_domain_name}.") ; do

        # fullrecord=${record}.${TF_VAR_domain_name}.
        get_record_data
        echo -n "record_data: "
        echo "${record_data}" | jq -r '[.[] | {(.Name): .Type}]'   
        echo "record_count: ${record_count}"

        if [[ ${record_count} -gt 0 ]] ; then

            echo "🪄 Abracadabra! ${record_count} DNS records named ${fullrecord} are vanishing!"
            counter=0
            counter_max=$(( ${record_count} - 1 ))

                while [[ ${counter} -le ${counter_max} ]] ; do

                    echo "counter: ${counter}"
                    echo "counter_max: ${counter_max}"
                    record=$(echo "${record_data}" | jq -r ".[${counter}]")
                    # echo "record: ${record}"
                    echo "Cooking up some JSON magic:"
                    generate_json
                    delete_record
                    counter=$(( ${counter} + 1 ))
                done
        else
            echo "No DNS records ${fullrecord} slipped through the DNS cracks! 🕳️"
        fi
    done

    return ${exitcode}
}

r53sweep
