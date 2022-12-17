# gratefuldog4
AWS EKS cluster with Karpenter

## infrastructure
### high-level components
- VPC
- EKS cluster
- add additional users to EKS by modifying the aws-auth configmap. 
- create an IAM role with full access to Kubernetes API and let users to assume that role if they need access to EKS.
- To automatically scale the EKS cluster, we will deploy Karpenter
- AWS Load Balancer Controller using the helm provider and create a test ingress resource.

### update kubeconfig
- `aws eks update-kubeconfig --name gd4 --region us-east-2`
- `kubectl get nodes`

### cluster autoscaler
- node group managed by AWS autoscaling group
- adjust the desired size based on the load

### IAM access to EKS
- access to EKS is managed by using AWS "auth config map" in the kube-system namespace
- initially only the user that created the cluster can access EKS and modify the config map
- access can be granted in two ways:
  + add IAM users directly to the config map *--not recommended*
  + preferred method:  grant access to IAM Role via aws config map; then allow specific users to assume that role 
- `aws configure --profile user1`
- `aws sts get-caller-identity --profile user1`
- `aws sts get-caller-identity --profile eks-admin`
- update kubectl to use IAM role:
```
aws eks update-kubeconfig \
--name gd4 \
--region us-east-2 \
--profile eks-admin
```
- `kubectl auth can-i "*" "*"`


### demo apps
#### nginx
- `kubectl apply -f k8s/nginx.yaml`



## add cluster to kubectl
- Amazon EKS uses the aws eks get-token command, available in version 1.16.156 or later of the AWS CLI or the AWS IAM Authenticator for Kubernetes with kubectl for cluster authentication
- if you have installed the AWS CLI on your system, then by default the AWS IAM Authenticator for Kubernetes uses the same credentials that are returned with the `aws sts` command:
1. `kubectl version | grep Client | cut -d : -f 5`
2. `aws --version | cut -d / -f2 | cut -d ' ' -f1`
3. `aws sts get-caller-identity`
4. aws eks update-kubeconfig --region us-east-2 --name gd4

##  install cert manager


install: `kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.8.2/cert-manager.yaml`
verify: `kubectl get pod -w -n cert-manager`

## OpenTelemetry
### Operator
- chart:  https://github.com/open-telemetry/opentelemetry-helm-charts/tree/main/charts/opentelemetry-operator
- install chart: `helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts`
  + `helm repo update`
### TLS requirement
- The ADOT Operator uses admission webhooks to mutate and validate the Collector Custom Resource (CR) requests. 
- In Kubernetes, the webhook requires a TLS certificate that the API server is configured to trust. 
- There are multiple ways for you to generate the required TLS certificate. 
- However, the default method is to install the latest version of the cert-manager manually. 
- The cert-manager generates a self-signed certificate.


### Collector
- chart: https://github.com/open-telemetry/opentelemetry-helm-charts/tree/main/charts/opentelemetry-collector
- install chart: `helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts`
- Once the OpenTelemetry Operator deployment is ready, you can deploy the ADOT Collector in your EKS cluster
- the Collector is managed by the Operator, and can be deployed as one of four modes: 
  + Deployment
  + DaemonSet
  + StatefulSet
  + Sidecar

#### Collector IAM Role and SA
- Helm chart will deploy the SA: adot-collector
- Helm chart will deploy the role
## links
https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html
https://www.youtube.com/watch?v=kRKmcYC71J4
https://aws-otel.github.io/docs/introduction
https://docs.aws.amazon.com/eks/latest/userguide/deploy-collector.html
https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html