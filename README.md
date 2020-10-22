# deploy-devops
## Environment  
* 4 Ubuntu20.04 LTS VM  
  * VM1(iiidevops1, 140.92.4.3): GitLab ce-12.10.6 Server  
  * VM2(iiidevops2, 140.92.4.4): Rancher Server, NFS Server  
  * VM3(iiidevops3, 140.92.4.5): Kubernetes node(control plane + etcd + worker node)  
  * VM4(iiidevops4, 140.92.4.6): Kubernetes node(control plane + etcd + worker node)  

## Install docker
> * Install docker (All VMs)  
> <code>sudo bin/ubuntu20lts_install_docker.sh </code>  

## Deploy Gitlab on VM1  
> <code> sudo gitlab/create_gitlab.sh </code>  

## Setting gitlab  
> * set gitlab new password  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/set-gitlab-new-password.png?raw=true)  

> * Generate root personal access tokens  
>   * User/Administrator/User seetings, gernerate root perionsal accesss token, and keep it.  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/root-settings.png?raw=true)  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/generate-root-persional-access-token.png?raw=true)
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/gitlab-rootpat.png?raw=true)  
> * Admin/Settings/Network/Outbound reuests，enable allonw request to the local netowrk  service
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/allow-request-to-the-local-netowrk.png?raw=true)  

# install rancher on VM2 
> <code> ./bin/ubuntu20lts_install_rancher.sh  </code>  
> * set admin password
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/set-racnher-admin-password.png?raw=true)  
> * set rancher server url  

# Create a Kubernetes by rancher
> ## Add cluster
> * add cluster/ From existing nodes(Custom)  
>   * Cluster name:  Then
>   * Kubernetes Version: Then newest kubernetes version  
>   * Network provider: Calico  
>   * CNI Plugin MTU Override: 1440  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-add-cluster.png?raw=true)  
>   * Node Options: Chose etcd, Control plane, worker
>   * Copy command to run on VM3, VM4  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-cluster-node-option.png?raw=true)  

# Get Kubeconfig Files
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-cluster-kubeconfig.png?raw=true)  
> Put on kubeconfig file to $HOME/.kube/config, and also keep it.  

# Gitlab and Rancher pipline hook  
> ## Rancher  
>  Choose Global/ Cluster(iiidevops-k8s)/ Project(Default)  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-choose-cluster-project.png?raw=true)  
> Choose Tools/Pipline, select Gitlab  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-setting-hook.png?raw=true)  
> Get the "Redirect URI"  
> ## Gitlab  
> Use root account/ settings/ Applications
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/gitlab-root-setting.png?raw=true)  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/gitlab-usersetting-application.png?raw=true)  
> Setting Applications  
> insert name, redirect url and chose all optional, and save application.
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/gitlab-setting-application.png?raw=true)  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/gitlab-application-info.png?raw=true)  
> Take the "Application ID" and "Secret", go to rancher pipeline, insert application id, secret and private gitlab url.  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-setting-applicationsecret.png?raw=true)  
> Authorize  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/gitlab-authorize.png?raw=true)  
> Done  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-hook-down.png?raw=true)  

# Prepare storage (Use NFS below)
> ## VM2 (NFS Server)  
> * Install NFS service  
> <code> sudo apt install nfs-kernel-server -y </code>  
> * Edit /etc/exports, add  
> <code>/iiidevopsNFS *(no_root_squash,rw,sync,no_subtree_check) </code>  

> * Create folder /iiidevopsNFS for NFS service  
> <code> sudo mkdir /iiidevopsNFS </code>  
> <code> sudo chmod 777 /iiidevopsNFS </code>  
> * Restart NFS service  
> <code> sudo systemctl restart nfs-kernel-server </code>  
> * Check NFS service  
> <code> sudo showmount -e localhost  </code>  
> * Create redmine-postgresql folder for redmine-postgresql  
> <code> sudo mkdir /iiidevopsNFS/redmine-postgresql </code>  
> <code> sudo chmod 777 /iiidevopsNFS/redmine-postgresql </code>  
> * Create devopsdb folder for DevOps DB  
> <code> sudo mkdir /iiidevopsNFS/devopsdb </code>  
> <code> sudo chmod 777 /iiidevopsNFS/devopsdb </code>  

> ## VM3, VM4 (NFS Client, Kubernetes worker node)  
> * Install on VM2  
> <code>sudo apt install nfs-common </code>  
> * Check NFS Service  
> <code> showmount -e {NFS server IP} </code>

# Install kubectl (On user client)
> https://kubernetes.io/docs/tasks/tools/install-kubectl/  
> Used Mac 
>> Example: Mac install kubectl by brew  
>> <code> brew install kubectl </code>  
>> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/mac-brew-install-kubectl.png?raw=true)  
>> <code> kubectl version --client </code>  
>> Example: Mac install kubectl by curl  
>> <code> curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/darwin/amd64/kubectl" </code>  
>> <code> chmod +x ./kubectl </code>  
>> <code> sudo mv ./kubectl /usr/local/bin/kubectl </code>  
>> <code> kubectl version --client </code>  

> Used Windows, install kubectl by curl 
>> <code> curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.19.0/bin/windows/amd64/kubectl.exe </code>  
>> Execute kubectl.exe

# Deploy Redmine on kubernetes cluster  
> * deploy redmine postgresql  
> <code> kubectl apply -f redmine/redmine-postgresql/ </code>  
> * deploy redmine  
> <code> kubectl apply -f redmine/redmine/ </code>  
> * redmine url  
> http://140.92.4.5:32748/

# Set Redmine
> * login by admin/ admin, and reset administrator password
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/reset-redmine-admin-password.png?raw=true)  
> * Enable REST API
>   * Administration/ Settings/ API/ Enable REST web service
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/enable-redmine-rest.png?raw=true)  
> * Generate redmine admin token
>   * My account/ API access key/ Show
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/redmine-admin-apikey.png?raw=true)  
> * wiki set markdown  
>   * Administration/ Setting/ Gereral/ Text formatting  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/redmine-set-testformat-markdown.png?raw=true)  
> * Create issue status  
>   *  Administration/ Issues statuses  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/redmine-set-issue-status.png?raw=true)  
> * Create Trackers  
>   *  Administration/ Trackers  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/redmine-set-trackers.png?raw=true)  
> * Create roles
>   * Administration/ Roles and permissions
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/redmine-create-roles.png?raw=true)  
> * Create priority
>   * Administration/ Enumerations/ Issue priorities
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/redmine-create-priority.png?raw=true)  

# Deploy DevOps DB (Postgresql) on kubernetes cluster  
> <code> docker build devops-db --tag devops-db:version </code>  
> <code> docker push  devops-db:version </code>  
> <code> kubectl apply -f devops-db/devopsdb-deployment.yaml </code>  
> <code> kubectl apply -f devops-db/devopsdb-service.yaml </code>  

# Deploy DevOps API (Python Flask) on kubernetes cluster  
> <code> cd ../ </code>  
> <code> git clone -b develope https://github.com/iii-org/devops-system.git </code>  
> <code> cd devops-system </code>  
> <code> cp $HOME/.kube/config k8s_config</code>  
> <code> docker build . --tag {{DockerHub_account}}/devopsapi:{{version}} </code>  
> <code> docker push {{DockerHub_account}}/devopsapi:{{version}} </code>  
> <code> docker login </code>  
> <code> cd ../deploy-devops </code>  
> Edit devops-ui/devopsapi-deployment.yaml, replace image name. From iiiorg/devops-api:0cb6e72-10121141, to {{DockerHub_account}}/devopsapi:{{version}}.  
> <code> kubectl apply -f devops-api/devopsapi-deployment.yaml </code>  
> <code> kubectl apply -f devops-api/devopsapi-service.yaml</code>  

# Deploy DevOps UI (VueJS) on kubernetes cluster  
> Install Node jS  
> <code> cd ../ </code>  
> <code> git clone -b develop https://github.com/iii-org/devops-ui.git </code>  
> <code> cd devops-ui </code>  
> Edit  .env.staging, replace VUE_APP_BASE_API = '/stage-api' to be VUE_APP_BASE_API = 'http://{{VM3_IP}}:31850'  
> <code> npm install </code>  
> <code> npm run build:stage </code>  
> <code> docker build . --tag {{DockerHub_account}}/devopsui:{{version}} </code>  
> <code> docker push {{DockerHub_account}}/devopsui:{{version}} </code>  
> <code> docker login </code>  
> <code> cd ../deploy-devops </code>  
> Edit devops-ui/devopsui-deployment.yaml, replace image name. From iiiorg/devops-ui:prod-0cb6e72, to {{DockerHub_account}}/devopsui:{{version}}.  
> <code> kubectl apply -f devops-ui/devopsui-deployment.yaml </code>  
> <code> kubectl apply -f devops-ui/devopsui-service.yaml </code>  

# Finish. Go to Web UI to login, Account: admin, Password: administrator
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/devops-ui.png?raw=true)  