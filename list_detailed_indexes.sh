#!/bin/bash

# Fetch all available regions for the account
REGIONS=$(aws ec2 describe-regions --query 'Regions[*].RegionName' --output text)

# Check if regions were found
if [[ -z "$REGIONS" ]]; then
  echo "No regions found for this account."
else
  # Display header for output
  echo "Detailed Index Information:"
  echo "-------------------------------------------------------------"
  echo -e "ARN\t\t\t\t\t\t\t\t\tType\tRegion\t\tState"
  echo "-------------------------------------------------------------"

  # Loop through each region and retrieve the index details
  for REGION in $REGIONS; do
    echo "Checking region: $REGION"
    
    # Get index information in the current region
    DETAILS=$(aws resource-explorer-2 get-index --region "$REGION" --query '[Arn,Type,State]' --output text 2>/dev/null)

    # Check if DETAILS is non-empty
    if [[ -n "$DETAILS" ]]; then
      INDEX_ARN=$(echo "$DETAILS" | awk '{print $1}')
      INDEX_TYPE=$(echo "$DETAILS" | awk '{print $2}')
      INDEX_STATE=$(echo "$DETAILS" | awk '{print $3}')
      
      # Display the details for the active index
      echo -e "$INDEX_ARN\t$INDEX_TYPE\t$REGION\t$INDEX_STATE"
    else
      echo "No index found or accessible in region: $REGION"
    fi
  done
fi
