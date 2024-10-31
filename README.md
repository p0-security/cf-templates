# cf-templates
Cloudformation templates for AWS Integration with P0 Security

Please copy the current directory to your local instance and execute the following commands using this folder as your working directory.

# Step 1:   Create P0-IAMRole

## Create IAMRole stack

```
aws cloudformation create-stack --stack-name P0IamRoleStack --template-body "file://$(pwd)/iam_management.json" \
--capabilities CAPABILITY_NAMED_IAM \
--parameters \
    ParameterKey=GoogleAudienceId,ParameterValue=<p0-google-aud-id> \
    ParameterKey=AwsAccountId,ParameterValue=<aws-account-id>;
```

#### Cleanup (Only if required):

```
aws cloudformation delete-stack --stack-name P0IamRoleStack
```

# Step 2: Create aggregator index


## A. Create Resource Explorer Index Stack 

```
    aws cloudformation create-stack-set \
    --stack-set-name ResourceExplorerIndexStackSet \
    --template-body "file://$(pwd)/resource_explorer_index.json" \
    --capabilities CAPABILITY_NAMED_IAM
```

## B. Create CloudFormation admin and execution role and add to Administrator Access Policy


```
aws cloudformation deploy \
  --template-file create_stackset_roles.json \
  --stack-name StackSetAdminRoleStack \
  --capabilities CAPABILITY_NAMED_IAM
```


## C. Deploy the StackSet instances across all active regions except us-west-2 (we'll use us-west-2 as our aggregator index)
```
aws cloudformation create-stack-instances \
    --stack-set-name ResourceExplorerIndexStackSet \
    --regions $(aws account list-regions --output text --query 'Regions[?(RegionOptStatus!=`DISABLED` && RegionOptStatus!=`DISABLING` && RegionName!=`us-west-2`)].RegionName') \
    --accounts <aws-account-id>
```

Check if an aggregator already exists
```
./check_aggregator.sh
```


## D. Create index in us-west-2 as an aggregator

```
aws cloudformation create-stack-instances \
    --stack-set-name ResourceExplorerIndexStackSet \
    --accounts <aws-account-id> \
    --regions us-west-2 \
    --parameter-overrides ParameterKey=IndexType,ParameterValue=AGGREGATOR
```

## E. Create default view in the aggregator index

```
aws cloudformation deploy \
  --template-file resource_explorer_view.yaml \
  --stack-name ResourceExplorerViewStack \
  --capabilities CAPABILITY_NAMED_IAM \
  --region your-aggregator-region \
  --parameter-overrides AggregatorRegion=your-aggregator-region
```

If you want to use the default (us-west-2) region:
```
aws cloudformation deploy \
  --template-file resource_explorer_view.yaml \
  --stack-name ResourceExplorerViewStack \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-west-2
```




#### Cleanup (only if required):

##### Delete Resource Explorer View:
```
aws cloudformation delete-stack \
  --stack-name ResourceExplorerViewStack \
  --region us-west-2
```

##### Delete Admin and Exec Roles:
```
aws cloudformation delete-stack \
  --stack-name StackSetAdminRoleStack
```

##### Delete Stack Instances:
```
aws cloudformation delete-stack-instances \
  --stack-set-name ResourceExplorerIndexStackSet \
  --regions $(aws account list-regions --output text --query 'Regions[?(RegionOptStatus!=`DISABLED` && RegionOptStatus!=`DISABLING`)].RegionName') \
  --accounts <aws-account-id> \
  --no-retain-stacks
```

##### Delete Stack Set:
```
aws cloudformation delete-stack-set \
    --stack-set-name ResourceExplorerIndexStackSet
```