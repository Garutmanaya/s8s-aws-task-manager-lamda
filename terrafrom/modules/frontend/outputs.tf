output "cloudfront_url" {
  value       = "https://${aws_cloudfront_distribution.cdn.domain_name}"
  description = "CloudFront distribution URL for the frontend application."
}

output "website_bucket_name" {
  value       = aws_s3_bucket.frontend.bucket
  description = "S3 bucket name that stores the rendered frontend assets."
}
