# AWS CloudFront WAF

## Create the infrastructure

Create the `.auto.tfvars` file:

```sh
touch .auto.tfvars
```

Add the required variables as 

```sh
# The role to be assumed by Terraform to create the resources
assume_role_arn = "arn:aws:iam::000000000000:role/OrganizationAccountAccessRole"

# Region to create the resources
region = "us-east-1"
```

<img src="saturn5.jpg" />