### Creating a Django SuperUser

``` bash
# Update to correct variables
aws ecs run-task \
  --cluster {CLUSTER_NAME} \
  --launch-type FARGATE \
  --task-definition {TASK_DEF_NAME:VERISON} \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-0ca6c291c655cf7fd,subnet-0a220132daaf70b49],securityGroups=[sg-047729efaea87dcfc],assignPublicIp=DISABLED}" \
  --overrides '{
    "containerOverrides": [{
      "name": "import",                          
      "command": ["python","manage.py","createsuperuser","--noinput"],
      "environment": [
        {"name":"DJANGO_SUPERUSER_USERNAME","value":"sf_admin"},
        {"name":"DJANGO_SUPERUSER_EMAIL","value":"catholicmentalprayer@gmail.com"},
        {"name":"DJANGO_SUPERUSER_PASSWORD","value":"{PASSWORD}"}
      ]
    }]
  }'
```

### Terraform-docs

``` bash
terraform-docs markdown --config=../../.terraform-docs.yml .
```

### Checkov report

#### Run the reports for json and sarif

```bash
checkov -d . --framework terraform --download-external-modules true --quiet --compact --output json --output-file-path "./checkov-results/" --output sarif --output-file-path "./checkov-results/"
```

#### Run the summarize script for a summary json of the report

```bash
bash scripts/summarize-checkov.sh checkov-results/results_json.json > checkov-results/summary.json
```

### Building/Tearing Down Staging

#### To build - update terraform.tfvars to

```tfvars
# --- Ephemeral staging flags ---
enable_apprunner_permissions     = true
staging_infra_enabled            = true
staging_rds_from_latest_snapshot = true
staging_low_cost                 = false
```

#### To tear down

1. Update terraform.tfvars to

```tfvars
# --- Ephemeral staging flags ---
enable_apprunner_permissions     = false
staging_infra_enabled            = false
staging_rds_from_latest_snapshot = false
staging_low_cost                 = true
```

2. Delete log bucket

```bash
aws s3 rm s3://sf-staging-logs --recursive
```

3. Run the following command to destroy the staging infrastructure

```bash
terraform init
terraform plan
terraform apply
```
