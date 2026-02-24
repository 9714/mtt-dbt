locals {
  config = var.environments[var.env]
  prefix = var.env == "prd" ? var.client_name : "${var.client_name}-${var.env}"

  common_labels = {
    client_name = var.client_name
    env         = var.env
  }
}
