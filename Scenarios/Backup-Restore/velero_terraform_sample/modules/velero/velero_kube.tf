
data "azurerm_subscription" "current" {
}


resource "kubernetes_namespace" "velero" {
  metadata {
    name = var.velero_namespace
    labels = {
      deployed-by = "Terraform"
    }
  }
}


resource "kubernetes_secret" "velero" {
  metadata {
    name      = "cloud-credentials"
    namespace = kubernetes_namespace.velero.metadata[0].name
  }
  data = {
    cloud = local.velero_credentials
  }
}


resource "helm_release" "velero" {
  depends_on = [
    kubernetes_secret.velero,
    kubernetes_namespace.velero]
  name       = "velero"
  chart      = "velero"
  repository = var.velero_chart_repository
  namespace  = kubernetes_namespace.velero.metadata[0].name
  version    = var.velero_chart_version

  dynamic "set" {
    for_each = local.velero_values
    iterator = setting
    content {
      name  = setting.key
      value = setting.value
    }
  }

}
