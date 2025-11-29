locals {
  create_flow_logs        = var.enable_flow_logs
  flow_logs_to_cloudwatch = local.create_flow_logs && var.flow_logs_destination_type == "cloud-watch-logs"
  flow_logs_to_s3         = local.create_flow_logs && var.flow_logs_destination_type == "s3"
}
