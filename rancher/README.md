# How to enter page that manage secrets from rancher
![01_select_cluster](img/01_select_cluster.png)
![02_select_project](img/02_select_project.png)
![03_select_secrets](img/03_select_secrets.png)
# Add secrets for all namespace
![04_add_secrets](img/04_add_secrets.png)
## 接下來會需要此步驟(按鈕)來新增四個`Secret`
> Name: `api-origin`  
> Keys: `api-origin`、`password`、`username`  
![05_add_api_origin](img/05_add_api_origin.png)

> Name: `checkmarx-secret`  
> Keys: `check-interval`、`client-secret`、`cm-url`、`password`、`username`
![06_add_checkmarx_secret](img/06_add_checkmarx_secret.png)

> Name: `gitlab-token`  
> Keys: `git-token`
![07_add_gitlab_token](img/07_add_gitlab_token.png)

> Name: `jwt-token`  
> Keys: `jwt-token`
![08_add_jwt_token](img/08_add_jwt_token.png)

# Add Registry Credentials for all namespace
![09_select_registry_cre](img/09_select_registry_cre.png)
![10_add_registry](img/10_add_registry.png)
> Name: `harbor-63`
![11_add_harbor-63](img/11_add_harbor-63.png)
