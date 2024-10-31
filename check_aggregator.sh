#!/bin/bash

# Step 1: Check if an AGGREGATOR index exists in any region
AGGREGATOR_DETAILS=$(aws resource-explorer-2 list-indexes --query "Indexes[?Type=='AGGREGATOR'].[Arn]" --output text)

if [[ -n $AGGREGATOR_DETAILS ]]; then
  # Extract the region from the ARN (second field of the ARN, e.g., arn:aws:resource-explorer-2:<region>:...)
  AGGREGATOR_ARN=$(echo "$AGGREGATOR_DETAILS" | awk '{print $1}')
  AGGREGATOR_REGION=$(echo "$AGGREGATOR_ARN" | cut -d':' -f4)
  
  echo "An AGGREGATOR index already exists in region '$AGGREGATOR_REGION' with ARN: $AGGREGATOR_ARN"
  echo "No further action is needed."
  exit 0
else
  # No AGGREGATOR found, proceed to check or create in us-west-2
  echo "No AGGREGATOR index found in any region. Checking for actions to take in us-west-2..."
fi

# Step 2: Check if an index exists in us-west-2 and its state
INDEX_DETAILS=$(aws resource-explorer-2 get-index --region us-west-2 --query '[Arn,Type,State]' --output text 2>/dev/null)

if [[ -z $INDEX_DETAILS ]]; then
  # No index exists in us-west-2; suggest creating a new AGGREGATOR index
  echo "No index found in us-west-2. Recommended action:"
  echo "Create a new AGGREGATOR index in us-west-2"
else
  # Parse existing index details
  IFS=$'\t' read -r INDEX_ARN INDEX_TYPE INDEX_STATE <<< "$INDEX_DETAILS"
  
  if [[ $INDEX_STATE == "DELETED" ]]; then
    # Index is deleted; suggest creating a new AGGREGATOR index
    echo "An index exists in us-west-2 but is in the DELETED state. Recommended action:"
    echo "Create a new AGGREGATOR index in us-west-2"
  elif [[ $INDEX_TYPE == "AGGREGATOR" ]]; then
    # Aggregator index already exists in us-west-2
    echo "An AGGREGATOR index already exists in us-west-2: $INDEX_ARN"
    echo "No further action is needed."
  else
    # LOCAL index exists and is active; suggest promoting to AGGREGATOR
    echo "A LOCAL index exists in us-west-2: $INDEX_ARN. Recommended action:"
    echo "Promote the existing index to AGGREGATOR."
  fi
fi
