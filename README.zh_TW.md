# deploy-devops
## 安裝環境需求

* III DevOps 系統需安裝在 Ubuntu 20.04 LTS 作業系統, 採用虛擬機 virtual machine(VM) 來進行部署, 讓系統可以依照實際運行狀況進行快速擴充
* 虛擬機的最小規格為 1 台 8 vCore, 16G RAM, 120G HD , 建議在正式開發產品的環境上需要至少 3 台以上的虛擬機且建議使用 SSD 硬碟, 確保檔案存取速度
* 在開始安裝之前, 您應該要先確認一下的安裝設定資訊
  * 虛擬機的 IP
  * 安裝部署的模式 IP, DNS, nip.io 或是 xip.io (nip.io 和 xip.io 應該儘安裝在驗證與評估的環境)
	- IP 模式 : 直接透過 IP 存取 III DevOps 系統
    - DNS 模式: 提供 Domain names 對應到 III DevOps 與相關服務 (GitLab, Redmine, Harbor, Sonarqube)
	- nip.io 與 xip.io: 使用這兩項網路免設定 Domain names 的服務來對應到 III DevOps 與相關服務 (GitLab, Redmine, Harbor, Sonarqube)
  * GitLab 的 root 密碼
  * Harbor, Rancher, Redmine, Sonarqube 的 admin 密碼 (可以和 GitLab 的 root 密碼相同)
  * III-devops 第一位使用者 ( III DevOps 的系統管理者)
    - 帳號 (不允許 'admin' 與 'root')
    - E-Mail
    - 密碼 (可以和 GitLab 的 root 密碼相同)

* 系統安裝之後可以依據實際建立專案的使用需要, 針對 Kubernetes 節點進行橫向擴充 (VM2, VM3, VM4, VM5...) 也可能需要針對 VM1 擴增硬碟大小

* 如果安裝環境外部有防火牆, 請增加防火牆規則讓使用者的來源 IP 到 III DevOps 主機(VM) 的 TCP port 80/443/3443/30000~32767 可允許存取


# Step 1. 下載部署程式與安裝 docker 環境

> ```bash
> wget https://raw.githubusercontent.com/iii-org/deploy-devops/master/bin/iiidevops_install.pl;
> perl ./iiidevops_install.pl local
> ```
> * 如果一切安裝順利, 你應該可以看到如同以下對各項檢查都 OK 的訊息
> 
> ```
> localadmin@iiidevops-71:~$ perl ./iiidevops_install.pl local
> :
> :
> -----Validation results-----
> Install docker 19.03.14 ..OK!
> Install kubectl v1.18 ..OK!
> Install helm v3.5 ..OK!
> ```

# Step 2. 產生安裝環境設定檔 "env.pl"

> ```bash
> ~/deploy-devops/bin/generate_env.pl
> ````
> * 在各項問題都輸入後, 請檢察輸入的項目是否都正確無誤. 你也可以直接編輯這個環境設定檔 env.pl 來進行環境設定資料的修正
>
>   ``` vi ~/deploy-devops/env.pl```

# Step 3. 部署 NFS 和 Rancher

> ``` sudo ~/deploy-devops/bin/iiidevops_install_base.pl```
>
> 當完成部署後, 你應該可以看到如同以下的 URL 資訊.
>
> * Rancher - https://10.20.0.71:3443/

# Step 4. 透過 Rancher 的 web 介面進行設定

> * Rancher - https://10.20.0.71:3443/
> * **請使用 Step 2.(~/deploy-devops/env.pl) 內所設定的 $rancher_admin_password 來輸入設定 Rancher 的 admin password**
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/set-racnher-admin-password.png?raw=true)  
>   
> * 接著設定 **Rancher Server URL**  (一般而言會顯示出正確 URL, 確認即可)

## 透過 Rancher 來建立 Kubernetes Cluster
> * 點 Add Cluster 後, 選擇 From existing nodes(Custom), 依照以下的資訊依次輸入與選定
>   * Cluster Name: **iiidevops-k8s** 
>   * Kubernetes Version: Then newest kubernetes version  Exp. **v.118.15-rancher1-1**
>   * Network provider: **Calico**  
>   * CNI Plugin MTU Override: **1440**  
>   ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-add-cluster.png?raw=true)  
>   * Click Next to  save the setting (It will take a while. If  you receive the error message "Failed while: Wait for Condition: InitialRolesPopulated: True", just click 'Next' again.)
>   * Node Options: Chose etcd, Control plane, worker
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-cluster-node-option.png?raw=true)  

## Copy the command to add-k8s.sh and build the K8s cluster
> * Copy the command to /iiidevopsNFS/deploy-config/add_k8s.sh 
>
>   ```vi /iiidevopsNFS/deploy-config/add_k8s.sh```
>
> * Execute the following command to build the K8s cluster.
>
>   ```sh /iiidevopsNFS/deploy-config/add_k8s.sh```
>
>   It should display as below.
>   ```bash
>   localadmin@iiidevops-71:~$ sh /iiidevopsNFS/deploy-config/add_k8s.sh
>   Unable to find image 'rancher/rancher-agent:v2.4.5' locally
>   v2.4.5: Pulling from rancher/rancher-agent
>   d7c3167c320d: Already exists
>   :
>   :
>   :
>   Digest: sha256:f263b6df0dccfafe5249618498287cae19673999face1a1555ac58f665974418
>   Status: Downloaded newer image for rancher/rancher-agent:v2.4.5
>   73f824ccd94f5e7b871bcd13f1a0023c6f63af0036cb9a73927f61461a75b3ae
>   ```
>
> * After executing this command, it takes about 5 to 10 minutes to build the cluster.  
> * Rancher Web UI will automatically refresh to use the new SSL certificate. You may need to login again. After the iiidevops-k8s cluster is activated, you can get the kubeconfig file.
>

## Get iiidevops-k8s Kubeconfig File
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-cluster-kubeconfig.png?raw=true)  
> Put on kubeconfig file to **~/.kube/config** and **/iiidevopsNFS/kube-config/config** and also keep it.
> ```bash
>  touch /iiidevopsNFS/kube-config/config
>  ln -s /iiidevopsNFS/kube-config/config ~/.kube/config
>  vi /iiidevopsNFS/kube-config/config
> ```
> After pasting the Kubeconfig File, you can use the following command to check if the configuration is working properly.
>
> > ```kubectl cluster-info```
>
> It should display as below.
>
> ```bash
> localadmin@iiidevops-71:~$ kubectl cluster-info
> Kubernetes master is running at https://10.20.0.71:3443/k8s/clusters/c-fg42q
> CoreDNS is running at https://10.20.0.71:3443/k8s/clusters/c-fg42q/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
> 
> To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
> ```

# Step 5. Deploy GitLab, Redmine, Harbor, Sonarqube on kubernetes cluster

> ```~/deploy-devops/bin/iiidevops_install_cpnt.pl```
>
>
> After the deployment is complete, you should be able to see the URL information of these services as shown below.
>
> * GitLab - http://10.20.0.71:32080/
> * Redmine - http://10.20.0.71:32748/
> * Harbor - http://10.20.0.71:32443/
> * Sonarqube - http://10.20.0.71:31910/

# Step 6. Set up GitLab from the web UI

> * GitLab - http://10.20.0.71:32080/
> * **Log in with the account root and password ($gitlab_root_passwd) you entered in step 2.(~/deploy-devops/env.pl)**
>

## Generate **root personal access tokens** 
> * User/Administrator/User seetings, generate the root personal access tokens and keep it.  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/root-settings.png?raw=true)  
>
> * Access Tokens / Name : **root-pat** / Scopes : Check all / Create personal access token  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/generate-root-persional-access-token.png?raw=true)
>
> * Keep Your New Personal Access Token 
>   ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/gitlab-rootpat.png?raw=true)  
>
> * Modify the **$gitlab_private_token** value in env.pl
>
>   ```~/deploy-devops/bin/generate_env.pl gitlab_private_token [Personal Access Token]```
>
>   It should display as below.
>   ```bash
>   localadmin@iiidevops-71:~$ ~/deploy-devops/bin/generate_env.pl gitlab_private_token 535wZnCJDTL5y22xYYzv
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

## Set up Rancher pipeline and Gitlab hook
> * Choose Global/ Cluster(**iiidevops-k8s**)/ Project(Default)  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-choose-cluster-project.png?raw=true)  
> * Choose Tools/Pipline, select **Gitlab**  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-setting-hook.png?raw=true)  
> Get the "Redirect URI" and then open GitLab web UI
>

> Use root account/ settings/ Applications
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/gitlab-root-setting.png?raw=true)  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/gitlab-usersetting-application.png?raw=true)  
> Setting Applications  
> insert Name : **iiidevops-k8s**, Redirect URI: [from Rancher] and chose all optional, and save application.
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/gitlab-setting-application.png?raw=true)  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/gitlab-application-info.png?raw=true)  
> Take the "Application ID" and "Secret", go to rancher pipeline, insert application id, secret and private gitlab url. Exp. **10.20.0.71:32080** 
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-setting-applicationsecret.png?raw=true)  
> Authorize  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/gitlab-authorize.png?raw=true)  
> Done  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-hook-down.png?raw=true)  
>
> Switch back to GitLab web UI


## Enable Outbound requests from web hooks
> * Admin Area/Settings/Network/Outbound reuests, enable **allow request to the local network from web hooks and service** / Save changes
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/allow-request-to-the-local-netowrk.png?raw=true)  
>

# Step 7. Check Harbor Project(Option)

> * Harbor - https://10.20.0.71:32443/
> * **Log in with the account admin and password ($harbour_admin_password) you entered in step 2.(~/deploy-devops/env.pl)**
> 
> * Check Project - dockerhub (Access Level : **Public** , Type : **Proxy Cache**) was added.
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/harbor_dockerhub_project.png?raw=true)  
> * If the project dockerhub is not created, you can exectue the command to manually create it.   
> 
>   ```sudo ~/deploy-devops/harbor/create_harbor.pl create_dockerhub_proxy```
>

# Step 8. Deploy III DevOps

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
> The deployment of III DevOps services has been completed. Please try to connect to the following URL.
> III DevOps URL - http://10.20.0.71:30775
>
> ```

## Go to Web UI to login 
> * III DevOps URL -  http://10.20.0.71:30775/
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/devops-ui.png?raw=true)  
>
> Use the **$admin_init_login** and **$admin_init_password** entered in Step 2.(~/deploy-devops/env.pl) to login to III DevOps

# Step 9. Scale-out K8s Node

> * Execute the following command on VM1 to make VM2, VM3.... join the K8s cluster.
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
>   -----
>   NAME           STATUS   ROLES                      AGE   VERSION
>   iiidevops-71   Ready    controlplane,etcd,worker   23h   v1.18.12
>   ```
>   * After executing this command, it will take about 3 to 5 minutes for the node to join the cluster.

