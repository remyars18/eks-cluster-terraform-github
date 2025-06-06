# IAM Role for the EKS Cluster
resource "aws_iam_role" "cluster-role" {
  name = "cluster-role-12"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach necessary policies to the cluster role
resource "aws_iam_role_policy_attachment" "cluster-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster-role.name
}

# IAM Role for the EKS Node Group
resource "aws_iam_role" "node-role" {
  name = "node-role-12"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach necessary policies to the node role
resource "aws_iam_role_policy_attachment" "node-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node-role.name
}

resource "aws_iam_role_policy_attachment" "cni-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"  # Updated policy ARN
  role       = aws_iam_role.node-role.name
}

resource "aws_iam_role_policy_attachment" "registry-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node-role.name
}

# EKS Cluster
resource "aws_eks_cluster" "eks-cluster" {
  name     = "k8-cluster-new"
  role_arn = aws_iam_role.cluster-role.arn
  version  = "1.32"

  vpc_config {
    subnet_ids         = ["subnet-0dde199d5341f24ba","subnet-094744c80d5d07c33"]
    security_group_ids = ["sg-078af200163e091fb"]
  }

  depends_on = [aws_iam_role_policy_attachment.cluster-policy]
}

# EKS Node Group
resource "aws_eks_node_group" "k8-cluster-node-group" {
  cluster_name    = aws_eks_cluster.eks-cluster.name
  node_group_name = "k8-cluster-node-group"
  node_role_arn   = aws_iam_role.node-role.arn
  subnet_ids      = ["subnet-0dde199d5341f24ba","subnet-094744c80d5d07c33"]

  scaling_config {
    desired_size = 3
    min_size     = 2
    max_size     = 5
  }

  depends_on = [aws_iam_role_policy_attachment.node-policy]
}
