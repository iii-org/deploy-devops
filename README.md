# deploy-devops
<<<<<<< HEAD
## Environment  
4 Ubuntu20.04 LTS VM  
> VM1 GitLab ce-12.10.6 Server  
> VM2 Rancher Server  
> VM3, VM4 Kubernetes node
## Install docker
> ### Install docker (All VMs)  
> <code>sudo bin/ubuntu20lts_install_docker.sh </code>  
=======
## Environment
### 4 Ubuntu20.04 LTS VM
#### VM1 GitLab ce-12.10.6 Server
#### VM2 Rancher Server
#### VM3, VM4 Kubernetes node
## Install
### Install docker (All VMs)
#### <code>sudo bin/ubuntu20lts_install_docker.sh </code>
### Deploy Gitlab on VM1
#### <code> sudo gitlab/create_gitlab.sh </code>
### Setting gitlab
#### set gitlab new password
![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/set-gitlab-new-password.png?raw=true)
#### Generate root personal access tokens
##### User/Administrator/User seetings, gernerate root perionsal accesss token
![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/root-settings.png?raw=true)
![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/generate-root-persional-access-token.png?raw=true)
##### GO to Admin/Settings/Network/"Outbound reuests"，tick "allow request to the local netowrk"
![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/allow-request-to-the-local-netowrk.png?raw=true)
>>>>>>> 5cc3ccbed77625f91ed2a882b889ad764ae86e7c

> ### Deploy Gitlab on VM1  
> <code> sudo gitlab/create_gitlab.sh </code>  

> ### Setting gitlab  
>> set gitlab new password  
>> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/set-gitlab-new-password.png?raw=true)  

>> Generate root personal access tokens  
>> User/Administrator/User seetings, gernerate root perionsal accesss token  
>>![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/root-settings.png?raw=true)  
>> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/generate-root-persional-access-token.png?raw=true)