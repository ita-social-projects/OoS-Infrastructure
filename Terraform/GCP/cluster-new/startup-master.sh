#!/usr/bin/env bash

set -uo pipefail

# TODO: Do not delete, currently too expensive :)
# curl -sSO https://dl.google.com/cloudagents/add-monitoring-agent-repo.sh
# sudo bash add-monitoring-agent-repo.sh --also-install
# sudo service stackdriver-agent start

export INSTALL_K3S_VERSION=${k3s_version}
#export K3S_DATASTORE_ENDPOINT="mysql://${db_username}:${db_password}@tcp(${db_host}:3306)/k3s"
export K3S_TOKEN=${token}

# Generate custom ca-certs
# Create folder for certs
mkdir -p /var/lib/rancher/k3s/server/tls

# Save root and intermediate ca-certs
echo "${ROOT_CA_PEM_CERT}" > /var/lib/rancher/k3s/server/tls/root-ca.pem
echo "${INTERMEDIATE_CA_PEM}" > /var/lib/rancher/k3s/server/tls/intermediate-ca.pem
echo "${INTERMEDIATE_CA_KEY}" > /var/lib/rancher/k3s/server/tls/intermediate-ca.key

# Generating custom certs
curl -sL https://github.com/k3s-io/k3s/raw/master/contrib/util/generate-custom-ca-certs.sh > generate-custom-ca-certs.sh
chmod +x generate-custom-ca-certs.sh
./generate-custom-ca-certs.sh
ls /var/lib/rancher/k3s/server/tls

# Change server and client ca-certs
echo "${SERVER_KEY}" > /var/lib/rancher/k3s/server/tls/server-ca.key
echo "${SERVER_PEM}" > /var/lib/rancher/k3s/server/tls/server-ca.pem
echo "${CLIENT_KEY}" > /var/lib/rancher/k3s/server/tls/client-ca.key
echo "${CLIENT_PEM}" > /var/lib/rancher/k3s/server/tls/client-ca.pem

# Create server and client crts
cd /var/lib/rancher/k3s/server/tls
cat server-ca.pem intermediate-ca.pem root-ca.pem > server-ca.crt
cat client-ca.pem intermediate-ca.pem root-ca.pem > client-ca.crt

# Install k3s
curl -sfL https://get.k3s.io | sh -s - server \
  --disable-cloud-controller \
  --write-kubeconfig-mode 644 \
  --kubelet-arg="cloud-provider=external" \
  --tls-san "${external_lb_ip_address}" \
  --tls-san "${external_hostname}" \
  --tls-san "${internal_lb_ip_address}" \
  --disable traefik \
  --disable servicelb \
  --disable local-storage

# Check k3s running
while true; do
  if [ "$(systemctl -l|grep k3s.service|grep running)" != "" ]; then
      break
  fi
  sleep 5
done

systemctl status k3s.service

# Install Cloud Controller Manager
cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cloud-controller-manager
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: system:cloud-provider
rules:
- apiGroups:
  - ""
  resources:
  - events
  verbs:
  - create
  - patch
  - update
- apiGroups:
  - ""
  resources:
  - services/status
  verbs:
  - patch
  - update
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: system:cloud-provider
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:cloud-provider
subjects:
- kind: ServiceAccount
  name: cloud-provider
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: system:cloud-controller-manager
rules:
- apiGroups:
  - ""
  - events.k8s.io
  resources:
  - events
  verbs:
  - create
  - patch
  - update
- apiGroups:
  - coordination.k8s.io
  resources:
  - leases
  verbs:
  - create
- apiGroups:
  - coordination.k8s.io
  resourceNames:
    - cloud-controller-manager
  resources:
  - leases
  verbs:
  - get
  - update
- apiGroups:
  - ""
  resources:
  - endpoints
  - serviceaccounts
  verbs:
  - create
  - get
  - update
- apiGroups:
  - ""
  resources:
  - nodes
  verbs:
  - get
  - update
- apiGroups:
  - ""
  resources:
  - namespaces
  verbs:
  - get
- apiGroups:
  - ""
  resources:
  - nodes/status
  verbs:
  - patch
  - update
- apiGroups:
  - ""
  resources:
  - secrets
  verbs:
  - create
  - delete
  - get
  - update
- apiGroups:
  - "authentication.k8s.io"
  resources:
  - tokenreviews
  verbs:
  - create
- apiGroups:
  - "*"
  resources:
  - "*"
  verbs:
  - list
  - watch
- apiGroups:
  - ""
  resources:
  - serviceaccounts/token
  verbs:
  - create
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: system:controller:cloud-node-controller
rules:
- apiGroups:
  - ""
  resources:
  - events
  verbs:
  - create
  - patch
  - update
- apiGroups:
  - ""
  resources:
  - nodes
  verbs:
  - get
  - list
  - update
  - delete
  - patch
- apiGroups:
  - ""
  resources:
  - nodes/status
  verbs:
  - get
  - list
  - update
  - delete
  - patch
- apiGroups:
  - ""
  resources:
  - pods
  verbs:
  - list
  - delete
- apiGroups:
  - ""
  resources:
  - pods/status
  verbs:
  - list
  - delete
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: cloud-controller-manager:apiserver-authentication-reader
  namespace: kube-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: extension-apiserver-authentication-reader
subjects:
- apiGroup: ""
  kind: ServiceAccount
  name: cloud-controller-manager
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: system:cloud-controller-manager
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:cloud-controller-manager
subjects:
- kind: ServiceAccount
  name: cloud-controller-manager
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: system:controller:cloud-node-controller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:controller:cloud-node-controller
subjects:
- kind: ServiceAccount
  name: cloud-node-controller
  namespace: kube-system
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: cloud-controller-manager
  namespace: kube-system
  labels:
    tier: control-plane
    k8s-app: cloud-controller-manager
spec:
  selector:
    matchLabels:
      k8s-app: cloud-controller-manager
  updateStrategy:
    type: RollingUpdate
  template:
    metadata:
      labels:
        tier: control-plane
        k8s-app: cloud-controller-manager
    spec:
      nodeSelector:
        node-role.kubernetes.io/master: "true"
      tolerations:
      - key: node.cloudprovider.kubernetes.io/uninitialized
        value: "true"
        effect: NoSchedule
      - key: node-role.kubernetes.io/master
        effect: NoSchedule
      securityContext:
        seccompProfile:
          type: RuntimeDefault
        runAsUser: 65521
        runAsNonRoot: true
      priorityClassName: system-node-critical
      hostNetwork: true
      serviceAccountName: cloud-controller-manager
      containers:
        - name: cloud-controller-manager
          image: quay.io/openshift/origin-gcp-cloud-controller-manager:4.12.0
          imagePullPolicy: Always
          resources:
            requests:
              cpu: 50m
          command:
            - /bin/gcp-cloud-controller-manager
          args:
            - --bind-address=127.0.0.1
            - --cloud-provider=gce
            - --use-service-account-credentials
            - --leader-elect=true
            - --configure-cloud-routes=true
            - --allocate-node-cidrs=false
            - --cluster-cidr=10.42.0.0/16
            # - --cluster-cidr=${cluster_cidr}
            - --controllers=*,-nodeipam
          livenessProbe:
            httpGet:
              host: 127.0.0.1
              port: 10258
              path: /healthz
              scheme: HTTPS
            initialDelaySeconds: 15
            timeoutSeconds: 15
EOF

# Wait for CCM is done
DEMONSET_NAME="cloud-controller-manager"
ROLLOUT_STATUS_CMD="kubectl rollout status ds/$DEMONSET_NAME -n kube-system"
until $ROLLOUT_STATUS_CMD; do
  $ROLLOUT_STATUS_CMD
  sleep 5
done

# Need to restart Kubelet after CCM installation
systemctl restart k3s

NAME=$(curl "http://metadata.google.internal/computeMetadata/v1/instance/name" -H "Metadata-Flavor: Google")
ZONE=$(curl "http://metadata.google.internal/computeMetadata/v1/instance/zone" -H "Metadata-Flavor: Google")

gcloud compute instances \
    add-tags $NAME \
    --tags=$NAME \
    --zone $ZONE

gcloud compute instances \
    add-labels $NAME \
    --zone $ZONE "--labels=startup-done=${random_number}"
