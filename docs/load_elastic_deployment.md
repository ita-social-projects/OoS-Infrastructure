# Load Elasticsearch deployments/policies

1. Got to script folder
```
cd Terraform/GCP/k8s/config
```
2. Setting up environment variables

Example for 'development' environment
```
export ES_ENDPOINT=https://elastic.oos.dmytrominochkin.cloud
export USERNAME=$(kubectl get secret elastic-credentials --namespace default -o jsonpath='{.data.username}' | base64 -d)
export PASSWORD=$(kubectl get secret elastic-credentials --namespace default -o jsonpath='{.data.password}' | base64 -d)
```
3. Create endpoints array inside script file `vi deploy-elastic-script.sh`
Example
```
endpoints=(
  "_ilm/policy/vector-logs-ilm"
)
```
4. Create deployment files. Name should be got from endpoints array
Example
```
cat <<EOF > vector-logs-ilm.json
{
  "policy": {
    "phases": {
      "hot": {
        "min_age": "0ms",
        "actions": {
          "set_priority": {
            "priority": 100
          },
          "rollover": {
            "max_primary_shard_size": "1gb",
            "max_age": "1d"
          }
        }
      },
      "delete": {
        "min_age": "2d",
        "actions": {
          "delete": {
            "delete_searchable_snapshot": true
          }
        }
      }
    }
  }
}
EOT

5. Run the script
```bash
./deploy-elastic-script.sh
```



