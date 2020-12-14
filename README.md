This repository contains terraform files that builds an instance of crates.io for experimentation with the https://github.com/caeg-industries/crates.io `subcrates` branch.

You should edit the `variables.tf` file first.

```shell
brew install awscli terraform

aws configure

terraform init

terraform plan -out plan.out

terraform apply plan.out

```


When you are done:

```shell
terraform refresh

terraform destroy

```
