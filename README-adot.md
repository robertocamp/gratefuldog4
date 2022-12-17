# AWS EKS add-on support for ADOT operator

## AWS Distro for OpenTelemetry
## About
- AWS Distro for OpenTelemetry is a secure, production-ready, AWS-supported distribution of the OpenTelemetry project
- provides open source APIs, libraries, and agents to collect distributed traces and metrics for application monitoring.
- With AWS Distro for OpenTelemetry, you can instrument your applications just once to send correlated metrics and traces to multiple monitoring solutions.
- AWS Distro for OpenTelemetry also collects metadata from your AWS resources and managed services, so you can correlate application performance data with underlying infrastructure data

## AWS Distro for OpenTelemetry using EKS Add-Ons
### AWS EKS ADDONS
- An add-on is software that provides supporting operational capabilities to Kubernetes applications, but is not specific to the application
- This includes software like observability agents or Kubernetes drivers that allow the cluster to interact with underlying AWS resources for networking, compute, and storage
- Add-on software is typically built and maintained by the Kubernetes community, cloud providers like AWS, or third-party vendors
- Amazon EKS add-ons provide installation and management of a curated set of add-ons for Amazon EKS clusters

### ADOT AS AWS ADDON
- When you leverage EKS add-ons, EKS will install the ADOT Operator
-  ADOT is generally available (GA) for tracing and can also be used for metrics.
- Amazon EKS add-ons support for ADOT enables a simplified experience through EKS APIs to install one component of ADOT, the ADOT Operator, in your Amazon EKS cluster for your metrics and/or trace collection pipeline
- All Amazon EKS add-ons include the latest security patches, bug fixes, and are validated by AWS to work with Amazon EKS
- The ADOT Operator is an implementation of a Kubernetes Operator, a method of packaging and deploying a Kubernetes-native application and managed using Kubernetes APIs
- A Kubernetes Operator is a custom controller, which uses a Custom Resource Definition (CRD) to simplify the deployment and configuration of Custom Resources (CR)
- The ADOT Operator introduces a new CR called the OpenTelemetryCollector through a CRD.
- The ADOT Collector is released and supported through regular ADOT releases on Amazon Elastic Container Registry (Amazon ECR) public gallery
- If you want to update your ADOT Collector version to the latest release, apply a new configuration via CRD with an updated image

## INSTLLATION
###  check tools
- `aws --version`
- `k version`
- `eksctl version`

## prerequisites
- Before installing the AWS Distro for OpenTelemetry (ADOT) add-on, you must meet the following prerequisites and considerations.
- Connected clusters can't use this add-on.
- Grant permissions to Amazon EKS add-ons to install ADOT:
- `k apply -f https://amazon-eks.s3.amazonaws.com/docs/addons-otel-permissions.yaml`

### TLS certificate requirement
- The ADOT Operator uses admission webhooks to mutate and validate the Collector Custom Resource (CR) requests.
- In Kubernetes, the webhook requires a TLS certificate that the API server is configured to trust. 
- There are multiple ways for you to generate the required TLS certificate. 
- However, the default method is to install the latest version of the cert-manager manually. 
- The cert-manager generates a self-signed certificate.

#### installing cert-manager
- creates the necessary cert-manager objects that allow end-to-end encryption. 
- This must be done for each cluster that will have ADOT installed
`kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.8.2/cert-manager.yaml`
- validate:  `kubectl get pod -w -n cert-manager`
- validate: `k get all -n cert-manager`

#### IRSA for ADOT
- by using IRSA (IAM Role for Service Accounts), your Service Account can then provide AWS permissions to the containers you run in any pods that use that Service Account
- Each cluster where you install AWS Distro for OpenTelemetry (ADOT) must have this role to grant your AWS service account permissions. 
- Follow these steps to create and associate your IAM role to your Amazon EKS service account using IRSA:
- create IAM OIDC provider for your cluster
  1. Determine whether you have an existing IAM OIDC provider for your cluster:
    + `oidc_id=$(aws eks describe-cluster --name gd4  --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)`
    + Determine whether an IAM OIDC provider with your cluster's ID is already in your account:
    + `aws iam list-open-id-connect-providers | grep $oidc_id`
      +  output: "Arn": "arn:aws:iam::240195868935:oidc-provider/oidc.eks.us-east-2.amazonaws.com/id/BB0DB3CC8780180E1819211DF56B4889"
- IAM role:
```
eksctl create iamserviceaccount \
    --name adot-collector \
    --namespace opentelemetry-operator-system \
    --cluster gd4 \
    --attach-policy-arn arn:aws:iam::aws:policy/AmazonPrometheusRemoteWriteAccess \
    --attach-policy-arn arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess \
    --attach-policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy \
    --approve \
    --override-existing-serviceaccounts
```

#### manage the ADOT distro for OpenTelemetry Operator
- The AWS Distro for OpenTelemetry (ADOT) Operator is available as an Amazon EKS add-on. 
- After installing the ADOT Operator, you can configure the ADOT Collector to specify the deployment type and the service that will receive your application metric or trace data. 

##### ADOT installation: operator
- Installing the ADOT add-on includes the ADOT Operator, which in turn deploys the ADOT Collector.
- The ADOT Operator is a custom controller which introduces a new object type called the OpenTelemetryCollector through CustomResourceDefinition (CRD)
- `aws eks create-addon --addon-name adot --cluster-name gd4`
- `aws eks describe-addon --addon-name adot --cluster-name gd4`
- check version: Amazon EKS does not automatically update ADOT on your cluster
```
aws eks describe-addon \
    --cluster-name gd4 \
    --addon-name adot \
    --query "addon.addonVersion" \
    --output text
```
- determine ADOT versions
```
aws eks describe-addon-versions \
    --addon-name adot \
    --kubernetes-version 1.22 \
    --query "addons[].addonVersions[].[addonVersion, compatibilities[].defaultVersion]" \
    --output text
```
##### AWS Managed Service for Prometheus

##### Deploy the Collector
- After the ADOT Operator is running in your cluster, you can deploy the ADOT Collector as a custom resource
- *Traces are received in OpenTelemetry Protocol (OTLP) format*
- *Metrics are received in Prometheus format*
- Once the AWS Distro for OpenTelemetry (ADOT) Operator is installed and running, you can deploy the ADOT Collector into your Amazon EKS cluster
- the ADOT Collector can be deployed in one of four modes: 
  + Deployment
  + Daemonset
  + StatefulSet
  + Sidecar and can be deployed for visibility by an individual service. 
  + For more information on these deployment modes, see the ADOT Collector installation instructions on Github
- You can deploy the ADOT Collector by applying a YAML file to your cluster. 
- You should have already installed the ADOT Operator. 
- (these steps should already be done:)
- You can Create an IAM role with your Amazon EKS service account using IRSA. 
- By doing this, your service account can provide AWS permissions to the containers you run in any pod that uses that service account.
- ADOT Collector examples: (todo: deloy Prometheus and X-Ray Collectors)
  + Amazon CloudWatch:
  + curl -o collector-config-cloudwatch.yaml https://raw.githubusercontent.com/aws-observability/aws-otel-community/master/sample-configs/operator/collector-config-cloudwatch.yaml

### Deploy sample app
- `curl -o traffic-generator.yaml https://raw.githubusercontent.com/aws-observability/aws-otel-community/master/sample-configs/traffic-generator.yaml`
  + edit YAML: update namespace  
- `curl -o sample-app.yaml https://raw.githubusercontent.com/aws-observability/aws-otel-community/master/sample-configs/sample-app.yaml`



## links
https://docs.aws.amazon.com/eks/latest/userguide/opentelemetry.html
https://aws-otel.github.io/
https://docs.aws.amazon.com/eks/latest/userguide/opentelemetry.html
https://github.com/cert-manager
https://aws-otel.github.io/docs/getting-started/adot-eks-add-on
https://docs.aws.amazon.com/eks/latest/userguide/eks-add-ons.html


## output logs
❯ k apply -f https://amazon-eks.s3.amazonaws.com/docs/addons-otel-permissions.yaml
namespace/opentelemetry-operator-system created
clusterrole.rbac.authorization.k8s.io/eks:addon-manager-otel created
clusterrolebinding.rbac.authorization.k8s.io/eks:addon-manager-otel created
role.rbac.authorization.k8s.io/eks:addon-manager created
rolebinding.rbac.authorization.k8s.io/eks:addon-manager created

❯ kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.8.2/cert-manager.yaml
namespace/cert-manager created
customresourcedefinition.apiextensions.k8s.io/certificaterequests.cert-manager.io created
customresourcedefinition.apiextensions.k8s.io/certificates.cert-manager.io created
customresourcedefinition.apiextensions.k8s.io/challenges.acme.cert-manager.io created
customresourcedefinition.apiextensions.k8s.io/clusterissuers.cert-manager.io created
customresourcedefinition.apiextensions.k8s.io/issuers.cert-manager.io created
customresourcedefinition.apiextensions.k8s.io/orders.acme.cert-manager.io created
serviceaccount/cert-manager-cainjector created
serviceaccount/cert-manager created
serviceaccount/cert-manager-webhook created
configmap/cert-manager-webhook created
clusterrole.rbac.authorization.k8s.io/cert-manager-cainjector created
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-issuers created
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-clusterissuers created
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-certificates created
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-orders created
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-challenges created
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-ingress-shim created
clusterrole.rbac.authorization.k8s.io/cert-manager-view created
clusterrole.rbac.authorization.k8s.io/cert-manager-edit created
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-approve:cert-manager-io created
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-certificatesigningrequests created
clusterrole.rbac.authorization.k8s.io/cert-manager-webhook:subjectaccessreviews created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-cainjector created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-issuers created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-clusterissuers created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-certificates created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-orders created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-challenges created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-ingress-shim created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-approve:cert-manager-io created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-certificatesigningrequests created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-webhook:subjectaccessreviews created
role.rbac.authorization.k8s.io/cert-manager-cainjector:leaderelection created
role.rbac.authorization.k8s.io/cert-manager:leaderelection created
role.rbac.authorization.k8s.io/cert-manager-webhook:dynamic-serving created
rolebinding.rbac.authorization.k8s.io/cert-manager-cainjector:leaderelection created
rolebinding.rbac.authorization.k8s.io/cert-manager:leaderelection created
rolebinding.rbac.authorization.k8s.io/cert-manager-webhook:dynamic-serving created
service/cert-manager created
service/cert-manager-webhook created
deployment.apps/cert-manager-cainjector created
deployment.apps/cert-manager created
deployment.apps/cert-manager-webhook created
mutatingwebhookconfiguration.admissionregistration.k8s.io/cert-manager-webhook created
validatingwebhookconfiguration.admissionregistration.k8s.io/cert-manager-webhook created

╰─ eksctl create iamserviceaccount \                                                                                                                                           ─╯
    --name adot-collector \
    --namespace opentelemetry-operator-system \
    --cluster gd4 \
    --attach-policy-arn arn:aws:iam::aws:policy/AmazonPrometheusRemoteWriteAccess \
    --attach-policy-arn arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess \
    --attach-policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy \
    --approve \
    --override-existing-serviceaccounts
2022-10-03 18:10:43 [ℹ]  1 iamserviceaccount (opentelemetry-operator-system/adot-collector) was included (based on the include/exclude rules)
2022-10-03 18:10:43 [!]  metadata of serviceaccounts that exist in Kubernetes will be updated, as --override-existing-serviceaccounts was set
2022-10-03 18:10:43 [ℹ]  1 task: {
    2 sequential sub-tasks: {
        create IAM role for serviceaccount "opentelemetry-operator-system/adot-collector",
        create serviceaccount "opentelemetry-operator-system/adot-collector",
    } }2022-10-03 18:10:43 [ℹ]  building iamserviceaccount stack "eksctl-gd4-addon-iamserviceaccount-opentelemetry-operator-system-adot-collector"
2022-10-03 18:10:44 [ℹ]  deploying stack "eksctl-gd4-addon-iamserviceaccount-opentelemetry-operator-system-adot-collector"
2022-10-03 18:10:44 [ℹ]  waiting for CloudFormation stack "eksctl-gd4-addon-iamserviceaccount-opentelemetry-operator-system-adot-collector"
2022-10-03 18:11:14 [ℹ]  waiting for CloudFormation stack "eksctl-gd4-addon-iamserviceaccount-opentelemetry-operator-system-adot-collector"
2022-10-03 18:11:15 [ℹ]  created serviceaccount "opentelemetry-operator-system/adot-collector"


❯ aws eks create-addon --addon-name adot --cluster-name gd4
{
    "addon": {
        "addonName": "adot",
        "clusterName": "gd4",
        "status": "CREATING",
        "addonVersion": "v0.58.0-eksbuild.1",
        "health": {
            "issues": []
        },
        "addonArn": "arn:aws:eks:us-east-2:240195868935:addon/gd4/adot/42c1d014-31e4-d6a5-57ba-d2005d6ef40d",
        "createdAt": "2022-10-03T18:22:25.225000-05:00",
        "modifiedAt": "2022-10-03T18:22:25.245000-05:00",
        "tags": {}
    }
}

❯ kubectl apply -f collector-config-cloudwatch.yaml
opentelemetrycollector.opentelemetry.io/aws-adot-cloudwatch created
clusterrole.rbac.authorization.k8s.io/otel-prometheus-role created
clusterrolebinding.rbac.authorization.k8s.io/otel-prometheus-role-binding created


❯ kubectl apply -f sample-app.yaml
service/sample-app created
deployment.apps/sample-app created