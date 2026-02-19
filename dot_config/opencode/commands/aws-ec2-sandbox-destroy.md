---
description: Destroy the AWS EC2 sandbox instance
agent: build
---

You are tasked with destroying an existing AWS EC2 sandbox instance managed by Terraform.

## Step 1: Get Working Directory

Capture the current working directory where the command was invoked:

!`pwd`

Store this directory path and use it for all subsequent operations. All file operations must happen in this directory.

## Step 2: Check if Sandbox Exists

Verify that a sandbox exists in the working directory. Use the bash tool with `workdir` parameter set to the working directory:

!`test -d .sandbox && test -f .sandbox/terraform.tfstate && echo "EXISTS" || echo "NONE"`

If the output is "NONE", inform the user that no sandbox exists and stop execution.

## Step 3: Display Current Sandbox Info

If a sandbox exists, read and display its current information from `<working_directory>/.sandbox/output.json`.

Use the Read tool with `filePath` set to `<working_directory>/.sandbox/output.json`, or use bash with workdir parameter:

!`test -f .sandbox/output.json && cat .sandbox/output.json || echo "{}"`

Show the user:
- Instance ID
- Instance Type
- Region
- Created At
- Shutdown Time

## Step 4: Confirm Destruction

Inform the user that you're about to destroy the sandbox instance and that this action cannot be undone.

## Step 5: Run Terraform Destroy

Execute Terraform destroy with auto-approve and wait for completion. Use the bash tool with `workdir` parameter set to `<working_directory>/.sandbox`:

!`terraform destroy -auto-approve`

## Step 6: Wait for Instance Termination

After Terraform completes, wait for the instance to fully terminate to ensure cleanup is complete.

Get the instance ID and region from terraform outputs, then wait for termination. Use the bash tool with `workdir` parameter set to `<working_directory>/.sandbox`:

!`INSTANCE_ID=$(terraform output -raw instance_id 2>/dev/null || echo ""); if [ ! -z "$INSTANCE_ID" ]; then AWS_REGION=$(terraform output -raw region 2>/dev/null || echo "us-west-2"); echo "⏳ Waiting for instance $INSTANCE_ID to terminate..."; aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID --region $AWS_REGION && echo "✅ Instance $INSTANCE_ID has been terminated"; fi`

## Step 7: Clean Up Files (Optional)

Ask the user if they want to remove the entire `.sandbox/` directory from the working directory. Explain that this will delete:
- All Terraform configuration files
- Terraform state files
- Output JSON file

If they choose yes, use the bash tool with `workdir` parameter set to the working directory:

!`rm -rf .sandbox`

If they choose no, just leave the files in place. They may want to inspect the Terraform state or keep the configuration for future use.

## Step 8: Update AGENTS.md (if .sandbox was removed)

If the `.sandbox/` directory was removed, update `AGENTS.md` in the working directory to remove or comment out the EC2 Sandbox section.

Use the Read tool to check if `<working_directory>/AGENTS.md` exists and contains an "EC2 Sandbox" section. If it does, you can either:
1. Remove the entire section using the Edit tool
2. Add a note that the sandbox has been destroyed

Use the Edit tool with `filePath` set to `<working_directory>/AGENTS.md`.

## Step 9: Display Success Message

Show a success message confirming the sandbox has been destroyed.

Example format:
```
✅ EC2 Sandbox destroyed successfully!

The sandbox instance has been terminated and all AWS resources have been cleaned up.

.sandbox/ directory: [kept/removed based on user choice]
```

## Error Handling

- If Terraform destroy fails, show the error and suggest manual cleanup via AWS Console
- If the instance termination wait fails, inform the user but note that Terraform has already issued the termination command
- Preserve error messages for debugging

## Important Notes

- **Working Directory**: Capture the working directory at the start (Step 1) and use it consistently throughout
- **Bash Tool Usage**: Use the `workdir` parameter for all bash commands to ensure they execute in the correct location
- **File Paths**: Use absolute paths constructed from `<working_directory>` for all Read and Edit tool operations
- **Critical**: The `rm -rf .sandbox` command in Step 7 must use the workdir parameter to ensure the correct directory is deleted
- **Critical**: Never use relative paths with `cd` commands - always use the `workdir` parameter instead
