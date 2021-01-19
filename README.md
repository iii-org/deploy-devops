# deploy-devops
## Environment

* 2 Ubuntu20.04 LTS VM  (The minimum resource configuration of a virtual machine is 4 vcore, 8G ram, 32G HD; however, for production environment, it should be 3 or more VMs with 8 vcore, 16G ram, 120G SSD)
  * VM1(iiidevops1, 10.20.0.71): Harbor 2.1 Server, Rancher Server, NFS Server  
  * VM2(iiidevops2, 10.20.0.72): Kubernetes node(control plane + etcd + worker node), used to run GitLab ce-12.10.6 Server, Redmine 4.1.1, etc.
* Before installation, you should decide on these configuration settings
  * IP of VM1 and VM2
  * Deploy mode:IP or DNS
    - IP : External access IP of VM1 and VM2
    - DNS: Domain names of III DevOps, GitLab, Redmine, Harbor. (If you choose DNS deployment mode but do not provide a domain name, it will automatically use the xip.io service to become your domain name)
  * GitLab root password
  * Rancher admin password
  * Redmine admin password
  * Harbor admin passowrd
  * III-devops super user account ('admin' and 'root' are not allowed)
  * III-devops super user E-Mail
  * III-devops super user password

* During the installation process, you should be able to get the following setup information through GitLab Web UI
  * GitLab private token

* You can scale out the Kubernetes nodes (VM3, VM4, VM5...) and scale up the VM1 according to actual performance requirements.


# Step 1. Download deploy-devops and Install docker (VM1)

> ```bash
> wget https://raw.githubusercontent.com/iii-org/deploy-devops/master/bin/iiidevops_install.pl;
> perl ./iiidevops_install.pl local
> ```
> * If everything is correct, you will see that all check items are OK shown below.
> 
> ```
> localadmin@iiidevops-71:~$ perl ./iiidevops_install.pl local
> :
> :
> :
> -----Validation results-----
> Install docker 19.03.14 ..OK!
> Install kubectl v1.18 ..OK!
> ```

# Step 2. Generate configuration setting information file "env.pl" (VM1)

> ```bash
> ~/deploy-devops/bin/generate_env.pl
> ````
> * After entering, please check whether the configuration setting information is correct.  You can also edit this env.pl configuration file data.
>
>   ``` vi ~/deploy-devops/env.pl```

# Step 3. Deploy Harbor / Rancher / NFS (VM1)

> ``` sudo ~/deploy-devops/bin/iiidevops_install_base.pl```
>
> After the deployment is complete, you should be able to see the URL information of these services as shown below.
>
> * Harbor - https://10.20.0.71/
> * Rancher - https://10.20.0.71:6443/

# Step 4. Setting Harbor server

> * Harbor - https://10.20.0.71/
> * **Log in with the account admin and password ($harbour_admin_password) you entered in step 2.(~/deploy-devops/env.pl)**
> 
> * Check Project - dockerhub (Access Level : **Public** , Type : **Proxy Cache**) was added.
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/harbor_dockerhub_project.png?raw=true)  
> * If the project dockerhub is not created, you can exectue the command to manually create it.   
> 
>   ```sudo ~/deploy-devops/harbor/create_harbor.pl create_dockerhub_proxy```
>

# Step 5. Set up Rancher from the web UI

> * Rancher - https://10.20.0.71:6443/
> * **Use the $rancher_admin_password entered in Step 2.(~/deploy-devops/env.pl) to set the admin password**
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/set-racnher-admin-password.png?raw=true)  
>   
> * set **Rancher Server URL**  

# Step 6. Create a Kubernetes by Rancher

> * add cluster/ From existing nodes(Custom)  
>   * Cluster name:  **iiidevops-k8s**
>   * Kubernetes Version: Then newest kubernetes version  Exp. **v.118.12-rancher1-1 **
>   * Network provider: **Calico**  
>   * CNI Plugin MTU Override: **1440**  
>   ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-add-cluster.png?raw=true)  
>   * Click Next to  save the setting (It will take a while. If  you receive the error message "Failed while: Wait for Condition: InitialRolesPopulated: True", just click 'Next' again.)
>   * Node Options: Chose etcd, Control plane, worker
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-cluster-node-option.png?raw=true)  

## Copy the command to add-k8s.sh and make VM2 join the K8S cluster
> * Copy the command to /iiidevopsNFS/deploy-config/add_k8s.sh 
>
>   ```vi /iiidevopsNFS/deploy-config/add_k8s.sh```
>
> * Execute the following command on VM1 to make VM2 join the K8S cluster.
>
>   ```~/deploy-devops/bin/add-k8s-node.pl [user@vm2_ip]```
>
>   It should display as below.
>   ```bash
>   localadmin@iiidevops-71:~$ ~/deploy-devops/bin/add-k8s-node.pl localadmin@10.20.0.72
>   :
>   :
>   :
>   -----Validation results-----
>   Docker          : OK!
>   Kubectl         : OK!
>   NFS Client      : OK!
>   Harbor Cert     : OK!
>
>   Please goto Rancher Web - https://10.20.0.71:6443 to get the status of added node of k8s cluster!
>   ```
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
> > ```kubectl cluster-info ```
>
> It should display as below.
>
> ```bash
> localadmin@iiidevops-71:~$ kubectl cluster-info
> Kubernetes master is running at https://10.20.0.71:6443/k8s/clusters/c-fg42q
> CoreDNS is running at https://10.20.0.71:6443/k8s/clusters/c-fg42q/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
> 
> To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
> ```

# Step 7. Deploy GitLab, Redmine, Sonarqube on kubernetes cluster

> ```~/deploy-devops/bin/iiidevops_install_cpnt.pl```
>
>
> After the deployment is complete, you should be able to see the URL information of these services as shown below.
>
> * GitLab - http://10.20.0.72:32080/ or http://gitlab.iiidevops.10.20.0.72.xip.io/ 
> * Redmine - http://10.20.0.72:32748/ or http://redmine.iiidevops.10.20.0.72.xip.io/
> * Sonarqube - http://10.20.0.72:31910/ or http://sonarqube.iiidevops.10.20.0.72.xip.io/

# Step 8. Set up GitLab from the web UI

> * GitLab - http://10.20.0.72:32080/ or http://gitlab.iiidevops.10.20.0.72.xip.io/ 
> * **Log in with the account root and password ($gitlab_root_passwd) you entered in step 2.(~/deploy-devops/env.pl)**
>

## Set up Rancher pipeline and Gitlab hook
> * Choose Global/ Cluster(iiidevops-k8s)/ Project(Default)  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-choose-cluster-project.png?raw=true)  
> * Choose Tools/Pipline, select Gitlab  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-setting-hook.png?raw=true)  
> Get the "Redirect URI" and then open GitLab web UI
>

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
>
> Switch back to GitLab web UI


## Generate **root personal access tokens** 
> * User/Administrator/User seetings, generate the root personal access tokens and keep it.  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/root-settings.png?raw=true)  
>
> * Access Tokens / Name : root-pat / Scopes : Check all / Create personal access token  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/generate-root-persional-access-token.png?raw=true)
>
> * Keep Your New Personal Access Token 
>   ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/gitlab-rootpat.png?raw=true)  
>
> * Modify the **$gitlab_private_token** value in env.pl
>
>   ```~/deploy-devops/bin/generate_env.pl ask_gitlab_private_token [Personal Access Token]```
>
>   It should display as below.
>   ```bash
>   localadmin@iiidevops-71:~$ ~/deploy-devops/bin/generate_env.pl ask_gitlab_private_token 535wZnCJDTL5y22xYYzv
>   A4. Set GitLab Token OK!
> 
>   Q21. Do you want to generate env.pl based on the above information?(Y/n)
>   The original env.pl has been backed up as /home/localadmin/deploy-devops/bin/../env.pl.bak
>   -----
>   11c11
>   < $gitlab_private_token = '535wZnCJDTL5y22xYYzv'; # Get from GitLab Web
>   ---
>   > $gitlab_private_token = 'skip'; # Get from GitLab Web
>   -----
>   ```
>

## Enable Outbound requests from web hooks
> * Admin Area/Settings/Network/Outbound reuests, enable **allow request to the local network from web hooks and service** / Save changes
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/allow-request-to-the-local-netowrk.png?raw=true)  
>

# Step 9. Deploy III-DevOps

> ```~/deploy-devops/bin/iiidevops_install_core.pl```
>
> You should wait 3 to 5 minutes to complete the deployment and initial system setup. Then, you can access the URL as shown below.
>
> ```
> :
> :
> .
> 
> Add Secrets Credentials
> -----
> nexus : Create Secrets /home/localadmin/deploy-devops/devops-api/secrets/nexus-secret.json..OK!
> checkmarx : Create Secrets /home/localadmin/deploy-devops/devops-api/secrets/checkmarx-secret.json..OK!
> webinspect : Create Secrets /home/localadmin/deploy-devops/devops-api/secrets/webinspect-secret.json..OK!
> 
> Add Registry Credentials
> -----
> harbor-local : Create Registry /home/localadmin/deploy-devops/devops-api/secrets/harbor-local-registry.json..OK!
> 
> The deployment of III-DevOps services has been completed. Please try to connect to the following URL.
> III-DevOps URL - http://10.20.0.72:30775 or http://iiidevops.10.20.0.72.xip.io/
>
> ```

## Go to Web UI to login 
> * III-DevOps URL -  http://10.20.0.72:30775/ or http://iiidevops.10.20.0.72.xip.io/ 
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/devops-ui.png?raw=true)  
>
> Use the **$admin_init_login** and **$admin_init_password** entered in Step 2.(~/deploy-devops/env.pl) to login to III-DevOps

# Step 10. Scale-out K8s Node

> * Execute the following command on VM1 to make VM3 join the K8s cluster.
>
>   ```~/deploy-devops/bin/add-k8s-node.pl [user@vm3_ip]```
>
>   It should display as below.
>   ```bash
>   localadmin@iiidevops-71:~$ ~/deploy-devops/bin/add-k8s-node.pl localadmin@10.20.0.73
>   :
>   :
>   :
>   -----Validation results-----
>   Docker          : OK!
>   Kubectl         : OK!
>   NFS Client      : OK!
>   Harbor Cert     : OK!
>   -----
>   NAME           STATUS   ROLES                      AGE   VERSION
>   iiidevops-72   Ready    controlplane,etcd,worker   23h   v1.18.12
>   ```
>   * After executing this command, it will take about 3 to 5 minutes for the node to join the cluster.

