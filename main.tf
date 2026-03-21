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

# 1. 创建底层 S3 存储桶 (不再作为 Web 服务器)
resource "aws_s3_bucket" "portfolio" {
  bucket = "my-devops-portfolio-${random_id.bucket_suffix.hex}"
  force_destroy = true
}

# 2. 关闭 S3 默认的公共访问拦截 (为阶段 1 的 Web 公开访问做准备)
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.portfolio.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 3. 创建 OAC (CloudFront 的专属访问签证)
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "portfolio-oac-${random_id.bucket_suffix.hex}"
  description                       = "OAC for Portfolio Site"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# 4. 创建 CloudFront Distribution
resource "aws_cloudfront_distribution" "cdn" {
  origin {
    # 阶段 3 改动：使用 S3 区域内部域名作为源，绑定 OAC 签证
    domain_name              = aws_s3_bucket.portfolio.bucket_regional_domain_name
    origin_id                = "S3PortfolioOrigin"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100" # 成本优化：仅使用北美/欧洲等最便宜节点

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

# 5. S3 Bucket Policy: 仅允许我们的 CloudFront CDN 读取文件 (最小权限原则)
resource "aws_s3_bucket_policy" "cloudfront_oac_policy" {
  bucket = aws_s3_bucket.portfolio.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipalReadOnly"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.portfolio.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.cdn.arn
          }
        }
      }
    ]
  })
}

# 6. 输出 CloudFront 域名，方便部署后直接访问
output "cloudfront_domain" {
  value       = aws_cloudfront_distribution.cdn.domain_name
  description = "你的作品集网站 CDN 域名"
}
