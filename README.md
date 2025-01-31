# README

## Introduction

This repository contains a solution for the **Senior Site Reliability Engineer Tech Challenge (July '24)**. The solution involves developing, containerizing, deploying, and provisioning infrastructure for a Python-based API server using **FastAPI**, Docker, Infrastructure as Code (IaC), and Kubernetes.

### Minimal Tools Required
To set up and run this project, ensure you have the following tools installed:

- **Python 3.11** - Required for running the FastAPI server and local development.
- **AWS CLI** - Needed for provisioning AWS resources.
- **JQ (Optional)** - Useful for processing JSON output.
- **cURL** - For testing API endpoints.
- **An AWS Account** - Required to provision infrastructure (LocalStack is not used).
- **Helm** - Required to deploy the app on the k8s cluster.
- **Poetry (1.8.4)**

## Getting Started

### 1. Clone the Repository
```sh
 git clone <repo-url>
 cd <repo-folder>
```

### 2. Setting Up the Local Environment

## using pip-tools
The repository contains a Makefile to help with setting up the development environment. Run the following command to create a virtual environment and install dependencies:
```
 make env_test
```
This uses pip-tools to manage dependencies instead of Poetry. pip-tools ensures deterministic dependency resolution while keeping requirements files concise and easy to audit, whereas Poetry provides additional features like dependency grouping, environment management, and packaging.

## using Poetry

if you want to use poetry, is still possible

```
poetry use env
poetry install
```



### 3. Infrastructure Provisioning

Since we are using AWS services (DynamoDB, S3), we must provision the infrastructure before running the application. The Makefile includes a command to facilitate this:
```
 make tf_init ENV=dev
 make tf_plan ENV=dev
 make tf_apply ENV=dev
```
This will:

    Create the required DynamoDB Table
    Create an S3 Bucket for storing avatars
    Set up necessary IAM roles and policies


As the terraform is going to provision also a S3 bucket and Dynamodb table to manage Terraform state, when running this for the very first time, please comment out 

```
  backend "s3" {
    key     = "prima-sre/terraform.tfstate"
    region  = "eu-west-2"
    encrypt = true
  }
```
in the `main.tf` file, Then run

```
 make tf_init ENV=dev
```
 once the bucket to store state is provisioned restore the original and run 


```
 make tf_plan ENV=dev
 make tf_apply ENV=dev
```
to copy state to remote location.



### Development & Testing

## Running Tests

To run unit tests and check test coverage, use:
```
 make env_test
 make pytest
```


## Local Deployment with Docker

The repository contains a Docker Compose file that allows for local deployment:
```
 docker-compose up --build
```
## Deployment and CI/CD

The project includes a GitHub Actions workflow that automates:

    Running unit tests
    Deploying to AWS


## Nginx Reverse Proxy

An Nginx proxy is used for:

    Handling requests efficiently
    Load balancing (if scaled further)
    Protecting direct access to uploaded images

Since we are uploading pictures, they should not be publicly accessible via direct S3 URLs. A possible missing non-functional requirement is implementing a pre-signed URL system or an authentication layer to control image access.


## Running the FastAPI Server

This project uses FastAPI instead of Flask because of its built-in support for asynchronous operations, auto-generated documentation, and superior performance with async capabilities.

To start the FastAPI server:

```
docker compose up --build -d
```

The API will be available at `http://localhost:8000`


to create an user 

```
curl -i -X POST \
  -F "name=Pinco Panco" \
  -F "email=pinco@panco.com" \
  -F "file=@./ita-spiderman.jpg" \
  http://localhost:8000/user


curl -i -X POST \
  -F "name=Massimo Decimo Meridio" \
  -F "email=massimo.d@Meridio.com" \
  -F "file=@./ita-spiderman.jpg" \
  http://localhost:8000/user
```

to list the users
```
curl -X GET http://localhost:8000/users -H "Accept: application/json" | jq
```


### EKS
## interacting with cluster
after deploying the eks cluster run 
```
make kubeconfig
```

and copy-paste the command 
```
export KUBECONFIG=<****>
```

in this way you can interact with the cluster.

```
Updated context arn:aws:eks:eu-west-2:546123287190:cluster/prima-sre in /Users/brunoviola/.kube/config
export KUBECONFIG=/Users/brunoviola/.kube/config
> export KUBECONFIG=/Users/brunoviola/.kube/config
```

Once this is done wait until the cluster is available

```
watch -n 10 kubectl get nodes

```
once ready you can see:

```
> k get node
NAME                  STATUS   ROLES    AGE     VERSION
i-********   Ready    <none>   9m24s   v1.31.3-eks-7636447
```



## AWS credentials

the app needs access to aws resources so we need to pass the creadentials to the pod

I create a secret using 
```
kubectl create secret generic aws-credentials  --from-literal=AWS_ACCESS_KEY_ID=<***>   --from-literal=AWS_SECRET_ACCESS_KEY=<***> -n bruvio-poc
```

this secret is used by the Helm charts.

## Push docker images to registry

in order for our Helm charts to work we need to build locally and push to a registry the images.
I choose to go for my `dockerhub` registry

to build and push i did something like this:

```
docker login
docker compose build
docker tag app-image:tag bruvio/prima-sre-app
docker tag nginx-image:tag bruvio/prima-sre-nginx
docker push bruvio/prima-sre-nginx
docker push bruvio/prima-sre-app
```


## install Helm charts

the api can be installed on the cluster via Helm

```
helm install prima-sre-app prima-api
```




the helm chart is going to pull the images from dockerhub and you can check
```
k get pod,svc,deploy -n bruvio-poc
NAME                                           READY   STATUS    RESTARTS   AGE
pod/prima-sre-app-prima-api-5c986b59df-r8qvg   2/2     Running   0          5m12s
pod/prima-sre-app-prima-api-5c986b59df-xrz7v   2/2     Running   0          5m11s

NAME                              TYPE           CLUSTER-IP       EXTERNAL-IP                                                               PORT(S)        AGE
service/kubernetes                ClusterIP      172.20.0.1       <none>                                                                    443/TCP        69m
service/prima-sre-app-prima-api   LoadBalancer   172.20.188.138   ********.eu-west-2.elb.amazonaws.com   80:30140/TCP   9m13s

NAME                                      READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/prima-sre-app-prima-api   2/2     2            2           9m13s

```

wait until the load balancer is provisioned

```
aws elbv2 describe-load-balancers --query "LoadBalancers[*].{Name:LoadBalancerName, ARN:LoadBalancerArn, Type:Type, State:State.Code}" --output table

-------------------------------------------------------------------------------------------------------------------------------------
|                                                       DescribeLoadBalancers                                                       |
+-------+---------------------------------------------------------------------------------------------------------------------------+
|  ARN  |  lalalal                                                                                                                  |
|  Name |  myname                                                                                                                   |
|  State|  active                                                                                                                   |
|  Type |  network                                                                                                                  |
+-------+---------------------------------------------------------------------------------------------------------------------------+
```


## access the API server

```
curl -v http://********.eu-west-2.elb.amazonaws.com /health
curl -v http://********.eu-west-2.elb.amazonaws.com /users
```

## Future Enhancements

- instead of passing credentials to the pod via secret, use a role
- create ECR repos and store images there
- update the github workflow to build,tag and push images to ECR using semver
- add stages for terraform checks (trivy?)
- add stages for security checks (safety?)
- add terraform plan/apply stages to automatically deploy to AWS
- remove the provisioning of the vpc and EKS cluster and put it in a different repo, use datasources if needed.
- create a deploy role that would handle CICD deployments


## Contributions
Contributions are welcome! Please fork the repository and create a pull request with your proposed changes.


## License

This project is open-source and available under the MIT License.


## Author

- **bruvio** - _Initial work_ - [bruvio](https://github.com/bruvio)


