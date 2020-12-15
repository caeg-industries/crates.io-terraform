## Introduction

This repository contains terraform files that builds an instance of crates.io for experimentation with the https://github.com/caeg-industries/crates.io `subcrates` branch.

## Requirements

##### GitHub OAuth

> Derived from https://github.com/rust-lang/crates.io/blob/master/docs/CONTRIBUTING.md

In order to publish a crate, you need an API token. In order to get an API
token, you need to be able to log in with GitHub OAuth. In order to be able to
log in with GitHub, you need to create an application with GitHub and specify
the `gh_client_id` and `gh_client_secret` variables in your `aws.tfvars` file below.

To create an application with GitHub, go to [Settings -> Developer Settings ->
OAuth Applications](https://github.com/settings/developers) and click on the
"Register a new application" button. Fill in the form as follows:

- Application name: name your application whatever you'd like.
- Homepage URL: `https://<SAME AS site_fqdn BELOW>/`
- Authorization callback URL: `https://<SAME AS site_fqdn BELOW>/authorize/github`

##### aws.tfvars

Create a `aws.tfvars` file, note that _all_ of the values in the file need to be replaced by you (`my_*`).
```
site_fqdn = "crates.my_site.example"
git_repo_url = "https://github.com/my_organization/crates.io-namespace-fork-index"
git_ssh_key = "my_ssh_key"
git_ssh_repo_url = "ssh://git@github.com:22/my_organization/crates.io-namespace-fork-index.git"
gh_client_secret = "my_gh_client_secret"
gh_client_id = "my_gh_client_id"
s3_access_key = "my_s3_access_key"
s3_secret_key = "my_s3_secret_key"
```

##### Install Terraform

Install `terraform` using the [Install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/aws-get-started) instructions provided by Hashicorp.

## Build

Then run:

```shell
terraform init
terraform plan -var-file aws.tfvars
terraform apply -var-file aws.tfvars
```

## Provision

When the script completes you will need to do two things:

### Set up DNS

Please check the output of the `terraform` run and update your DNS accordingly.

Once you are able to resolve the DNS host (in `site_fqdn` above), proceed to the next step.

> Hint: Use `ping`, `dig` or `nslookup` to test


**IMPORTANT** Do _NOT_ proceed beyond this poing until DNS is set up correctly and confirmed to work. 

### Finish provisioning

This step secures access to the instance through the use of TLS courtesy of [Let’s Encrypt](https://letsencrypt.org)

Shell into the instance using the output of `ssh`, then run the following command, completing the prompts as appropriate.

```shell
sudo sh secure.sh
```

##### Set up Github deploy keys

Run this command:

```shell
cat ~/.ssh/authorized_keys
```

Add the output to the Git Deploy keys of the Git Repository specified above (`git_repo_url`) (ie. `https://github.com/my_organization/crates.io-namespace-fork-index/settings/keys`).

Be sure to enable `Allow write access`.


### Using this service

Connect to your sever on `https://site_fqdn` <- Use the value you chose above.

Further instructions can be found on the homepage.

### When you are done:

Destroy the aws infrastructure:

```shell
terraform refresh
terraform destroy
```

- Delete the `ssh` key in your github repo's Deploy Keys

- Detete the GitHub OAuth credentials you created
