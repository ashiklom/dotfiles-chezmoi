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

1. **Discovery**: Search for resources tagged with `ManagedBy=opencode-terraform` and `Project=<current_dir_basename>`.
   Run these discovery commands:
   ```bash
   PROJECT_NAME=$(basename $(pwd))
   # Instances
   aws ec2 describe-instances --filters "Name=tag:ManagedBy,Values=opencode-terraform" "Name=tag:Project,Values=$PROJECT_NAME" "Name=instance-state-name,Values=pending,running,stopping,stopped" --query "Reservations[].Instances[].{ID:InstanceId,Type:InstanceType,State:State.Name}" --output table
   # Security Groups
   aws ec2 describe-security-groups --filters "Name=tag:ManagedBy,Values=opencode-terraform" "Name=tag:Project,Values=$PROJECT_NAME" --query "SecurityGroups[].{ID:GroupId,Name:GroupName}" --output table
   # IAM Roles
   aws iam list-roles --query "Roles[?contains(RoleName, 'opencode-sandbox')].RoleName" --output text # Filter further in your logic
   ```

2. **Present and Confirm**: List all found IDs/Names to the user and ask: "Are you sure you want to permanently destroy these AWS resources?"

3. **Manual Cleanup Sequence**:
   If confirmed, execute cleanup in this order (handling errors gracefully):
   - **Instances**: `aws ec2 terminate-instances --instance-ids <IDS>`
   - **Wait**: `aws ec2 wait instance-terminated --instance-ids <IDS>` (Crucial for SG cleanup)
   - **IAM Instance Profiles**: Find, detach roles, and delete.
     `aws iam list-instance-profiles --query "InstanceProfiles[?contains(InstanceProfileName, 'opencode-sandbox')].InstanceProfileName"`
   - **IAM Roles**: Detach policies and delete.
   - **Security Groups**: `aws ec2 delete-security-group --group-id <ID>`

4. **Validate**: Run the discovery commands again to ensure "No resources found".

## Step 3: Display Success Message

Show a success message confirming the cleanup.

```
✅ Sandbox resources destroyed successfully!
```

## Error Handling

- If Terraform destroy fails, suggest manual cleanup using the Aggressive Discovery mode or AWS Console.
- If AWS CLI commands fail (e.g., dependency violation), inform the user and suggest they check for remaining resources.
- Always use the `workdir` parameter for bash commands.
