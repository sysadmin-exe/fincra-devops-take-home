# Install AWS Load Balancer Controller
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.15.0"

  set = [
    {
      name  = "clusterName"
      value = aws_eks_cluster.main.name
    },
    {
      name  = "serviceAccount.create"
      value = "false"
    },
    {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller"
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = aws_iam_role.aws_load_balancer_controller.arn
    }
  ]
  depends_on = [
    aws_iam_role_policy_attachment.aws_load_balancer_controller
  ]
}

# Install Kube prometheus stack
resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = false
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "72.3.0"

  values = [
    yamlencode({
      prometheus = {}
      prometheusSpec = {
        serviceMonitorSelectorNilUsesHelmValues = false
        serviceMonitorSelector = {
          matchLabels = {
            app = "loki"
          }
        }
      }
    })
  ]
}

# Install Loki
resource "helm_release" "loki" {
  name             = "loki"
  namespace        = "kube-system"
  create_namespace = false
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "loki-stack"
  version          = "2.10.2"

  values = [
    yamlencode({
      loki = {
        serviceMonitor = {
          enabled = true
          labels = {
            app = "loki"
          }
        }
      }
    })
  ]

  set = [
    {
      name  = "promtail.enabled"
      value = "true"
    },
    {
      name  = "loki.serviceMonitor.enabled"
      value = "true"
    },
    {
      name  = "loki.prometheus.enabled"
      value = "true"
    }
  ]
  depends_on = [
    helm_release.kube_prometheus_stack
  ]
}
