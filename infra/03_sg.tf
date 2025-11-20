
# EKS Cluster Security Group
resource "aws_security_group" "eks_cluster" {
  name_prefix = "${local.project_name}-eks-cluster-sg"
  vpc_id      = aws_vpc.main.id
  description = "Security group for EKS cluster"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all egress"
  }

  tags = {
    Name = "${local.project_name}-eks-cluster-sg"
  }
}

resource "aws_security_group_rule" "nodes_to_cluster" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.hello_fincra.id
  description              = "Allow nodes to communicate with cluster"
}

# hello_fincra Pod Security Group
resource "aws_security_group" "hello_fincra" {
  name_prefix = "${local.project_name}-hello-fincra-sg"
  vpc_id      = aws_vpc.main.id
  description = "Security group for hello_fincra pods"
  # Allow all egress
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all egress"
  }

  # Allow HTTP from internet
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP from internet"
  }

  # Allow HTTPS from internet
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS from internet"
  }

  # Allow ICMP (ping) from internet
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow ICMP from internet"
  }

  # Allow all TCP traffic within VPC
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "Allow all TCP within VPC"
  }

  # Allow all UDP traffic within VPC
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "Allow all UDP within VPC"
  }

  tags = {
    Name                                                      = "${local.project_name}-eks-nodes-sg"
    "kubernetes.io/cluster/${local.project_name}-eks-cluster" = "owned"
  }
}


resource "aws_security_group_rule" "cluster_to_nodes" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.hello_fincra.id
  source_security_group_id = aws_security_group.eks_cluster.id
  description              = "Allow cluster to communicate with nodes"
}