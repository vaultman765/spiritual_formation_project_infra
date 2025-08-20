# module "redirect_mwc_prod" {
#   source = "../../modules/redirect_domain"

#   providers = {
#     aws           = aws
#     aws.us_east_1 = aws.us_east_1
#   }

#   project        = "var.project"
#   project        = var.project
#   env            = var.env
#   name_prefix    = "${var.name_prefix}-prod-redir"
#   hosted_zone_id = "<ZONE_ID_FOR_meditationwithchrist.com>"

#   from_domains = [
#     "meditationwithchrist.com",
#     "www.meditationwithchrist.com",
#   ]

#   to_domain = "catholicmentalprayer.com"
# }