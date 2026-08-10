resource "kubectl_manifest" "k8s" {
  for_each  = fileset("${path.module}/../k8s", "*.yaml")
  yaml_body = file("${path.module}/../k8s/${each.value}")

  depends_on = [
    kubernetes_namespace.oficina
  ]
}