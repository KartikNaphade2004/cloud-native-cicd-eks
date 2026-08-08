locals {
  name = "${var.project}-${var.environment}"

  # Use up to 3 availability zones for high availability.
  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# --------------------------------------------------------------------------
# VPC: public subnets (for the load balancer) + private subnets (for nodes).
# The Kubernetes tags let the AWS Load Balancer Controller discover subnets.
# --------------------------------------------------------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.8"

  name = "${local.name}-vpc"
  cidr = var.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 4, k + 8)]

  enable_nat_gateway = true
  single_nat_gateway = true # one NAT to keep cost down (not HA)
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = local.tags
}

# --------------------------------------------------------------------------
# EKS cluster with a managed node group in the private subnets.
# --------------------------------------------------------------------------
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.11"

  cluster_name    = local.name
  cluster_version = var.cluster_version

  # Public endpoint so you can reach the API from your laptop for the demo.
  cluster_endpoint_public_access = true

  # Give the identity running Terraform admin access to the cluster.
  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Core add-ons managed by EKS.
  cluster_addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni    = {}
  }

  eks_managed_node_groups = {
    default = {
      instance_types = var.node_instance_types

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      # SPOT instances cut worker cost ~70% — great for a demo cluster.
      capacity_type = "SPOT"
    }
  }

  tags = local.tags
}

# --------------------------------------------------------------------------
# ECR repository for the application image.
# --------------------------------------------------------------------------
resource "aws_ecr_repository" "app" {
  name                 = var.project
  image_tag_mutability = "MUTABLE"
  force_delete         = true # allow `terraform destroy` even with images

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.tags
}

# Keep only the 10 most recent images to control storage cost.
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}
