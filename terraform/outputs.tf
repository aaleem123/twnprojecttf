output "cluster_name" {
  value = module.eks.cluster_name
}

output "app_url" {
  value = kubernetes_service.node_app.status[0].load_balancer[0].ingress[0].hostname
  description = "Public LoadBalancer URL for your Node.js app"
}

