# deploy-devops
## Environment  

* 2 Ubuntu20.04 LTS VM  (The minimum resource configuration of the virtual machine is 4 vcore, 8G ram, 32G HD)
  * VM1(iiidevops1, 10.20.0.71): GitLab ce-12.10.6 Server, Harbor 2.1 Server, Rancher Server, NFS Server  
  * VM2(iiidevops2, 10.20.0.72): Kubernetes node(control plane + etcd + worker node)
* Before installation, you should decide on these configuration settings
  1. External access IP or domain name of VM1 and VM2
  2. GitLab root password
  3. Rancher admin password
  4. Redmine admin password
  5. Harbor admin passowrd
  6. III-devops super user account ('admin' and 'root' are not allowed)
  7. III-devops super user E-Mail
  8. III-devops super user password

* After installation, you should be able to get the following setup information through Redmine and GitLab Web UI
  1. GitLab private token
  2. Redmine API key

* You can scale out the Kubernetes nodes (VM3, VM4, VM5...) or scale up the VM1 according to actual performance requirements.


# Step 1. Download deploy-devops and Install docker (VM1)

> ```bash
> wget https://raw.githubusercontent.com/iii-org/deploy-devops/master/bin/iiidevops_install.pl
> perl ./iiidevops_install.pl local
> perl ./iiidevops_install.pl localadmin@10.20.0.72
> ```
> * If everything is correct, you will see that all check items are OK shown below.
> 
> ```
> localadmin@iiidevops-71:~$ perl ./iiidevops_install.pl localadmin@10.20.0.72
> :
> :
> :
> -----
> Install docker 19.03.14 ..OK!
> Install kubectl v1.18 ..OK!
> 
> -----
> ```

# Step 2. Generate configuration setting information file "env.pl" (VM1)

> ```bash
> ~/deploy-devops/bin/generate_env.pl
> ````
> * After entering, please check whether the configuration setting information is correct.  You can also edit this env.pl configuration file data.
>
>   ``` vi ~/deploy-devops/env.pl```

# Step 3. Deploy Gitlab / Harbor / Rancher / NFS (VM1)

> ``` sudo ~/deploy-devops/bin/iiidevops_install_mainapps.pl```
>
> After the deployment is complete, you should be able to see the URL information of these services as shown below.
>
> * GitLab - http://10.20.0.71/ 
> * Rancher - https://10.20.0.71:6443/
> * Harbor - https://10.20.0.71:5443/

# Step 4. Set up GitLab from the web UI
> * GitLab - http://10.20.0.71/ 
> * **Use the $gitlab_root_passwd entered in Step 2.(~/deploy-devops/env.pl) as GitLab new password** 
>![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/set-gitlab-new-password.png?raw=true)  
>   

>
>* After setting a new password for GitLab, you should log in again with **root** and the **new password**
>
>* Generate **root personal access tokens**  
>
>
> * User/Administrator/User seetings, generate the root personal access tokens and keep it.  
>   ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/root-settings.png?raw=true)  
>
>  * Access Tokens / Name : root-pat / Scopes : Check all / Create personal access token  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/generate-root-persional-access-token.png?raw=true)
>
> * Keep Your New Personal Access Token 
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/gitlab-rootpat.png?raw=true)  
>
>* Enable Outbound requests from web hooks
>
>
> * Admin Area/Settings/Network/Outbound reuests, enable **allow request to the local network from web hooks and service** / Save changes
>   ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/allow-request-to-the-local-netowrk.png?raw=true)  
>
>* Modify the **$gitlab_private_token** value in env.pl
>
>> ```~/deploy-devops/bin/generate_env.pl ask_gitlab_private_token```
>
> It should display as below.
>```bash
> localadmin@iiidevops-71:~$ ~/deploy-devops/bin/generate_env.pl ask_gitlab_private_token
> Q4. Please enter the GitLab Token:(If your GitLab has not been set up, please enter 'SKIP')GexxxxWxxxdJyCyz4knt
> A4. Set GitLab Token OK!
>
> Q21. Do you want to generate env.pl based on the above information?(y/N)y
> The original env.pl has been backed up as /home/localadmin/deploy-devops/bin/../env.pl.bak
>```

# Step 5. Set up Rancher from the web UI
> * Rancher - https://10.20.0.71:6443/
> * **Use the $rancher_admin_password entered in Step 2.(~/deploy-devops/env.pl) as admin password**
>![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/set-racnher-admin-password.png?raw=true)  
>   
>* set **Rancher Server URL**  

## Create a Kubernetes by rancher
> ## Add cluster
> * add cluster/ From existing nodes(Custom)  
>   * Cluster name:  **iiidevops-k8s**
>   * Kubernetes Version: Then newest kubernetes version  Exp. **v.118.12-rancher1-1 **
>   * Network provider: **Calico**  
>   * CNI Plugin MTU Override: **1440**  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-add-cluster.png?raw=true)  
>   * Click Next to  save the setting (It will take a while. If  you receive the error message "Failed while: Wait for Condition: InitialRolesPopulated: True", just click 'Next' again.)
>   * Node Options: Chose etcd, Control plane, worker
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-cluster-node-option.png?raw=true)  

## Copy command to /iiidevopsNFS/deploy-config/add_k8s.sh for VM2
>
> ```bash
> vi /iiidevopsNFS/deploy-config/add_k8s.sh
> ```
> * Excute the following command on VM1 to make VM2 a K8S node.
> ```bash
> ~/deploy-devops/bin/add-k8s-node.pl localadmin@10.20.0.72
> ```
>
> * After executing this command, it takes about 5 to 10 minutes to build the cluster.  
> * Rancher Web UI will automatically refresh to use the new SSL certificate. You need to login again.  After the iiidevops-k8s cluster is activated, you can get kubeconfig file.
>

## Get Kubeconfig File
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-cluster-kubeconfig.png?raw=true)  
> Put on kubeconfig file to **~/.kube/config** and **/iiidevopsNFS/kube-config/config** on VM1, and also keep it.  
> ```bash
>  vi /iiidevopsNFS/kube-config/config
>  ln -s /iiidevopsNFS/kube-config/config ~/.kube/config
> ```
>
> Use the following command to check if the config is working
>
> > <code> kubectl top node </code>
>
> It should display as below.
>
> ```bash
> localadmin@iiidevops-71:~$ kubectl top node
> NAME           CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
> iiidevops-72   258m         12%    2008Mi          25%
> ```

## setting Gitlab and Rancher pipline hook  
> ## Rancher  
> Choose Global/ Cluster(iiidevops-k8s)/ Project(Default)  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-choose-cluster-project.png?raw=true)  
> Choose Tools/Pipline, select Gitlab  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-setting-hook.png?raw=true)  
> Get the "Redirect URI"  
>
> ## Gitlab  
> Use root account/ settings/ Applications
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/gitlab-root-setting.png?raw=true)  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/gitlab-usersetting-application.png?raw=true)  
> Setting Applications  
> insert Name : iiidevops-k8s, Redirect URI: [from Rancher] and chose all optional, and save application.
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/gitlab-setting-application.png?raw=true)  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/gitlab-application-info.png?raw=true)  
> Take the "Application ID" and "Secret", go to rancher pipeline, insert application id, secret and private gitlab url.  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-setting-applicationsecret.png?raw=true)  
> Authorize  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/gitlab-authorize.png?raw=true)  
> Done  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-hook-down.png?raw=true)  

# Step 6. Setting harbor server 
* Harbor - https://10.20.0.71:5443/
* Use **admin** and the **$harbour_admin_password** entered in Step 2.(~/deploy-devops/env.pl) to login to harbour

* Check Project - dockerhub (Access Level : **Public** , Type : **Proxy Cache**) was added. 

# Step 7. Check NFS Client and Harbor cert of the Kubernetes worker node
> * You can run the check-k8s-node.pl script on VM1 to check all k8s nodes
>
>   ``` ~/deploy-devops/bin/check-k8s-node.pl [user@k8s_ip] ```
>
>   If everything in the k8s node is correct, you will see that all check items are OK in the verification result shown below.
>   ```bash
>   localadmin@iiidevops-71:~$ ~/deploy-devops/bin/check-k8s-node.pl localadmin@10.20.0.72
>   :
>   :
>   :
>   -----Validation results-----
>   NFS Client      : OK!
>   Harbor Cert     : OK!
>   ```

# Step 8. Install kubectl (On user client if you need)
> https://kubernetes.io/docs/tasks/tools/install-kubectl/  
> ## All virtual machines have been installed in Step 1.
>
> ## Used Mac 
> > Example: Mac install kubectl by brew  
> > <code> brew install kubectl </code>  
> > ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/mac-brew-install-kubectl.png?raw=true)  
> > <code> kubectl version --client </code>  
> > Example: Mac install kubectl by curl  
> > <code> curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/darwin/amd64/kubectl" </code>  
> > <code> chmod +x ./kubectl </code>  
> > <code> sudo mv ./kubectl /usr/local/bin/kubectl </code>  
> > <code> kubectl version --client </code>  

> ## Used Windows, install kubectl by curl 
>> <code> curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.19.0/bin/windows/amd64/kubectl.exe </code>  
>> Execute kubectl.exe

# Step 9. Deploy Redmine on kubernetes cluster
> <code> ~/deploy-devops/bin/iiidevops_install_apps.pl </code>
>
> After running the script, you should wait 1 to 3 minutes for these services to start running.
>

> ## Redmine
> * Redmine URL - http://10.20.0.72:32748/
> * **login by admin/ admin, and reset the administrator password using $redmine_admin_passwd entered in Step 2.(~/deploy-devops/env.pl)**
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/reset-redmine-admin-password.png?raw=true)  
> * Enable REST API
>   * Administration/ Settings/ API/ Enable REST web service
>   ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/enable-redmine-rest.png?raw=true)  
> * Generate redmine admin token
>   * My account/ API access key/ Show
>   ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/redmine-admin-apikey.png?raw=true)  
> * set API access key to env.pl
>   
>   ``` ~/deploy-devops/bin/generate_env.pl ask_redmine_api_key```
>   ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/redmine_set_API_access_key.png?raw=true)
> * wiki set markdown  
>   * Administration/ Setting/ Gereral/ Text formatting  
>   ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/redmine-set-testformat-markdown.png?raw=true)  
> * Create issue status  
>   * Administration/ Issues statuses / New status
>     * Active, Assigned, Solved, Responded, Finished, Closed
>     ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/redmine-set-issue-status.png?raw=true)  
> * Create Trackers  
>   * Administration/ Trackers / New tracker
>     * Feature, Bug, Document, Research
>     ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/redmine-set-trackers.png?raw=true)  
> * Create roles
>   * Administration/ Roles and permissions / New role
>   * Engineer, Project Manager
>     * Engineer Permissions : Check all and then uncheck all project permissions 
>     ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/redmine-engineer-permissions.png?raw=true)
>     * Project Manager Permissions :  Check all 
>     ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/redmine-pm-permissions.png?raw=true)
>   ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/redmine-create-roles.png?raw=true)  
> * Create priority
>   * Administration/ Enumerations/ Issue priorities / New value
>     * Immediate, High, Normal, Low
>     ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/redmine-create-priority.png?raw=true)  

# Step 10. Deploy III-DevOps
> <code> ~/deploy-devops/bin/iiidevops_install_core.pl </code>
>
> You should wait 3 to 5 minutes to complete the deployment and initial system setup. Then, you can access the URL as shown below.
>
> ## Go to Web UI to login 
> * III-DevOps URL -  http://10.20.0.72:30775/ 
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/devops-ui.png?raw=true)  
>
> Use the **$admin_init_login** and **$admin_init_password** entered in Step 2.(~/deploy-devops/env.pl) to login to III-DevOps
