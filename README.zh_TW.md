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
> wget https://raw.githubusercontent.com/iii-org/deploy-devops/old_v1/bin/iiidevops_install.pl;
> perl ./iiidevops_install.pl local old_v1
> ```
> * 如果一切安裝順利, 你應該可以看到如同以下對各項檢查都 OK 的訊息
> 
> ```
> localadmin@iiidevops-71:~$ perl ./iiidevops_install.pl local old_v1
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
>   * Cluster Name: 輸入 **iiidevops-k8s**
>   * Kubernetes Version: 選擇最新版的 kubernetes 例如. **v.118.15-rancher1-1**
>   * Network provider: 選擇 **Calico**
>   * CNI Plugin MTU Override: 輸入 **1440**
>   ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-add-cluster.png?raw=true)  
>   * 點下 Next 去儲存設定 (這步驟會需要等一些時間才會完成, 如果過程中看到 "Failed while: Wait for Condition: InitialRolesPopulated: True" 這樣的訊息, 可直接點 'Next' 繼續處理.)
>   * Node Options: 勾選 **etcd**, **Control plane**, **worker**
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-cluster-node-option.png?raw=true)  

## 將這命令字串複製到 add-k8s.sh 後執行加入 K8s cluster
> * 將這命令字串複製到 /iiidevopsNFS/deploy-config/add_k8s.sh 
>
>   ```vi /iiidevopsNFS/deploy-config/add_k8s.sh```
>
> * 執行以下的命令來加入 K8s cluster.
>
>   ```sh /iiidevopsNFS/deploy-config/add_k8s.sh```
>
>   執行後, 你應該可以看到如同以下的訊息.
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
> * 執行這指令後, 會需要 5 到 10 分鐘讓這主機加入 K8s cluster.  
> * Rancher Web 介面將自動更新去使用新的 SSL 憑證. 你可能需要再次登入 Rancher. 等 iiidevops-k8s 這個 cluster 正確完成啟動, 就可以下載 **kubeconfig** 檔案.
>

## 取得 iiidevops-k8s 的 Kubeconfig 檔案
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-cluster-kubeconfig.png?raw=true)  
> 將 kubeconfig 檔內容儲存至 **/iiidevopsNFS/kube-config/config** 和 **~/.kube/config** 兩個檔案內.
> ```bash
>  touch /iiidevopsNFS/kube-config/config
>  ln -s /iiidevopsNFS/kube-config/config ~/.kube/config
>  vi /iiidevopsNFS/kube-config/config
> ```
> 然後你就可以輸入以下的命令來確認這 kubeconfig 是否可以正確操作 K8s.
>
> > ```kubectl cluster-info```
>
> 執行後, 你應該可以看到如同以下的訊息.
>
> ```bash
> localadmin@iiidevops-71:~$ kubectl cluster-info
> Kubernetes master is running at https://10.20.0.71:3443/k8s/clusters/c-fg42q
> CoreDNS is running at https://10.20.0.71:3443/k8s/clusters/c-fg42q/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
> 
> To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
> ```

# Step 5. 部署 GitLab, Redmine, Harbor, Sonarqube 到 kubernetes cluster 內

> ```~/deploy-devops/bin/iiidevops_install_cpnt.pl```
>
>
> 當完成部署後, 你應該可以看到如同以下的 URL 資訊.
>
> * GitLab - http://10.20.0.71:32080/
> * Redmine - http://10.20.0.71:32748/
> * Harbor - http://10.20.0.71:32443/
> * Sonarqube - http://10.20.0.71:31910/

# Step 6. 透過 GitLab 的管理網頁進行設定

> * GitLab - http://10.20.0.71:32080/
> * **使用 root 和 step 2.(~/deploy-devops/env.pl) 所設定的密碼進行登入**
>

## 產生 **root personal access tokens** 
> * 至 User/Administrator/User seetings, 產生 root personal access tokens 並將這個 token 複製出來.
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/root-settings.png?raw=true)  
>
> * Access Tokens / Name : 輸入 **root-pat** / Scopes : 選取全部 / Create personal access token
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/generate-root-persional-access-token.png?raw=true)
>
> * 複製這個新產生的 Personal Access Token 
>   ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/gitlab-rootpat.png?raw=true)  
>
> * 設定 env.pl 內的 **$gitlab_private_token** 
>
>   ```~/deploy-devops/bin/generate_env.pl gitlab_private_token [Personal Access Token]```
>
>   執行後, 你應該可以看到如同以下的訊息.
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

## 設定 Rancher 的 pipeline 與 Gitlab 進行連動
> * 回到 Rancher 管理網頁
> * 點選 Global/ Cluster(**iiidevops-k8s**)/ Project(Default)
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-choose-cluster-project.png?raw=true)  
> * 點選 Tools/Pipline, 選擇 **Gitlab**
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-setting-hook.png?raw=true)  
> * 複製 "Redirect URI"
> * 開啟 GitLab 管理網頁
>

> 點選 root account/ settings/ Applications
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/gitlab-root-setting.png?raw=true)  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/gitlab-usersetting-application.png?raw=true)  
> 設定 Applications
> Name: 輸入 **iiidevops-k8s**, Redirect URI: [貼上剛剛在 Rancher 上複製的值] 並且勾選所有的項目, 然後儲存這個 application.
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/gitlab-setting-application.png?raw=true)  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/gitlab-application-info.png?raw=true)  
> 取得這個 "Application ID" 和 "Secret"
> 開啟 Rancher 管理網頁, 點選 rancher pipeline, 貼上 application id 和 secret, 然後輸入 gitlab url. 例如 **10.20.0.71:32080**
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-setting-applicationsecret.png?raw=true)  
> 點選進行授權
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/gitlab-authorize.png?raw=true)  
> 點選 Done 完成設定
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-hook-down.png?raw=true)  
>
> 切回 GitLab 管理網頁


## 啟用 Outbound requests from web hooks
> * 至 Admin Area/Settings/Network/Outbound reuests, 勾選 **allow request to the local network from web hooks and service** / 儲存設定
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/allow-request-to-the-local-netowrk.png?raw=true)  
>

# Step 7. 檢查 Harbor Project 部署建立的專案

> * Harbor - https://10.20.0.71:32443/
> * **使用 admin 和 step 2.(~/deploy-devops/env.pl) 設定的密碼 ($harbour_admin_password) 進行登入 **
> 
> * 檢查專案 Project - dockerhub 是否已經自動建立(存取等級 : **Public** , 類型 : **Proxy Cache**).
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/harbor_dockerhub_project.png?raw=true)
> * 如果 project dockerhub 沒被自動建立, 你可以手動執行以下的命令來建立.
> 
>   ```sudo ~/deploy-devops/harbor/create_harbor.pl create_dockerhub_proxy```
>

# Step 8. 部署 III DevOps 系統

> ```~/deploy-devops/bin/iiidevops_install_core.pl```
>
> 你可能需要等 3 到 5 分鐘來完成部署與一些系統初始值的建立. 然後你應該可以看到如同以下的 URL 訊息.
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

## 透過網頁進行登入
> * III DevOps URL -  http://10.20.0.71:30775/
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/devops-ui.png?raw=true)  
>
> 使用 Step 2.(~/deploy-devops/env.pl) 所設定的 **$admin_init_login** 管理者帳號與 **$admin_init_password** 密碼進行系統登入

# Step 9. 橫向擴展 K8s 主機

> * 可以在 VM1 執行以下的命令來讓 VM2, VM3.... 加入 K8s cluster.
>
>   ```~/deploy-devops/bin/add-k8s-node.pl [user@vm2_ip]```
>
>   執行後, 你應該可以看到如同以下的訊息.
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
>   * 執行這命令可能需要 3 to 5 分鐘才可以讓該主機加入 K8s cluster.

# Step 10. 設定自動更新專案範本

> * III DevOps 維護熱門軟體開發使用框架與資料庫專案範本 - https://github.com/iiidevops-templates
> * 請先申請個人在 github 上的 Token (scopes 只需要 public_repo 即可) - https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token
>
> * 在 VM1 建立 cron.txt 內設定上班時間每 10 分鐘進行檢查同步範本
>
>   ```bash
>   localadmin@iiidevops-71:~$ vi cron.txt
>   ----
>   */10 7-20 * * * /home/localadmin/deploy-devops/bin/sync-prj-templ.pl my_github_id:3563cxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxf3ba4 >> /tmp/sync-prj-templ.log 2>&1
>   ----
>   localadmin@iiidevops-71:~$ crontab cron.txt
>   localadmin@iiidevops-71:~$ crontab -l
>   */10 7-20 * * * /home/localadmin/deploy-devops/bin/sync-prj-templ.pl my_github_id:3563cxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxf3ba4 >> /tmp/sync-prj-templ.log 2>&1
>   ```
> * 接下來就可以在 /tmp/sync-prj-templ.log 內看到同步紀錄, 類似如下的訊息
>
>   ```bash
>   localadmin@iiidevops-71:~$ tail /tmp/sync-prj-templ.log
>   ----
>   :
>   :
>   [18].   name:flask-postgres-todo (2021-03-11T08:18:11Z)
>           GitLab-> id:252 path:flask-postgres-todo created_at:2021-03-11T09:00:53.812Z
>   [19].   name:spring-maraidb-restapi (2021-03-11T08:13:26Z)
>           GitLab-> id:253 path:spring-maraidb-restapi created_at:2021-03-11T09:01:00.607Z
>   [20].   name:flask-webpage-with-men (2021-03-11T08:10:06Z)
>           GitLab-> id:254 path:flask-webpage-with-men created_at:2021-03-11T09:01:02.401Z
>   localadmin@iiidevops-71:~$
>   ```
