# Mabaya Exercise

## _Details_

### Autor
Dima Rudnitsky, 054-5369633, dima.rudnitsky@gmail.com

## _System Desctription_
### Overall architecture
- Database _**sqlite**_
- Redundancy:
  - 2 replicas
  - StatefulSet for AWS and mutural volume for the docker approach
- LoadBalancer:
  - for the docker approach - nginx container connected to both the replicas
  - for AWS approach - EKS ingress
- Monitoring approach:
  There is _**/health**_ URI which returns _**{"status":"OK"}**_ responce and doesn't update the DB. It can be usesd from any external system in order to make sure the servie is up and running.
  It is possible to use _**siege**_ utility for this.
- Simple testing approach:
  Use _**GET /showdb**_ to see all table rows

### Directory structure
#### src
- Contains source JS code for echo-service including _**package.json**_ file.
- _**index.js**_ file contains server code that shold be run inside the container
- _**Dockerfile**_ is used by terraform in order to create local container

#### local/terraform
- Contains terraform files that create 3 containers - 2 application containers and one loadbalancer (nginx)

#### aws/helm and aws/terraform
- Both the directories describe the AWS approach
  - _**aws/terraform**_ contains terraform files that create appropriated IAM role for the StatefulSet
  - _**aws/helm**_ contains helm chart with the _**values.yaml**_ file that creates application StatefullSet with PVC, SVC (service) and ingress.

## _Installation procedure_
#### Prerequisites - tools version
- Terraform: _**Terraform v0.14.9**_
- Helm: _**Version:"v3.6.1"**_
- Docker: _**Version:"20.10.12"**_
I suggest to use the same versions in order to avoid any misunderstanding and failures
### Local configuration
#### Installaton
From directory __**local/terraform**__ run the following commands:
```sh
[] >> cd local/terraform
[local/terraform] >> terraform init; terraform plan
[local/terraform] >> terraform 
[local/terraform] >> apply -auto-approve -refresh=true -lock=false
```
#### Test
Use _**curl**_:
```sh
[] >> docker ps
[] >> curl -X POST -H "Content-type: application/json" http://localhost:8080 -d '{"name":"dima"}'
[] >> curl -X POST -H "Content-type: application/json" http://localhost:8080 -d '{"name":"moti"}'
[] >> curl -X GET http://localhost:8080/health
[] >> curl -X GET http://localhost:8080/showdb
```
#### Uninststall
Again from directory __**local/terraform**__ 
```sh
[] >> cd local/terraform
[local/terraform] >> terraform destroy -auto-approve -lock=false
```
### AWS EKS cluster configuration
#### Cluster prerequisites
- ad-ons
  - aws-load-balancer-controller
  - aws-ebs-csi-driver
  - external-dns
  - storage class gp3 can be installed from _**aws/els/storageclass-gp3.yaml**_
  ```sh
  [] >> cd aws/els
  [aws/els] >> kubectl create -f storageclass-gp3.yaml
  ```
- Purchase AWS domain so the hosted zone will be created automatically
- Create ECR (container repository) and upload docker image to it (example for my repository)
  ```sh
  [] >> docker build . --tag 515321278346.dkr.ecr.us-east-1.amazonaws.com/echo-service:latest
  [] >> docker push 515321278346.dkr.ecr.us-east-1.amazonaws.com/echo-service:latest
  ```
#### Installation
From aws/terrafom directory run:
```sh
[] >> cd aws/terraform
[aws/terraform] >> terraform init; terraform plan
[aws/terraform] >> terraform 
[aws/terraform] >> apply -auto-approve -refresh=true -lock=false
```
Edit _**aws/helm/values.yaml**_ file, set desired hostname in the _**ingress**_ sections (there are two), and update repository in the _**image**_ section. Then run
```sh
[] >> helm upgrade --install --namespace <DesiredClusterNamespace> echo-service --debug aws/helm
```
#### Test
Make sure all the relevant EKS components have been created:
- PV
- PVC
- StatefulSet
- Ingress
- Pods are up and running
- There is new entry in the route53 hosted zone
  
Use _**curl**_, refer to the route53 entry created by helm installation
```sh
[] >> kubectl get ing -n <YourNameSpace>
[] >> curl -X POST -H "Content-type: application/json" http://echo-service.orcandies.click:8080 -d '{"name":"dima"}'
[] >> curl -X POST -H "Content-type: application/json" http://echo-service.orcandies.click:8080 -d '{"name":"maty"}'
[] >> curl -X GET http://echo-service.orcandies.click:8080/health
[] >> curl -X GET http://echo-service.orcandies.click:8080/showdb
```
#### Uninstall
```sh
[] >> helm delete echo-service
[] >> kubectl delete pvc echo-service-vol-echo-service-0 echo-service-vol-echo-service-1
[] >> kubectl get pv
[] >> kubectl delete pv pvc-2d1f88b7-81ff-4756-bc1e-7b2b8230e273 pvc-450a5769-afc6-44b3-8db9-dfaa81d5edff
[] >> cd local/terraform
[aws/terraform] >> terraform destroy -auto-approve -lock=false
```

### _Importand note_
In order to save time and effort I used my own pre-installed EKS cluster for deployment and testing. This AWS account and cluster will be closed and destroyed in the coming days. So either use your ows ESK cluster for installation and testing or let's discuss any other way. 