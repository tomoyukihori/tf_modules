
##############################################
# EKS module
##############################################

module "eks_cluster" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.13.1"

  cluster_name                   = "my-eks-cluster"
  cluster_version                = "1.29"
  cluster_endpoint_public_access = true

  vpc_id                   = data.aws_vpc.main.id
  subnet_ids               = toset(data.aws_subnets.private.ids)
  control_plane_subnet_ids = toset(data.aws_subnets.private.ids)
  iam_role_name            = "eks-role"
  iam_role_use_name_prefix = false
  create_cluster_security_group = true
  cluster_security_group_description = "This is attached to Network Interface for EKS Cluster Control Plane Nodes only"
  create_node_security_group           = true
  node_security_group_description      = "This is attached to Network Interface for Worker Nodes in Managed Node Groups only"

  node_security_group_additional_rules = {
    cluster_tcp_kubeseal_security_group_id = {
      description                   = "Cluster API to kubeseal"
      protocol                      = "tcp"
      from_port                     = 8080
      to_port                       = 8080
      type                          = "ingress"
      source_cluster_security_group = true
    }
    fargate_profile_tcp_dns_security_group_id = {
      description              = "Fargate Node Ingress For CoreDNS on TCP"
      protocol                 = "tcp"
      from_port                = 53
      to_port                  = 53
      type                     = "ingress"
      source_security_group_id = aws_security_group.eks_fargate_node_to_worker_node.id
    }
    fargate_profile_udp_dns_security_group_id = {
      description              = "Fargate Node Ingress For CoreDNS on UDP"
      protocol                 = "udp"
      from_port                = 53
      to_port                  = 53
      type                     = "ingress"
      source_security_group_id = aws_security_group.eks_fargate_node_to_worker_node.id
    }
    fargate_profile_datadog_security_group_id = {
      description              = "Fargate Node Ingress For Datadog"
      protocol                 = "tcp"
      from_port                = 5005
      to_port                  = 5005
      type                     = "ingress"
      source_security_group_id = aws_security_group.eks_fargate_node_to_worker_node.id
    }
    elb_ingress_https_security_group_id = {
      description              = "Ingress HTTPS from elb"
      protocol                 = "tcp"
      from_port                = 443
      to_port                  = 443
      type                     = "ingress"
      source_security_group_id = "" // expose_web_to_inhouse
    }
    elb_ingress_8080_security_group_id = {
      description              = "Ingress 8080 from elb argocd"
      protocol                 = "tcp"
      from_port                = 8080
      to_port                  = 8080
      type                     = "ingress"
      source_security_group_id = "" // expose_web_to_inhouse
    }
  }

  eks_managed_node_groups = {
    initial = {
      instance_types = ["m5.large"]
      min_size       = 3
      max_size       = 5
      desired_size   = 3
    }
  }
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
