# Troubleshooting

## Transit Gateway
* VPCs need unique IP ranges unless using a mesh gateway
* Review VPC Route Table and ensure the TGW is set as a target to all Destinations that need access to HCP
* [AWS TGW Troubleshooting Guide](https://aws.amazon.com/premiumsupport/knowledge-center/transit-gateway-fix-vpc-connection/)
* [Hashicorp TGW UI Setup Video](https://youtu.be/tw7FK_uUwqI?t=527
https://learn.hashicorp.com/tutorials/cloud/amazon-transit-gateway?in=consul/)
* [Visual Subnet Calculator](https://www.davidc.net/sites/default/subnets/subnets.html?network=10.0.0.0&mask=20&division=23.f42331) to help find the correct CIDR block ranges.

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

### logs
To investigate systemd errors starting consul use `journalctl`.  
```
journalctl -u consul.service
```
### Test client connectivity to HCP Consul
First check consul logs above to verify the local client successfully connected.  You should see the IP of the node and `agent: Synced`
```
[INFO]  agent: Synced node info
```
If the client can't connect verify it has a route to HCP Consul's internal address and the required ports.
```
ssh ubuntu@**bastion_ip**   #terraform output variable
consul_url=**consul_private_endpoint_url**   #terraform output variable

curl ${consul_url}/v1/status/leader  #verify consul internal url is accessible and service healthy
ip=$(dig +short ${consul_url//https:\/\/}) # get internal consul IP
ping $ip
nc -zv $ip 8301   # TCP Test to remote HCP Consul agent port
nc -zvu $ip 8301  # UDP 8301
nc -zv $ip 8300   # TCP 8300
```

Look at the logs to identify other unhealthy clients in remote VPC's.
```
[INFO]  agent.client.serf.lan: serf: EventMemberFailed: ip-10-15-2-242.us-west-2.compute.internal 10.15.2.79
[INFO]  agent.client.memberlist.lan: memberlist: Suspect ip-10-15-2-242.us-west-2.compute.internal has failed, no acks received
```
These are examples of a client that can connect to HCP Consul, but not all other agents in other VPC's that are using the shared service.  Unless they are in their own Admin Partition they need to be able to route to all other agents participating in HCP Consul. This is how Consul agents monitor each other through Gossip.  In this case, verify both source and destinations can reach eachother over TCP and UDP on port 8301.
```
nc -zv 10.15.2.79 8301
nc -zvu 10.15.2.79 8301
```

Check Security group rules to ensure TCP/UDP bidirectional traffic is openned to all networks using HCP.  
Warning:  EKS managed nodes are mapped to specific security groups that need to allow this traffic.  Refer to `aws_eks/sg-hcp-consul.tf`
### Monitor the Server
Using the consul client with the root token get a live stream of logs from the server.
```
consul monitor -log-level debug
```

## Consul

### DNS lookups
Use the local consul clients DNS interface that runs on port 8600 for testing.  This client will service local DNS requests to the HCP Consul service over port 8301 so there is no need to add additional security rules for port 8600.
```
dig @127.0.0.1 -p 8600 consul.service.consul

; <<>> DiG 9.11.3-1ubuntu1.17-Ubuntu <<>> @127.0.0.1 -p 8600 consul.service.consul
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 47609
;; flags: qr aa rd; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1
;; WARNING: recursion requested but not available

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;consul.service.consul.		IN	A

;; ANSWER SECTION:
consul.service.consul.	0	IN	A	172.25.20.205

;; Query time: 2 msec
;; SERVER: 127.0.0.1#8600(127.0.0.1)
;; WHEN: Tue Aug 16 21:00:13 UTC 2022
;; MSG SIZE  rcvd: 66
```
The response should contain *ANSWER: 1* for a single node HCP development cluster.  If you receive a response with *ANSWER: 0 and status: NXDOMAIN* then most likely you need to [review the DNS policies associated with your consul client](https://learn.hashicorp.com/tutorials/consul/access-control-setup-production?in=consul/security#token-for-dns). In this guide the terraform (./hcp_consul/consul-admin.tf) is creating this policy and assigning it to the anonymous token to allow DNS lookups to work by default for everyone.

Additional DNS Queries
```
dig @127.0.0.1 -p 8600 api.service.consul SRV  # lookup api service IP and Port
```
References:
https://learn.hashicorp.com/tutorials/consul/get-started-service-discover
https://www.consul.io/docs/discovery/dns#dns-with-acls

### DNS Forwarding
Once DNS lookups are working through the local consul client,  setup DNS forwarding to port 53 to work for all requests by default.
https://learn.hashicorp.com/tutorials/consul/dns-forwarding

### EC2 fake-service
The start.sh should start the fake-service, register it to consul as 'api', and start the envoy sidecar.  If this happens before the consul client registers the EC2 node to consul then you may need to restart the service, or look at the logs.
```
cd /opt/consul/fake-service
sudo ./stop.sh
sudo ./start.sh
cat api-service.hcl   # review service registration config
ls ./logs             # review service and envoy logs
```
There are some additional example configurations that use the CLI to configure L7 traffic management.
## EKS Kubernetes

### Deregister Node to remove consul-sync k8s services from HCP.
```
curl \
    --header "X-Consul-Token: ${CONSUL_HTTP_TOKEN}" \
    --request PUT \
    --data '{"Datacenter": "usw2","Node": "ip-10-15-3-83.us-west-2.compute.internal"}' \
    https://usw2.private.consul.328306de-41b8-43a7-9c38-ca8d89d06b07.aws.hashicorp.cloud/v1/catalog/deregister
```
### Helm - Install manually to debug
Manually install consul using Helm.  The test.yaml below can be created from existing Terraform Output.  Make sure you are using a [compatable consul-k8s helm chart version](https://www.consul.io/docs/k8s/compatibility).  Make sure you create the k8s secrets in the correct namespace that the helm chart is expecting.
```
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install consul hashicorp/consul --create-namespace --namespace consul --version 0.33.0 --set global.image="hashicorp/consul-enterprise:1.11.0-ent" --values ./helm/test.yaml
helm status consul
```
The Helm release name must be unique for each Kubernetes cluster. The Helm chart uses the Helm release name as a prefix for the ACL resources that it creates
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

Additional DNS Queries
```
web.service.consul
web.ingress.consul
api.virtual.consul
api.virtual.api-ns.ns.default.ap.hcpc-cluster-presto.dc.consul
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

#### Read fake-service envoy-sidcar configuration
kubectl exec deploy/web -c envoy-sidecar -- wget -qO- localhost:19000/clusters
kubectl exec deploy/api-deployment-v2 -c envoy-sidecar -- wget -qO- localhost:19000/clusters
kubectl exec deploy/api-deployment-v2 -c envoy-sidecar -- wget -qO- localhost:19000/config_dump

NetCat - Verify IP:Port connectivity from EKS Pod
```
kubectl exec -it deploy/web  -c web -- nc -zv 10.20.11.138 21000
kubectl exec -it deploy/web  -c envoy-sidecar -- nc -zv 10.20.11.138 20000
```