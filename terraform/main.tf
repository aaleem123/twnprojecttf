terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "eks-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "20.8.4"
  cluster_name    = var.cluster_name
  cluster_version = "1.29"
  enable_kms_key_rotation = false
  create_kms_key          = false
  cluster_encryption_config = {}
  subnet_ids = module.vpc.private_subnets
  vpc_id     = module.vpc.vpc_id

  eks_managed_node_groups = {
    default_node_group = {
      instance_types = ["t3.small"]
      min_size       = 1
      max_size       = 2
      desired_size   = 1
    }
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

data "aws_eks_cluster" "cluster" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

resource "kubernetes_namespace" "bootcamp" {
  metadata {
    name = "bootcamp"
  }
}

resource "kubernetes_deployment" "node_app" {
  metadata {
    name      = "bootcamp-node-app"
    namespace = kubernetes_namespace.bootcamp.metadata[0].name
    labels = {
      app = "bootcamp-node"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "bootcamp-node"
      }
    }
    template {
      metadata {
        labels = {
          app = "bootcamp-node"
        }
      }
      spec {
        container {
          name  = "web"
          image = var.node_app_image
          port {
            container_port = 3000
          }
          resources {
            limits = {
              memory = "256Mi"
              cpu    = "250m"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "node_app" {
  metadata {
    name      = "bootcamp-node-svc"
    namespace = kubernetes_namespace.bootcamp.metadata[0].name
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type"   = "nlb"
      "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
    }
  }
  spec {
    type = "LoadBalancer"
    selector = {
      app = "bootcamp-node"
    }
    port {
      port        = 80
      target_port = 3000
      protocol    = "TCP"
    }
  }
}

