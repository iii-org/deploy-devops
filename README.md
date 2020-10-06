# deploy-devops
## Environment  
4 Ubuntu20.04 LTS VM  
> VM1 GitLab ce-12.10.6 Server  
> VM2 Rancher Server  
> VM3, VM4 Kubernetes node
## Install docker
> ### Install docker (All VMs)  
> <code>sudo bin/ubuntu20lts_install_docker.sh </code>  

> ### Deploy Gitlab on VM1  
> <code> sudo gitlab/create_gitlab.sh </code>  

> ### Setting gitlab  
>> set gitlab new password  
>> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/set-gitlab-new-password.png?raw=true)  

>> Generate root personal access tokens  
>> User/Administrator/User seetings, gernerate root perionsal accesss token  
>>![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/root-settings.png?raw=true)  
>> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/generate-root-persional-access-token.png?raw=true)