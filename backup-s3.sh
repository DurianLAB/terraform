#!/bin/bash

# Variables
CLOUDFLARE_API_TOKEN="LxQx8pCIxzAo62eSp7kBbZeDx5Cstd3gs2Ag8192"  # Replace with your Cloudflare API token
ZONE_ID="b8eab279d6c45a63db5228e10652c328"                             # Replace with your Cloudflare Zone ID
S3_BUCKET="cloudflare-dns-backup"                    # Replace with your S3 bucket name
BACKUP_FILE="dns_backup_$(date +%Y%m%d_%H%M%S).json"  # Backup file name with timestamp

# Fetch DNS records from Cloudflare
echo "Fetching DNS records for Zone ID: $ZONE_ID..."
RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
-H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
-H "Content-Type: application/json")

# Check if the S3 bucket exists
if aws s3api head-bucket --bucket "$S3_BUCKET" 2>/dev/null; then
    echo "Bucket '$S3_BUCKET' exists."
else
    echo "Bucket '$S3_BUCKET' does not exist or you do not have access."
fi
#
# Check if the request was successful
if [[ $(echo "$RESPONSE" | jq -r '.success') == "true" ]]; then
    echo "DNS records fetched successfully."
    echo "$RESPONSE" > "$BACKUP_FILE"
    echo "Backup saved to $BACKUP_FILE."

    # Upload to S3
    echo "Uploading backup to S3 bucket: $S3_BUCKET..."
    aws s3 cp "$BACKUP_FILE" "s3://$S3_BUCKET/$BACKUP_FILE"

    if [[ $? -eq 0 ]]; then
        echo "Backup uploaded successfully to S3."
    else
        echo "Failed to upload backup to S3."
    fi
else
    echo "Failed to fetch DNS records. Response: $RESPONSE"
fi

