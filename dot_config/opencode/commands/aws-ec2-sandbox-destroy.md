---
description: Destroy the AWS EC2 sandbox instance
agent: build
---

You are tasked with destroying an existing AWS EC2 sandbox instance. You will first attempt to use local Terraform state, and if that is missing, you will offer an "Aggressive Discovery" mode to find and clean up orphaned AWS resources.

## Step 1: Get Working Directory

Capture the current working directory where the command was invoked:

!`pwd`

Store this directory path and use it for all subsequent operations. All file operations must happen in this directory.

## Step 2: Check for Local Sandbox State

Verify if a sandbox exists in the working directory:

!`test -d .sandbox && test -f .sandbox/terraform.tfstate && echo "EXISTS" || echo "NONE"`

### Case A: Local Sandbox Exists

If the output is "EXISTS", proceed with standard Terraform destruction:

1. **Display Current Sandbox Info**:
   !`test -f .sandbox/output.json && cat .sandbox/output.json || echo "{}"`
   Show the user: Instance ID, Instance Type, Region, Created At, Shutdown Time.

2. **Confirm Destruction**: Inform the user that you're about to destroy the sandbox instance and that this action cannot be undone.

3. **Run Terraform Destroy**: Execute with auto-approve in `.sandbox/` directory.
   !`terraform destroy -auto-approve`

4. **Wait for Instance Termination**:
   !`INSTANCE_ID=$(terraform output -raw instance_id 2>/dev/null || echo ""); if [ ! -z "$INSTANCE_ID" ]; then AWS_REGION=$(terraform output -raw region 2>/dev/null || echo "us-west-2"); echo "⏳ Waiting for instance $INSTANCE_ID to terminate..."; aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID --region $AWS_REGION && echo "✅ Instance $INSTANCE_ID has been terminated"; fi`

5. **Clean Up Files**: Ask the user if they want to remove the `.sandbox/` directory. If yes: `rm -rf .sandbox`.

6. **Update AGENTS.md**: If `.sandbox/` was removed, remove or comment out the "EC2 Sandbox" section in `AGENTS.md`.

### Case B: No Local State Found (Aggressive Discovery)

If the output is "NONE", inform the user that no local sandbox state was found. Ask:
> "No local sandbox state found. Would you like to search AWS for orphaned 'ghost' resources tagged for this project?"

If the user says yes:

1. **Select Search Scope**: Prompt the user to choose the search region(s):
   - **Configured Region**: Only search the region currently configured in AWS CLI/Environment (e.g., `us-west-2`).
   - **All US Regions (Default)**: Search `us-east-1`, `us-east-2`, `us-west-1`, `us-west-2`.
   - **All Active Regions**: Search every region enabled in the AWS account.
   - **Custom**: User provides a specific region or comma-separated list.

2. **Discovery Loop**: 
   Iterate through the selected regions. For each region, search for:
   - **Instances**: `aws ec2 describe-instances --region <REGION> --filters "Name=tag:ManagedBy,Values=opencode-terraform" "Name=tag:Project,Values=<PROJECT_NAME>" "Name=instance-state-name,Values=pending,running,stopping,stopped"`
   - **Security Groups**: `aws ec2 describe-security-groups --region <REGION> --filters "Name=tag:ManagedBy,Values=opencode-terraform" "Name=tag:Project,Values=<PROJECT_NAME>"`

   After regional checks, perform one global check for:
   - **IAM Roles**: Search for roles with names containing `opencode-sandbox` and the `Project` tag.
   - **IAM Instance Profiles**: Search for profiles with names containing `opencode-sandbox` and the `Project` tag.

3. **Present and Confirm**: Group findings by region and resource type. 
   Example:
   ```
   Found in us-west-2:
   - EC2 Instance: i-0abc123... (running)
   - Security Group: sg-0def456...
   
   Found in Global (IAM):
   - Role: opencode-sandbox-role-abc...
   ```
   Ask: "Are you sure you want to permanently destroy these AWS resources?"

4. **Manual Cleanup Sequence**:
   Execute cleanup in this order, being careful to pass the correct `--region` for regional resources:
   - **Terminate Instances**: `aws ec2 terminate-instances --region <REGION> --instance-ids <IDS>`
   - **Wait**: `aws ec2 wait instance-terminated --region <REGION> --instance-ids <IDS>` (Crucial for SG cleanup)
   - **Delete IAM Instance Profiles**: Remove roles first, then delete.
   - **Delete IAM Roles**: Detach all attached policies first, then delete.
   - **Delete Security Groups**: `aws ec2 delete-security-group --region <REGION> --group-id <ID>`

5. **Validate**: Re-run discovery across the same regions to ensure "No resources found".

## Step 3: Display Success Message

Show a success message confirming the cleanup.

```
✅ Sandbox resources destroyed successfully!
```

## Error Handling

- If Terraform destroy fails, suggest manual cleanup using the Aggressive Discovery mode or AWS Console.
- If AWS CLI commands fail (e.g., dependency violation), inform the user and suggest they check for remaining resources.
- Always use the `workdir` parameter for bash commands.
