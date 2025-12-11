# AWS Infrastructure Repository

This repository manages AWS infrastructure using **Terraform**, organized into reusable modules and environment-specific configurations. It utilizes **GitHub Actions** with **AWS CodeBuild-hosted runners** for secure and efficient CI/CD deployment.

## 📂 Repository Structure

- **`modules/`**: Contains reusable Terraform modules (Compute, Networking, Data, Security).
- **`dev/`**: The live configuration for the **Development** environment, consuming the modules.
- **`.github/workflows/`**: CI/CD pipeline definitions.

## 🚀 CI/CD Pipeline (GitHub Actions + AWS CodeBuild)

This project uses a **"Plan on Push, Apply on Click"** workflow to balance automation with control and cost efficiency.

### 1. Automated Planning (On Push)
- **Trigger**: Any push to the `main` branch affecting `dev/` or `modules/` directories.
- **Action**: Runs `terraform plan` automatically.
- **Runner**: Uses an ephemeral AWS CodeBuild runner.
- **Output**: You can review the plan in the GitHub Actions run logs.

### 2. Manual Application (On Demand)
- **Trigger**: Manual `workflow_dispatch` event.
- **Action**: Runs `terraform apply -auto-approve`.
- **How to Run**:
    1. Go to the **Actions** tab in GitHub.
    2. Select the **Terraform Dev Deployment** workflow.
    3. Click **Run workflow**.
    4. **Check the box**: "Check to run Terraform Apply".
    5. Click **Run workflow**.

> **Note**: This setup ensures you are not billed for CodeBuild runner time while waiting for approvals.

### 🛠 CodeBuild Runner Configuration
The workflow targets a self-hosted runner provided by AWS CodeBuild.
- **Project Name**: `vinay-github-aws-infra-runner`
- **Runner Label**: `codebuild-vinay-github-aws-infra-runner-${{ github.run_id }}-${{ github.run_attempt }}`
- **Webhook Filter**: configured to match the dynamic label format.

## 💻 Local Development

To run Terraform locally:

1. **Prerequisites**:
   - [Terraform](https://www.terraform.io/) (v1.14.1+)
   - [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials.

2. **Initialize**:
   ```bash
   cd dev
   terraform init
   ```

3. **Plan**:
   ```bash
   terraform plan
   ```

4. **Apply**:
   ```bash
   terraform apply
   ```

## 🔒 Security
- **State Management**: Terraform state is stored securely in an S3 bucket (`vinay-terraform-state-dev`) with S3 native locking (`use_lockfile = true`).
- **Permissions**: The CI/CD pipeline uses OIDC authentication (assuming an IAM role) to avoid storing long-lived AWS keys in GitHub Secrets.