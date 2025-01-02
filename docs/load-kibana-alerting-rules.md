# Deploy Elasticsearch Alerting Rules via Terraform

https://www.elastic.co/guide/en/kibana/8.6/create-rule-api.html

1. It is recommended to create and edit alerting rules in the Kibana UI.
2. Create a file with the alerting rule in the folder `k8s/config/kibana-rules`. The filename should be the rule ID (a UUID v1 or v4).
3. Add the filename to the `local.kibana_rules_files_list` list in the file `k8s/kibana_alerting_rules.tf`.
4. Apply Terraform to deploy the rule.

