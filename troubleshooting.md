<!-- TOC -->

- [Troubleshooting](#troubleshooting)
  - [Transit Gateway](#transit-gateway)
  - [SSH - Bastion Host](#ssh---bastion-host)
    - [Manually create SSH Key, and AWS keypair](#manually-create-ssh-key-and-aws-keypair)
  - [AWS EC2 / VM](#aws-ec2--vm)
    - [AWS EC2 - Review Cloud-init execution](#aws-ec2---review-cloud-init-execution)
    - [AWS EC2 - systemctl consul.service](#aws-ec2---systemctl-consulservice)
    - [AWS EC2 - logs](#aws-ec2---logs)
    - [AWS EC2 - Test client connectivity to HCP Consul](#aws-ec2---test-client-connectivity-to-hcp-consul)
    - [AWS EC2 - Monitor the Server](#aws-ec2---monitor-the-server)
    - [AWS EC2 - Deploy service (api)](#aws-ec2---deploy-service-api)
  - [Consul - DNS](#consul---dns)
    - [Consul - DNS lookups](#consul---dns-lookups)
    - [Consul - DNS Forwarding](#consul---dns-forwarding)
    - [Consul - Deregister Node from HCP.](#consul---deregister-node-from-hcp)
    - [Consul - Connect CA](#consul---connect-ca)
    - [Consul - Admin Partitions.](#consul---admin-partitions)
  - [EKS / Kubernetes](#eks--kubernetes)
    - [EKS - Login / Set Context](#eks---login--set-context)
    - [EKS - Helm Install manually to debug](#eks---helm-install-manually-to-debug)
    - [EKS - DNS Troubleshooting](#eks---dns-troubleshooting)
    - [EKS - Change proxy global defaults](#eks---change-proxy-global-defaults)
    - [EKS - Terminate stuck namespace](#eks---terminate-stuck-namespace)
    - [EKS - Terminate stuck objects](#eks---terminate-stuck-objects)
  - [Envoy](#envoy)
    - [Envoy - Read fake-service envoy-sidcar configuration](#envoy---read-fake-service-envoy-sidcar-configuration)
    - [Consul - Ingress GW](#consul---ingress-gw)

<!-- /TOC -->
# Troubleshooting

## Transit Gateway
* VPCs need unique IP ranges unless using a mesh gateway
* Review VPC Route Table and ensure the TGW is set as a target to all Destinations that need access to HCP
* [AWS TGW Troubleshooting Guide](https://aws.amazon.com/premiumsupport/knowledge-center/transit-gateway-fix-vpc-connection/)
* [Hashicorp TGW UI Setup Video](https://youtu.be/tw7FK_uUwqI?t=527
https://learn.hashicorp.com/tutorials/cloud/amazon-transit-gateway?in=consul/)
* [Visual Subnet Calculator](https://www.davidc.net/sites/default/subnets/subnets.html?network=10.0.0.0&mask=20&division=23.f42331) to help find the correct CIDR block ranges.

## SSH - Bastion Host
SSH to bastion host for access to internal networks.  The TF is leveraging your AWS Key Pair for the Bastion/EC2 and EKS nodes.  Use `Agent Forwarding` to ssh to your nodes.  Locally in your terminal find your key and setup ssh.
```
ssh-add -L  # Find SSH Keys added
ssh-add ${HOME}/.ssh/my-dev-key.pem  # If you dont have any keys then add your key being used in TF.
ssh -A ubuntu@<BASTION_IP>>  # pass your key in memory to the ubuntu Bastion Host you ssh to.
ssh -A ec2_user@<K8S_NODE_IP> # From bastion use your key to access a node in the private network.
```

### Manually create SSH Key, and AWS keypair
```
ssh-keygen -t rsa -b 4096 -f /tmp/tfc-hcpc-pipelines_rsa -N ''
publickeyfile="/tmp/tfc-hcpc-pipelines/tfc-hcpc-pipelines_rsa.pub"
aws_keypair_name=my-aws-keypair-$(date +%Y%m%d)
echo aws ec2 import-key-pair \
    --region "$AWS_DEFAULT_REGION" \
    --key-name "$aws_keypair_name" \
    --public-key-material "fileb://$publickeyfile"
```

## AWS EC2 / VM
### AWS EC2 - Review Cloud-init execution
When a user data script is processed, it is copied to and run from /var/lib/cloud/instances/instance-id/. The script is not deleted after it is run and can be found in this directory with the name user-data.txt.  
```
sudo cat /var/lib/cloud/instance/user-data.txt
```
The cloud-init log captures console output of the user-data script run.
```
sudo cat /var/log/cloud-init-output.log
```

### AWS EC2 - systemctl consul.service
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

### AWS EC2 - logs
To investigate systemd errors starting consul use `journalctl`.  
```
journalctl -u consul.service
```
### AWS EC2 - Test client connectivity to HCP Consul
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
### AWS EC2 - Monitor the Server
Using the consul client with the root token get a live stream of logs from the server.
```
consul monitor -log-level debug
```
### AWS EC2 - Deploy service (api)
The start.sh should start the fake-service, register it to consul as 'api', and start the envoy sidecar.  If this happens before the consul client registers the EC2 node to consul then you may need to restart the service, or look at the logs.
```
cd /opt/consul/fake-service
sudo ./stop.sh
sudo ./start.sh
cat api-service.hcl   # review service registration config
ls ./logs             # review service and envoy logs
```
There are some additional example configurations that use the CLI to configure L7 traffic management.

## Consul - DNS

### Consul - DNS lookups
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

### Consul - DNS Forwarding
Once DNS lookups are working through the local consul client,  setup DNS forwarding to port 53 to work for all requests by default.
https://learn.hashicorp.com/tutorials/consul/dns-forwarding

### Consul - Deregister Node from HCP.
```
curl \
    --header "X-Consul-Token: ${CONSUL_HTTP_TOKEN}" \
    --request PUT \
    --data '{"Datacenter": "usw2","Node": "ip-10-15-3-83.us-west-2.compute.internal"}' \
    https://usw2.private.consul.328306de-41b8-43a7-9c38-ca8d89d06b07.aws.hashicorp.cloud/v1/catalog/deregister
```
### Consul - Connect CA
```
curl -s ${CONSUL_HTTP_ADDR}/v1/connect/ca/roots | jq -r '.Roots[0].RootCert' | openssl x509 -text -noout
```
### Consul - Admin Partitions.

Setup: https://github.com/hashicorp/consul-k8s/blob/main/docs/admin-partitions-with-acls.md

Setup K8s Video: https://www.youtube.com/watch?v=RrK89J_pzbk

Blog: https://www.hashicorp.com/blog/achieving-multi-tenancy-with-consul-administrative-partitions
## EKS / Kubernetes

### EKS - Login / Set Context
Login to team1 and set alias 'team1' to current-context
```
aws_team1_eks/connect.sh
export team1_context=$(kubectl config current-context)
alias 'team1=kubectl config use-context $team1_context'
```

Login to team2 and set alias 'team2' to current-context
```
aws_team2_eks/connect.sh
export team2_context=$(kubectl config current-context)
alias 'team2=kubectl config use-context $team2_context'
```

Set default Namespace in current context
```
kubectl config set-context --current --namespace=consul
```

Switch Contexts using team aliases
```
team1
team2
```
### EKS - Helm Install manually to debug
Manually install consul using Helm.  The test.yaml below can be created from existing Terraform Output.  Make sure you are using a [compatable consul-k8s helm chart version](https://www.consul.io/docs/k8s/compatibility).  Make sure you create the k8s secrets in the correct namespace that the helm chart is expecting.
```
helm repo add hashicorp https://helm.releases.hashicorp.com

# --create-namespace
# 0.41.1 , consul 1.11.8-ent
helm install team2 hashicorp/consul --namespace consul --version 0.41.1 --set global.image="hashicorp/consul-enterprise:1.11.8-ent" --values ./helm/test.yaml

# 0.43.0 , consul 1.12.4-ent
helm install team2 hashicorp/consul --namespace consul --version 0.45.0 --set global.image="hashicorp/consul-enterprise:1.12.4-ent" --values ./helm/test.yaml
```

The Helm release name must be unique for each Kubernetes cluster. The Helm chart uses the Helm release name as a prefix for the ACL resources that it creates so duplicate names will overwrite ACL's.

[Uninstall Consul / Helm](https://www.consul.io/docs/k8s/operations/uninstall)

### EKS - DNS Troubleshooting
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
kubectl exec busybox -- nslookup web
kubectl exec busybox -- nslookup web.default  #default k8s namespace
kubectl exec busybox -- nslookup web.service.consul $consuldnsIP
kubectl exec busybox -- nslookup web.ingress.consul #Get associated ingress GW
kubectl exec busybox -- nslookup api.service.consul
kubectl exec busybox -- nslookup api.virtual.consul #Tproxy uses .virtual not .service lookup
```

Additional DNS Queries
```
# Service Lookup for defined upstreams
kubectl exec busybox -- nslookup api.service.api.ns.default.ap.usw2.dc.consul
Name:      api.service.api.ns.default.ap.usw2.dc.consul
Address 1: 10.15.1.175 10-15-1-175.api.api.svc.cluster.local
Address 2: 10.20.1.31 ip-10-20-1-31.us-west-2.compute.internal

# Virtual lookup for Transparent Proxy upstreams
kubectl exec busybox -- nslookup api.virtual.api.ns.default.ap.usw2.dc.consul
Name:      api.virtual.api.ns.default.ap.usw2.dc.consul
Address 1: 240.0.0.3
```
References:
https://aws.amazon.com/premiumsupport/knowledge-center/eks-dns-failure/

### EKS - Change proxy global defaults
For proxy global default changes to take affect restart envoy sidecars with rolling deployment.
```
for i in  $(kubectl get deployments -l service=fake-service -o name); do kubectl rollout restart $i; done
```

### EKS - Terminate stuck namespace

Start proxy on localhost:8001
```
kubectl proxy
```

Use k8s API to delete namespace
```
cat <<EOF | curl -X PUT \
  localhost:8001/api/v1/namespaces/payments/finalize \
  -H "Content-Type: application/json" \
  --data-binary @-
{
  "kind": "Namespace",
  "apiVersion": "v1",
  "metadata": {
    "name": "payments"
  },
  "spec": {
    "finalizers": null
  }
}
EOF
```

Find finalizers in "spec"
```
kubectl get namespace payments -o json > temp.json
```

```
"spec": {
        "finalizers": []
    }
```

### EKS - Terminate stuck objects
Examples to Fix defaults, intentions, and ingressgateways that wont delete
```
kubectl patch servicedefaults.consul.hashicorp.com payments -n payments --type merge --patch '{"metadata":{"finalizers":[]}}'
kubectl patch servicedefaults.consul.hashicorp.com web -n consul --type merge --patch '{"metadata":{"finalizers":[]}}'

kubectl patch serviceresolvers.consul.hashicorp.com api -n api --type merge --patch '{"metadata":{"finalizers":[]}}'

kubectl patch ingressgateway.consul.hashicorp.com ingress-gateway --type merge --patch '{"metadata":{"finalizers":[]}}'

kubectl patch serviceintentions.consul.hashicorp.com payments --type merge --patch '{"metadata":{"finalizers":[]}}'

kubectl patch exportedservices.consul.hashicorp.com pci -n default --type merge --patch '{"metadata":{"finalizers":[]}}'

kubectl patch proxydefaults.consul.hashicorp.com global -n default --type merge --patch '{"metadata":{"finalizers":[]}}'
```

## Envoy
[Verify Envoy compatability](https://www.consul.io/docs/connect/proxies/envoy) for your platform and consul version.

### Envoy - Read fake-service envoy-sidcar configuration
kubectl exec deploy/web -c envoy-sidecar -- wget -qO- localhost:19000/clusters
kubectl exec deploy/api-deployment-v2 -c envoy-sidecar -- wget -qO- localhost:19000/clusters
kubectl exec deploy/api-deployment-v2 -c envoy-sidecar -- wget -qO- localhost:19000/config_dump

NetCat - Verify IP:Port connectivity from EKS Pod
```
kubectl exec -it deploy/web  -c web -- nc -zv 10.20.11.138 21000
kubectl exec -it deploy/web  -c envoy-sidecar -- nc -zv 10.20.11.138 20000
```

List fake-service pods across all k8s ns
```
kubectl get pods -A -l service=fake-service
```

Using Manually defined upstreams (web -> api). the service dns lookup can be used to discover these services (api.service.consul, or api.default in single k8s cluster)
```
kubectl exec -it $(kubectl get pod -l app=web -o name) -c web -- curl http://localhost:9090
kubectl exec -it $(kubectl get pod -l app=web -o name) -c web -- curl http://localhost:9091
```

Using Transparent Proxy upstreams (web -> api).
* web runs in the usw2 DC, default AP, in the web namespace.
* api runs in the usw2 DC, default AP, in the api namespace.

Verify api intentions are correct, and that the web proxy has discovered api upstreams.
```
kubectl -n web exec web -c envoy-sidecar -- wget -qO- 127.0.0.1:19000/clusters

api.api.usw2.internal.b61b8e34-30b1-5058-9f49-5ca6f80c645a.consul::10.15.1.175:20000::health_flags::healthy
api.api.usw2.internal.b61b8e34-30b1-5058-9f49-5ca6f80c645a.consul::10.20.1.31:20000::health_flags::healthy
```

Next test the web app container can use the virtual lookup to connect to the api upstream.
```
kubectl -n web exec deploy/web -c web -- wget -qO- http://api.virtual.api.ns.default.ap.usw2.dc.consul
```

### Consul - Ingress GW
```
kubectl -n consul exec deploy/consul-ingress-gateway -c ingress-gateway -- wget -qO- 127.0.0.1:19000/clusters

kubectl -n consul exec deploy/consul-ingress-gateway -c ingress-gateway -- wget -qO- http://localhost:19000/config_dump

kubectl -n consul exec deploy/consul-ingress-gateway -c ingress-gateway -- wget -qO- 127.0.0.1:19000/config_dump | jq '[.. |."dynamic_route_configs"? | select(. != null)[0]]'

kubectl -n consul exec deploy/consul-ingress-gateway -c ingress-gateway -- wget -qO- http://localhost:8080

kubectl -n consul exec -it deploy/consul-ingress-gateway -c ingress-gateway -- wget --no-check-certificate -qO- http://web.virtual.consul
```