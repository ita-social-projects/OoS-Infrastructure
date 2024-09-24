# Load Elasticsearch templates/policies via script

1. Goto to script folder
```bash
cd Terraform/GCP/k8s/config
```
2. Setting up environment variables

Example for `development` environment
```bash
export ES_ENDPOINT=https://elastic.oos.dmytrominochkin.cloud
export USERNAME=$(kubectl get secret elastic-credentials --namespace default -o jsonpath='{.data.username}' | base64 -d)
export PASSWORD=$(kubectl get secret elastic-credentials --namespace default -o jsonpath='{.data.password}' | base64 -d)
```
3. Create endpoints array inside script file `vi load-elastic-script.sh`
Example
```vi
endpoints=(
  "_ilm/policy/vector-logs-ilm"
)
```
4. Create template/policy file. Name should be got from endpoints array
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
EOF
```

5. Run the script
```bash
./load-elastic-script.sh
```

# Apply Elasticsearch templates/policies via terraform

1. Create template or policy file. Name will be used in PUT request.
Example policy `vector-logs-ilm.json`
2. Add endppint url to `local.es_endpoints_list`
Example url: "_ilm/policy/vector-logs-ilm"
3 Run `terraform apply`
4. Check logs from Kubernetes Job `load-elastic-policy-******`