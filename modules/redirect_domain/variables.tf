variable "project"            { type = string }
variable "env"                { type = string }
variable "source_domains"     { type = list(string) }   # e.g. ["meditationwithchrist.com","www.meditationwithchrist.com"]
variable "target_host"        { type = string }         # e.g. "catholicmentalprayer.com"
variable "acm_certificate_arn"{ type = string }         # us-east-1 cert that covers source_domains
variable "price_class"        {
  type = string
  default = "PriceClass_100"
}
