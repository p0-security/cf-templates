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


# Step 2: Create Resource Explorer Default View

#### 1. Create Resource Lister Role for P0 for children accounts

1. AWS -> Cloudformation -> StackSets
2. Create a new stackset using the 'iam_resource_lister.yaml` template
    1. Use service-managed permissions
    2. Upload the `iam_resource_lister.yaml` template
    3. Provide a StackSet name like `P0IAMRoleListerStackSet`
    4. Enter Google Audience ID for P0
    5. Enter TargetAccountID as the parent Account ID (the value doesn't really matter, it'll be overridden)
    6. Deploy new stacks
    7. Deploy to organization
    8. Specify a single region (us-west-2), its not relevant as the IAM role will be global
    9. Submit


#### 2. Create Resource Lister Role for P0 for management account

1. AWS -> Cloudformation -> Stack
2. Create a new stack using existing resources
    1. Choose an existing template
    2. Upload the `iam_resource_lister.yaml` template
    3. Provide a Stack name like `P0IAMRoleListerStack`
    4. Enter Google Audience ID for P0
    5. Enter TargetAccountID as the parent Account ID
    6. Submit

## B. Create Resource Explorer Local Indexes for children accounts

1. AWS -> Cloudformation -> StackSets
2. Create a new stackset 
    1. Use service-managed permissions
    2. Upload the `resource_explorer_local_index.yaml` template
    3. Provide a StackSet name like `LocalIndexStackSetForChildAccounts`
    4. Deploy new stacks
    5. Deploy to organization
    6. Specify all active regions except one (which will be used for the aggregator index, we can use `us-west-2` as the exception)
    7. Submit

## C. Create Resource Explorer Local Indexes for the management account

1. We'll be creating new IAM roles to use for self-managed permissions for the CF templates.
2. AWS -> Cloudformation -> Stacks
3. Create a new stack using existing resources
    1. Choose an existing template
    2. Upload the `stack_set_roles.yaml` template
    3. Provide a Stack Name like `StackSetRoles`
    4. Submit
4. Now we'll create the local indexes in the management account
5. AWS -> Cloudformation -> StackSets
6. Create a new stack set 
    1. Use self-service permissions
    2. Use IAM admin role created in step 3 - `AWSCloudFormationStackSetAdministrationRole`
    3. Use IAM execution role created in step 3  - `AWSCloudFormationStackSetExecutionRole`
    4. Upload same template from Step B.2 - `resource_explorer_local_index.yaml`
    5. Provide a StackSet name like `LocalIndexStackSetForParentAccount`
    6. Deploy stack sets in accounts: Put in the management account ID
    7. Specify all active regions except one (which will be used for the aggregator index, we can use `us-west-2` as the exception)
    8. Submit

## D. Create Resource Explorer Aggregator Index for children accounts

1. AWS -> Cloudformation -> StackSets
2. Create a new stackset 
    1. Use service-managed permissions
    2. Upload the `resource_explorer_aggregator_index.yaml` template
    3. Provide a StackSet name like `AggregatorIndexStackSetForChildAccounts`
    4. Deploy new stacks
    5. Deploy to organization
    6. Specify the excluded active region from Step B.2.vi (e.g. `us-west-2`)
    7. Submit

## E. Create Resource Explorer Aggregator Index for the management account

1. We'll be using the same IAM roles as in Step C.3
2. AWS -> Cloudformation -> StackSets
3. Create a new stack set 
    1. Use self-service permissions
    2. Use IAM admin role created in step C.3 - `AWSCloudFormationStackSetAdministrationRole`
    3. Use IAM execution role created in step C.3  - `AWSCloudFormationStackSetExecutionRole`
    4. Upload same template from Step D.2 - `resource_explorer_aggregator_index.yaml`
    5. Provide a StackSet name like `AggregatorIndexStackSetForParentAccount`
    6. Deploy stack sets in accounts: Put in the management account ID
    7. Specify the excluded active region from Step C.6.vii (e.g. `us-west-2`)
    8. Submit

## F. Create default view in the aggregator index for children accounts

1. AWS -> Cloudformation -> StackSets
2. Create a new stackset 
    1. Use service-managed permissions
    2. Upload the `resource_explorer_view.yaml` template
    3. Provide a StackSet name like `ResourceExplorerViewStackSetForChildAccounts`
    4. Set aggregator region to `us-west-2`
    5. Deploy new stacks
    6. Deploy to organization
    7. Specify the same aggregator region as Step D.2.vi
    8. Submit

## G. Create default view in the aggregator index for the management account

1. AWS -> Cloudformation -> Stacks
2. Create a new stack using existing resources
    1. Choose an existing template
    2. Upload the `resource_explorer_view.yaml` template
    3. Provide a Stack name like `ResourceExplorerViewStack`
    4. Specify the aggregator region as Step E.3.vii (`us-west-2`)
    5. Enter TargetAccountID as the parent Account ID
    6. Submit
