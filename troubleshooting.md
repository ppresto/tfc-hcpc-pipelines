# Troubleshooting

## Transit Gateway
* VPCs need unique IP ranges unless using a mesh gateway
* Review VPC Route Table and ensure the TGW is set as a target to all Destinations that need access to HCP
* [AWS TGW Troubleshooting Guide](https://aws.amazon.com/premiumsupport/knowledge-center/transit-gateway-fix-vpc-connection/)
* [Hashicorp TGW UI Setup Video](https://youtu.be/tw7FK_uUwqI?t=527
https://learn.hashicorp.com/tutorials/cloud/amazon-transit-gateway?in=consul/)cloud-production


## SSH
The TF is leveraging your AWS Key Pair for the Bastion/EC2 and EKS nodes.  Use `Agent Forwarding` to ssh to your nodes.  Locally in your terminal find your key and setup ssh.
```
ssh-add -L  # Find SSH Keys added
ssh-add ${HOME}/.ssh/my-dev-key.pem  # If you dont have any keys then add your key being used in TF.
ssh -A ubuntu@<BASTION_IP>>  # pass your key in memory to the ubuntu Bastion Host you ssh to.
ssh -A ec2_user@<K8S_NODE_IP> # From bastion use your key to access a node in the private network.
```

## AWS EC2 Consul client
When a user data script is processed, it is copied to and run from /var/lib/cloud/instances/instance-id/. The script is not deleted after it is run and can be found in this directory with the name user-data.txt.  
```
sudo cat /var/lib/cloud/instance/user-data.txt
```
The cloud-init log captures console output of the user-data script run.
```
sudo cat /var/log/cloud-init-output.log
```

### systemctl consul.service
This repo creates the systemd start script located at `/etc/systemd/system/consul.service`.  This scripts requires:
*  /opt/consul to store data.
*  /etc/consul.d/certs - ca.pem from HCP
*  /etc/consul.d/ - HCP default configs and an ACL token

To stop, start, and get the status of the service
```
sudo systemctl stop consul.service
sudo systemctl start consul.service
sudo systemctl status consul.service
```

To investigate systemd errors starting consul use `journalctl`
```
journalctl -u consul.service
```

## Consul

### DNS lookups
```
web.service.consul
web.ingress.consul
api.virtual.consul
api.virtual.api-ns.ns.default.ap.hcpc-cluster-presto.dc.consul
```
Once DNS lookups are working through the local consul client,  setup DNS forwarding to port 53 to work for all requests by default.
https://learn.hashicorp.com/tutorials/consul/dns-forwarding

### Deregister Node to remove consul-sync k8s services from HCP.
```
curl \
    --header "X-Consul-Token: ${CONSUL_HTTP_TOKEN}" \
    --request PUT \
    --data '{"Datacenter": "hcpc-cluster-presto","Node": "k8s-sync"}' \
    https://hcpc-cluster-presto.consul.328306de-41b8-43a7-9c38-ca8d89d06b07.aws.hashicorp.cloud//v1/catalog/deregister
```

## EKS Kubernetes

### Helm - Install manually to debug
Manually install consul using Helm.  The test.yaml below can be created from existing Terraform Output.  Make sure you are using a [compatable consul-k8s helm chart version](https://www.consul.io/docs/k8s/compatibility).
```
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install consul hashicorp/consul --create-namespace --namespace consul --version 0.33.0 --set global.image="hashicorp/consul-enterprise:1.11.0-ent" --values ./helm/test.yaml
helm status consul
```
### Kubernetes EKS DNS
Get DNS services (consul and coredns), start busybox, and use nslookup
```
consuldnsIP=$(kubectl -n consul get svc consul-dns -o json | jq -r '.spec.clusterIP')
corednsIP=$(kubectl -n kube-system get svc kube-dns -o json | jq -r '.spec.clusterIP')
kubectl run busybox --restart=Never --image=busybox:1.28 -- sleep 3600
kubectl exec busybox -- nslookup kubernetes $corednsIP
```

Test coredns config
```
kubectl run busybox --restart=Never --image=busybox:1.28 -- sleep 3600
kubectl exec busybox -- nslookup kubernetes $corednsIP
```
Test consul config
```
kubectl exec busybox -- nslookup web.default
kubectl exec busybox -- nslookup web.service.consul $consuldnsIP
kubectl exec busybox -- nslookup web.service.consul
kubectl exec busybox -- nslookup web
kubectl exec busybox -- nslookup api.service.consul
```

References:
https://aws.amazon.com/premiumsupport/knowledge-center/eks-dns-failure/

### Change proxy global defaults
For proxy global default changes to take affect restart envoy sidecars with rolling deployment.
```
for i in  $(kubectl get deployments -l service=fake-service -o name); do kubectl rollout restart $i; done
```

### Terminate stuck namespace

Start proxy on localhost:8001
```
kubectl proxy
```

Use k8s API to delete namespace
```
cat <<EOF | curl -X PUT \
  localhost:8001/api/v1/namespaces/currency-ns/finalize \
  -H "Content-Type: application/json" \
  --data-binary @-
{
  "kind": "Namespace",
  "apiVersion": "v1",
  "metadata": {
    "name": "currency-ns"
  },
  "spec": {
    "finalizers": null
  }
}
EOF
```

Find finalizers in "spec"
```
kubectl get namespace api -o json > temp.json
```

```
"spec": {
        "finalizers": []
    }
```

### Terminate stuck objects
Examples to Fix defaults, intentions, and ingressgateways that wont delete
```
kubectl patch servicedefaults.consul.hashicorp.com api -n api-ns --type merge --patch '{"metadata":{"finalizers":[]}}'
kubectl patch servicedefaults.consul.hashicorp.com web --type merge --patch '{"metadata":{"finalizers":[]}}'

kubectl patch ingressgateway.consul.hashicorp.com ingress-gateway --type merge --patch '{"metadata":{"finalizers":[]}}'

kubectl patch serviceintentions.consul.hashicorp.com web --type merge --patch '{"metadata":{"finalizers":[]}}'
```

### Envoy
[Verify Envoy compatability](https://www.consul.io/docs/connect/proxies/envoy) for your platform and consul version.

#### Get Envoy Proxy Information
```
kubectl exec -it web-7c4f6d77d8-gqs2p -c envoy-sidecar -- wget -qO- http://localhost:19000/clusters
kubectl exec -it web-7c4f6d77d8-gqs2p -c envoy-sidecar -- wget -qO- http://localhost:19000/config_dump
```

NetCat - Verify IP:Port connectivity from EKS Pod
```
kubectl exec -it web-7c4f6d77d8-gqs2p -c web -- nc -zv 10.20.11.138 21000
kubectl exec -it web-7c4f6d77d8-gqs2p -c envoy-sidecar -- nc -zv 10.20.11.138 20000
```