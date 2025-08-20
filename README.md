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
