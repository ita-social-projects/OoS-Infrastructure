# Move Elastic Indexes between different Elastic search deployments.

1. Add to ElasticSearch config repo for backup:
    config:
      path.repo:
        - /usr/share/elasticsearch/data/backup

Elastic will create a folder on Elastic Instance.

2. Go to Kibana UI

https://kibana.oos.dmytrominochkin.cloud/app/management/data/snapshot_restore/snapshots

3. Register repository:

https://kibana.oos.dmytrominochkin.cloud/app/management/data/snapshot_restore/add_repository

4. Create a snapshot policy and snapshot.

https://kibana.oos.dmytrominochkin.cloud/app/management/data/snapshot_restore/add_policy

5. Go to Elastic instance and check snapshot files:
```bash
kubectl exec elasticsearch-es-elastic-0 -- ls /usr/share/elasticsearch/data/backup
```

6. Zip snapshot and copy to local PC.
```bash
kubectl exec elasticsearch-es-elastic-0 -- zip -r backup.zip /usr/share/elasticsearch/data/backup
kubectl cp elasticsearch-es-elastic-0:/usr/share/elasticsearch/data/backup.zip .
```

7. Repeat 1-4 on your other Elastic deployment.

8. Copy the snapshot to another Elastic2 instance. (change KUBECONFIG for other Elastic2 deployment)
```bash
kubectl cp backup.zip elasticsearch-es-elastic-0:/usr/share/elasticsearch/data
kubectl exec elasticsearch-es-elastic-0 -- unzip /usr/share/elasticsearch/data/backup.zip
```

9.Go to Kibana2 UI
https://kibana.oos.dmytrominochkin.cloud/app/management/data/snapshot_restore/snapshots

You should see the snapshot.

10. Click snapshot and restore.



