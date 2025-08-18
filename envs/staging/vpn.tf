module "client_vpn" {
  source                 = "../../modules/client_vpn"
  project                = var.project
  env                    = var.env
  count                  = var.vpn_enabled ? 1 : 0
  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnet_ids
  server_certificate_arn = var.client_vpn_server_cert_arn
  region                 = var.region
}
