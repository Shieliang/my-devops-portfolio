terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # 使用 5.x 版本的 AWS Provider
    }
  }
}

# 配置 AWS Provider
provider "aws" {
  region  = "us-east-1" # 建议：CloudFront 的标准证书和许多全局服务都在此区域
}

# 生成随机后缀，防止 S3 Bucket 重名
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# 1. 创建 S3 Bucket
resource "aws_s3_bucket" "portfolio" {
  bucket = "my-devops-portfolio-${random_id.bucket_suffix.hex}"
}

# 2. 开启 S3 静态网站托管模式
resource "aws_s3_bucket_website_configuration" "portfolio_website" {
  bucket = aws_s3_bucket.portfolio.id

  index_document {
    suffix = "index.html"
  }
}

# 3. 关闭 S3 默认的公共访问拦截 (为阶段 1 的 Web 公开访问做准备)
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.portfolio.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# 4. 添加 Bucket Policy，允许任何人读取内容
resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.portfolio.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.portfolio.arn}/*"
      },
    ]
  })
  depends_on = [aws_s3_bucket_public_access_block.public_access]
}

# 5. 创建 CloudFront Distribution
resource "aws_cloudfront_distribution" "cdn" {
  origin {
    # 阶段 1：使用 S3 网站终结点作为源
    domain_name = aws_s3_bucket_website_configuration.portfolio_website.website_endpoint
    origin_id   = "S3PortfolioOrigin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  # 新增这一行：只使用最便宜的边缘节点区域
  price_class         = "PriceClass_100"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3PortfolioOrigin"

    # 使用 AWS 托管的缓存策略 (CachingOptimized)
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    
    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# 6. 输出 CloudFront 域名，方便部署后直接访问
output "cloudfront_domain" {
  value       = aws_cloudfront_distribution.cdn.domain_name
  description = "你的作品集网站 CDN 域名"
}
