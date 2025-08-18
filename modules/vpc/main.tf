data "aws_region" "current" {}
data "aws_availability_zones" "this" {
  state = "available"
}

locals {
  tags = {
    Project = var.project
    Env     = var.env
  }

  azs       = slice(data.aws_availability_zones.this.names, 0, 2)
  nat_count = var.nat_gateway_mode == "per_az" ? 2 : (var.nat_gateway_mode == "single" ? 1 : 0)

  create_vpc = var.enabled
  create_nat = var.enabled && (var.nat_gateway_mode != "none")
  base_tags  = merge({ ManagedBy = "Terraform" }, var.tags)
}

resource "aws_vpc" "this" {
  count                = local.create_vpc ? 1 : 0
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(local.tags, {
    Name = length(var.name_prefix) > 0 ? "${var.name_prefix}-vpc" : "vpc"
  })
}

resource "aws_internet_gateway" "this" {
  count  = local.create_vpc ? 1 : 0
  vpc_id = aws_vpc.this[0].id
  tags   = merge(local.tags, { Name = "${var.name_prefix}-igw" })
}

# Public subnets (2)
resource "aws_subnet" "public" {
  for_each                = local.create_vpc ? { for idx, cidr in var.public_subnet_cidrs : idx => cidr } : {}
  vpc_id                  = aws_vpc.this[0].id
  cidr_block              = each.value
  availability_zone       = local.azs[tonumber(each.key)]
  map_public_ip_on_launch = true
  tags                    = merge(local.tags, { Name = "${var.name_prefix}-public-${each.key}" })
}

# Private subnets (2)
resource "aws_subnet" "private" {
  for_each          = local.create_vpc ? { for idx, cidr in var.private_subnet_cidrs : idx => cidr } : {}
  vpc_id            = aws_vpc.this[0].id
  cidr_block        = each.value
  availability_zone = local.azs[tonumber(each.key)]
  tags              = merge(local.tags, { Name = "${var.name_prefix}-private-${each.key}" })
}

# Public route table, 0.0.0.0/0 -> IGW
resource "aws_route_table" "public" {
  count  = local.create_vpc ? 1 : 0
  vpc_id = aws_vpc.this[0].id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this[0].id
  }
  tags = merge(local.tags, { Name = "${var.name_prefix}-public-rt" })
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public[0].id
}

# NAT (configurable)
resource "aws_eip" "nat" {
  count      = local.create_nat ? local.nat_count : 0
  domain     = "vpc"
  depends_on = [aws_internet_gateway.this]
  tags       = merge(local.tags, { Name = "${var.name_prefix}-nat-eip-${count.index}" })
}

resource "aws_nat_gateway" "this" {
  count         = local.create_nat ? local.nat_count : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = values(aws_subnet.public)[count.index % length(aws_subnet.public)].id
  tags          = merge(local.tags, { Name = "${var.name_prefix}-nat-${count.index}" })
  depends_on    = [aws_internet_gateway.this]
}

# Private route tables: each private subnet gets a route table.
resource "aws_route_table" "private" {
  for_each = aws_subnet.private
  vpc_id   = aws_vpc.this[0].id

  dynamic "route" {
    for_each = local.nat_count == 0 ? [] : [1]
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = local.nat_count == 1 ? aws_nat_gateway.this[0].id : aws_nat_gateway.this[tonumber(each.key)].id
    }
  }

  tags = merge(local.tags, { Name = "${var.name_prefix}-private-rt-${each.key}" })
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

# Optional: S3 gateway endpoint so private subnets can hit S3 without NAT
resource "aws_vpc_endpoint" "s3" {
  count             = local.create_vpc ? 1 : 0
  vpc_id            = aws_vpc.this[0].id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = concat(
    aws_route_table.public[*].id,         # count-based
    values(aws_route_table.private)[*].id # for_each-based
  )

  tags = merge(local.tags, { Name = "${var.name_prefix}-s3-endpoint" })
}
