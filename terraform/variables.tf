variable "aws_region" {
  default = "us-east-1"
}

variable "cluster_name" {
  default = "demo-cluster"
}

variable "node_app_image" {
  description = "Docker image for the Node.js app"
  type        = string
  default     = "aaleem1993/bootcamp-node-app:latest"
}

