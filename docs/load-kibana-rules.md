# Load Elasticsearch alerting riles via script

1. Goto to script folder
```bash
cd Terraform/GCP/k8s/config/scripts
```
2. Setting up environment variables

Example for `development` environment
```bash
export KIBANA_ENDPOINT=https://kibana.oos.dmytrominochkin.cloud
export USERNAME=$(kubectl get secret elastic-credentials --namespace default -o jsonpath='{.data.username}' | base64 -d)
export PASSWORD=$(kubectl get secret elastic-credentials --namespace default -o jsonpath='{.data.password}' | base64 -d)
```
