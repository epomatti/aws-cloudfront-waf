# AWS CloudFront WAF

CloudFront with WAF serving S3 and ELB origins.

<img src=".assets/cloudfront.png" />

## Create the infrastructure

Applied the infrastructure:

```sh
terraform init
terraform apply -auto-approve
```

It is required to edit the last LB rule so it fails when the header is not present.

<img src=".assets/web.png" width=500/>

---

### Clean-up

```sh
terraform destroy -auto-approve
```