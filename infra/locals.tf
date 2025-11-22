locals {
  project_name = "fincra-devops"
  cluster_name = "${local.project_name}-eks-cluster"
  environment  = "production"
  region       = "eu-central-1"
  eks_version  = "1.33"

  vpc_cidr = "10.0.0.0/16"

  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]

  availability_zones = ["eu-central-1a", "eu-central-1b"]

  instance_type = "t3.micro"

  cluster_application_namespaces = [
    "hello-world",
    "kube-system",
    "devops"
  ]

  tags = {
    Project     = "fincra-devops"
    Environment = "production"
    ManagedBy   = "terraform"
    Region      = "eu-central-1"
  }
}
