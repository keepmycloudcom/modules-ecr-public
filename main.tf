### Variables
variable "basename" { type = string }
variable "names" { type = list(string) }
variable "amount_keep_images" { 
  type = number 
  default = 5
}
variable "expire_days" {
  type = number
  default = 14
}
variable "tags" { type = map(string) }

### ECR
resource "aws_ecrpublic_repository" "ecr" {
  count = length(var.names)

  repository_name = "${lower(var.basename)}-${var.names[count.index]}"

  tags = merge(var.tags, {
    Name = "${lower(var.basename)}-${var.names[count.index]}"
  })
}

# ECR Lifecycle Policy
resource "aws_ecr_lifecycle_policy" "lifecycle" {
  count = length(var.names)

  repository = "${lower(var.basename)}-${var.names[count.index]}"

  policy = <<-EOF
    {
      "rules": [
        {
          "rulePriority": 1,
          "description": "Keep last ${var.amount_keep_images} images",
          "selection": {
            "tagStatus": "tagged",
            "tagPrefixList": ["dev", "staging", "prod"],
            "countType": "imageCountMoreThan",
            "countNumber": ${var.amount_keep_images}
          },
          "action": {
            "type": "expire"
          }
        },
        {
          "rulePriority": 2,
          "description": "Expire images older than ${var.expire_days} days",
          "selection": {
            "tagStatus": "untagged",
            "countType": "sinceImagePushed",
            "countUnit": "days",
            "countNumber": ${var.expire_days}
          },
          "action": {
            "type": "expire"
          }
        }
      ]
    }
    EOF

  depends_on = [
    aws_ecrpublic_repository.ecr
  ]
}

### Outputs
#output "repo_names" { value = aws_ecrpublic_repository.ecr[*].name }
output "repo_arns"  { value = aws_ecrpublic_repository.ecr[*].arn }

# vim:filetype=terraform ts=2 sw=2 et: