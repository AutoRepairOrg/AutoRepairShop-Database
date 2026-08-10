output "namespace" {
  description = "Kubernetes namespace"
  value       = kubernetes_namespace.oficina.metadata[0].name
}

output "environment" {
  description = "Deployed environment"
  value       = var.environment
}
