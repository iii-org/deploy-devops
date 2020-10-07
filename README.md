# deploy-devops
## Environment  
4 Ubuntu20.04 LTS VM  
> VM1 GitLab ce-12.10.6 Server  
> VM2 Rancher Server  
> VM3, VM4 Kubernetes node
## Install docker
> ### Install docker (All VMs)  
> <code>sudo bin/ubuntu20lts_install_docker.sh </code>  

## Deploy Gitlab on VM1  
> <code> sudo gitlab/create_gitlab.sh </code>  

## Setting gitlab  
> ### set gitlab new password  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/set-gitlab-new-password.png?raw=true)  

> ### Generate root personal access tokens  
> #### User/Administrator/User seetings, gernerate root perionsal accesss token  
> #### ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/root-settings.png?raw=true)  
> #### ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/generate-root-persional-access-token.png?raw=true)
> ### Admin/Settings/Network/Outbound reuests，enable allonw request to the local netowrk  service
> #### ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/allow-request-to-the-local-netowrk.png?raw=true)  

# install rancher on VM2 
> <code> ./bin/ubuntu20lts_install_rancher.sh  </code>  
> ## set admin password
> #### ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/set-racnher-admin-password.png?raw=true)  
> ## set rancher server url
> #### ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/set-racnher-url.png?raw=true)  

# Create a Kubernetes by rancher
> ## Add cluster
> add cluster/ From existing nodes(Custom)  
> Cluster name: 
> Kubernetes Version: Then newest kubernetes version  
> Network provider: Calico  
> CNI Plugin MTU Override: 1440  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-add-cluster.png?raw=true)  
> Node Options: Chose etcd, Control plane, worker
> Copy command to run on VM3, VM4  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-cluster-node-option.png?raw=true)  
> ## Get Kubeconfig Files
> Put on kubeconfig to ~/.kube/config

## Install kubectl  
> https://kubernetes.io/docs/tasks/tools/install-kubectl/  

## Deploy Redmine  
> <code> kubectl apply -k redmine/ </code>  
