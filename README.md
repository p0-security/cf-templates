# cf-templates
Cloudformation templates for AWS Integration with P0 Security

Summary: We will be using a cloudformation template to deploy a stackset in order to create an IAM Role 
for P0 across all children accounts for an organization. Individual stacks will be deployed to a single 
region across all the children accounts. 

In order to cover the management account, we will then be deploying a stack manually via the same stackset 
to target the management account and create the same IAM Role for P0.

Instructions: 
Please copy the current directory to your local instance and execute the following using the AWS Console

# Step 1:   Create P0-IAMRole

## Create IAMRole stack-set

#### For children accounts in an organization: 

1. AWS -> Management Account -> Cloudformation -> StackSets
2. Create StackSet 
    1. Service-managed permissions
    2. Upload the `iam_management.json` template 
    3. Provide a StackSet name like `P0IAMRoleStackSet`
    4. Enter Google Audience ID for P0
    5. Deploy New stacks
    6. Deploy to organization (This will ONLY deploy to children accounts)
    7. Pick a single active region aka `us-west-2`
    8. Submit 

#### For the management account in the organization
1. AWS -> Management Account -> Cloudformation -> Stack
2. Create stack with new resources
    1. Choose an existing template
    2. Upload the `iam_management.json` template
    3. Provide a Stack name like `P0IAMRoleStack`
    4. Enter the Google Audience ID for P0
    5. Submit


> [!CAUTION]
> The work below is in progress


# Step 2: Create Resource Explorer Default View

Cloudformation templates for a Default View in the Resource Explorer with P0 Security

Summary: For execution, we'll be creating 2 roles via a cloudformation template and then we will be 
using 4 cloudformation stacksets two with self-managed permissions and two with service-managed 
permissions. 

For the management account:
1. We'll create a resource lister role for P0 to leverage
2. We'll create an administration and an execution role for cloudformation
3. We'll use these roles to deploy local indexes across all regions except one. 
4. We'll use the same roles to deploy one aggregator index across a single region (us-west-2)

For the children accounts:
1. We'll create a resource lister role for P0 to leverage
2. We'll use service-managed permissions to deploy local indexes across all regions except one 
for all the children accounts. 
3. We'll use service-managed permissions to deploy an aggregator index across one region (us-west-2) 
across all the children accounts.




Instructions: 
Please copy the current directory to your local instance and execute the following using the AWS Console

## A. Create Resource Explorer Index Stack 

#### 1. Create Resource Lister Role for P0 for children accounts

1. AWS -> Cloudformation -> StackSets
2. Create a new stackset using the 'iam_resource_lister.yaml` template
    a. Use service-managed permissions
    b. Upload the `iam_resource_lister.yaml` template
    c. Provide a StackSet name like `P0IAMRoleListerStackSet`
    d. Enter Google Audience ID for P0
    e. Enter TargetAccountID as the parent Account ID (the value doesn't really matter, it'll be overridden)
    f. Deploy new stacks
    g. Deploy to organization
    h. Specify a single region (us-west-2), its not relevant as the IAM role will be global
    i. Submit


#### 2. Create Resource Lister Role for P0 for management account

1. AWS -> Cloudformation -> Stack
2. Create a new stack using existing resources
  a. Choose an existing template
  b. Upload the `iam_resource_lister.yaml` template
  c. Provide a Stack name like `P0IAMRoleListerStack`
  d. Enter Google Audience ID for P0
  e. Enter TargetAccountID as the parent Account ID
  f. Submit

## B. Create Resource Explorer Local Index Stack Set

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
