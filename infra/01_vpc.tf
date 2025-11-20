# VPC Configuration
resource "aws_vpc" "main" {
  cidr_block           = local.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name                                                      = "eks-vpc"
    "kubernetes.io/cluster/${local.project_name}-eks-cluster" = "shared"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "eks-igw"
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count                   = length(local.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                                                      = "eks-public-subnet-${count.index + 1}"
    "kubernetes.io/role/elb"                                  = "1"
    "kubernetes.io/cluster/${local.project_name}-eks-cluster" = "shared"
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  count             = length(local.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name                                                      = "eks-private-subnet-${count.index + 1}"
    "kubernetes.io/role/internal-elb"                         = "1"
    "kubernetes.io/cluster/${local.project_name}-eks-cluster" = "shared"
  }
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count  = 2
  domain = "vpc"

  tags = {
    Name = "eks-nat-eip-${count.index + 1}"
  }
}

# NAT Gateways
resource "aws_nat_gateway" "main" {
  count         = 2
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "eks-nat-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.main]
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "eks-public-rt"
  }
}

# Private Route Tables
resource "aws_route_table" "private" {
  count  = 2
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name = "eks-private-rt-${count.index + 1}"
  }
}

# Route Table Associations - Public
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Route Table Associations - Private
resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

