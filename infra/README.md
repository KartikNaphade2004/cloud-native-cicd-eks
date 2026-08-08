# Infrastructure (Terraform)

Provisions everything the app runs on in AWS:

| Resource | Purpose |
|----------|---------|
| VPC (3 AZs, public + private subnets, 1 NAT) | Network isolation |
| EKS cluster (Kubernetes) | Runs the containerized app |
| Managed node group (SPOT `t3.medium`) | Worker nodes (cheap, auto-scaling 1–3) |
| ECR repository | Stores the app container image |
| GitHub OIDC provider + IAM role | Lets CI push images with **no stored AWS keys** |

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.5
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) configured (`aws configure`) with an account that can create VPC/EKS/IAM
- `kubectl`

## Usage

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars   # edit if you like

terraform init
terraform plan       # review what will be created
terraform apply      # ~15 min to build the cluster
```

Point `kubectl` at the new cluster (command is printed as an output):

```bash
aws eks update-kubeconfig --region us-east-1 --name cloud-native-cicd-dev
kubectl get nodes
```

## 💰 Cost & teardown

A running EKS cluster costs roughly **$0.10/hr control plane + SPOT nodes + NAT
(~$3–5/day if left on)**. **Always destroy when you're done demoing:**

```bash
terraform destroy
```

State (`terraform.tfstate`) and `terraform.tfvars` are gitignored so nothing
sensitive is committed.

## Wiring CI to push images (after apply)

`terraform apply` prints `github_ci_role_arn`. Add it to the GitHub repo as a
secret named `AWS_ROLE_ARN` (Settings → Secrets and variables → Actions). The CI
workflow then assumes that role and pushes to ECR automatically — no access keys.
