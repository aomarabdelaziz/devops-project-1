# This repository contains a DevOps project that leverages various technologies, including Terraform, Ansible, Docker, eksctl, EKS cluster, and kubectl to automate the deployment and management of an application on Amazon EKS

## Project Design

![Alternative Image](./asssets/design-1.png)
![Alternative Image](./asssets/design-2.png)

## Tools

- GCP CLI (Cloud Provider)
- Terraform (IaC)
- Docker (Containerization Application)

## How to Use

### Installation Guide

1. Download or clone the repository to your local machine.

2. Install gcloud CLI, Terraform, and Docker on your local machine if you haven't already done so.

3. Authenticate to your user by running the command "gcloud init" and follow the instructions to log in to your Google Cloud Platform account and select the project you want to use

4. Navigate to the Application directory in the repository and build the app using Docker by running the command \
`docker build -t <repository host>/<project id>/<image name>:<tag>` \
Make sure to replace the placeholders with your own values.

5. Navigate to the k8s-Deployment directory and make the necessary changes to the AppDeployment.yaml file, specifically the image source, to match the image you built in step 4

6. Navigate to the Terraform directory and initialize it by running the command "terraform init"

7. Make the ncessary changes in the provider.tf file, specifically the project name and region, to match your own project settings

8. Run the command "terraform validate" to validate your terraform code , then "terraform plan" to review the infrastructure changes that
terraform will apply.

9. After reviewing the changes, run the command "terraform apply" to apply the changes to your infrastructure

Note: this guide assumes that you have a basic understanding of Docker, Terraform, and GCP Platform.
  
### Access VM

1. To ssh into the vm-instance run this command \
`gcloud compute ssh --zone "<your zone>" "my-instance" --tunnel-through-iap --project "<you project name>"`

- Note: You Will find that the kubectl already installed using script created by terraform. no need to install kubectl manually

2. To change the default k8s cluster run this command \
`gcloud container clusters get-credentials my-gke --region <your region> --project <your project name>`

3. Copy the content of the k8s-Deployment directory into the vm-instance

- run `kubectl apply -f AppDeployment.yml` & `Kubectl apply -f AppSVC.yml`
- run `Kubectl get svc` to get the service ip

## Pictures

### Terraform Apply

![Alternative Image](./pics/terraform-apply.png)

### GCP Home

![Alternative Image](./pics/welcome-dashboard.png)

### GCP VPC

![Alternative Image](./pics/vpc.png)

### GCP NAT

![Alternative Image](./pics/nat.png)

### GCP IAM

![Alternative Image](./pics/GCP-IAM.png)

### GCP VMs

![Alternative Image](./pics/vm-instances.png)

### GCP GKE

![Alternative Image](./pics/k8s-cluster.png)

### GCP Load Balancer

![Alternative Image](./pics/loadbalancer.png)

### GCP GCR

![Alternative Image](./pics/gcr.png)
![Alternative Image](./pics/gcr-2.png)

### VM Pods

![Alternative Image](./pics/vm-pods.png)

### VM SVC

![Alternative Image](./pics/vm-svc.png)

### Access the Application

![Alternative Image](./pics/app-running.png)
