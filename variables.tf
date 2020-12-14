variable "region" {
  type        = string
  default     = "eu-west-1"
}

variable "availability_zones" {
  type = list(string)
  default = ["eu-west-1a","eu-west-1b","eu-west-1c"]
}

variable "namespace" {
  type        = string
  default     = "crates"
}

variable "resource_tag_name" {
  type        = string
  default     = "experimental"
}

variable "ec2_instance_type" {
  type        = string
  default     = "t2.medium"
}

variable "key_name" {
  type        = string
  default     = "ssh_key"
}

variable "group_tag" {
  type = string
  default = "crates.io"
}

variable "postgresql_port" {
  type        = number
  default     = 5432
}

variable "postgresql_version" {
  type = string
  default = "9.6.9"
}

variable "postgresql_instance_class" {
  type = string
  default = "db.t2.medium"
}

variable "postgresql_db" {
  type = string
  default = "cargo_registry"
}

variable "postgresql_username" {
  type = string
  default = "cratesio"
}

variable "identifier" {
  type        = string
  default     = "crates"
}

variable "allocated_storage" {
  type        = number
  default     = 5
}

variable "backup_retention_period" {
  type        = number
  default     = 0
}

variable "backup_window" {
  type        = string
  default     = "03:00-06:00"
}

variable "maintenance_window" {
  type        = string
  default     = "Mon:00:00-Mon:03:00"
}

variable "storage_type" {
  description = "One of 'standard' (magnetic), 'gp2' (general purpose SSD), or 'io1' (provisioned IOPS SSD). The default is 'io1' if iops is specified, 'standard' if not. Note that this behaviour is different from the AWS web console, where the default is 'gp2'."
  type        = string
  default     = "gp2"
}

variable "s3_secret_key" {
  type        = string
}

variable "s3_access_key" {
  type        = string
}

variable "gh_client_id" {
  type        = string
}

variable "gh_client_secret" {
  type        = string
}

variable "git_ssh_repo_url" {
  type        = string
}

variable "git_repo_url" {
  type        = string
}

variable "site_fqdn" {
  type        = string
}

