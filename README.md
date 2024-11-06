# cf-templates
Cloudformation templates for AWS Integration with P0 Security

Please copy the current directory to your local instance and execute the following commands using this folder as your working directory.

# Step 1:   Create P0-IAMRole

## Create IAMRole stack-set

1. Deploy the `iam_management.json` template as a stackset via the Management/Parent account across all children accounts. 
  a. Pick all the children accounts to deploy the Role to. [Note: this will not get deployed in the management account]
  b. Pick any one region to deploy the stack to. 

2. Deploy the `iam_management.json` template as a stack just for the Management account. 


Commands to deploy it across all children accounts: 
```
aws cloudformation create-stack-set \
  --stack-set-name P0IamRoleStackSet \
  --template-body file://iam_management.json \
  --parameters ParameterKey=GoogleAudienceId,ParameterValue=<your-google-audience-id> \
  --capabilities CAPABILITY_NAMED_IAM \
  --permission-model SERVICE_MANAGED \
  --auto-deployment Enabled=true,RetainStacksOnAccountRemoval=false
```

```
aws cloudformation create-stack-instances \
  --stack-set-name P0IamRoleStackSet \
  --deployment-targets AccountIds='["111122223333","444455556666","777788889999"]' \
  --regions us-west-2
```

#### Cleanup (Only if required):

```
aws cloudformation delete-stack-instances \
  --stack-set-name P0IamRoleStackSet \
  --regions us-east-1 \
  --deployment-targets AccountIds='["123456789012","234567890123","345678901234"]' \
  --no-retain-stacks \
  --operation-preferences FailureToleranceCount=1,MaxConcurrentCount=2
```

```
aws cloudformation delete-stack-set \
  --stack-set-name P0IamRoleStackSet
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

## F. Create a new role that allows referencing the indexes
```
aws cloudformation deploy \
  --template-file Iam_resource_lister.yaml \
  --stack-name P0RoleIamResourceListerStack \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    GoogleAudienceId=<goog-aud-id> \
    TargetAccountId=<aws-acccount-id>
```


#### Cleanup (only if required):

##### Delete Resource Explorer View:
```
aws cloudformation delete-stack \
  --stack-name ResourceExplorerViewStack \
  --region us-west-2
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

##### Delete Admin and Exec Roles:
```
aws cloudformation delete-stack \
  --stack-name StackSetAdminRoleStack
```
