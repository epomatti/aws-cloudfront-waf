# AWS CloudFront WAF

CloudFront with WAF serving S3 and ELB origins.

<img src=".assets/cloudfront.png" />

## Create the infrastructure

Create the `.auto.tfvars`:

```sh
cp config/template.auto.tfvars .auto.tfvars
```

Apply the infrastructure:

```sh
terraform init
terraform apply -auto-approve
```

Origins will be available for testing:

<img src=".assets/web.png" width=500/>


[Standard logs][1] (access logs) will be enabled by default:

<img src=".assets/cfaccesslogs.png" />

---

### Clean-up

```sh
terraform destroy -auto-approve
```

[1]: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/AccessLogs.html
