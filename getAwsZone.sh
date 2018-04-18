#!/bin/bash

DST="/home/george/dns_backup/backup";
ZONE_ID="Z1AP1YP3QDRHMT";
DATE=`date +"%Y-%m-%d-%H%M%S"`

aws route53 list-resource-record-sets --hosted-zone-id $ZONE_ID --output json > $DST/backup_$DATE.json

