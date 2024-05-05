
##############################################
# EKS module
##############################################

module "eks_cluster" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.8.5"
  
  cluster_name    = "my-eks-cluster"
  cluster_version = "1.29"

  vpc_id          = data.aws_vpc.main.id
  subnet_ids      = toset(data.aws_subnets.private.ids)
}

# example
resource "kubernetes_deployment" "nginx" {
  metadata {
    name = "nginx-deployment"
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "nginx"
      }
    }
    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }
      spec {
        container {
          image = "nginx:latest"
          name  = "nginx"
          # ports {
          #   container_port = 80
          # }
        }
      }
    }
  }
}
