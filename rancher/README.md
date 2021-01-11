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
> Name: `harbor-63` 會改用 `harbor-local` 
![11_add_harbor-63](img/11_add_harbor-63.png)

# Pipeline 變數取代參考 
參考來源: [rancher pipeline](https://rancher.com/docs/rancher/v2.x/en/pipelines/config/)
| VARIABLE NAME  | DESCRIPTION  | 
|---|---|
| CICD_GIT_REPO_NAME  | Repository name (Github organization omitted).  |
| CICD_GIT_URL  | URL of the Git repository.  |
| CICD_GIT_COMMIT  | Git commit ID being executed.  |   
| CICD_GIT_BRANCH  | Git branch of this event.  |
| CICD_GIT_REF  | Git reference specification of this event.  |
| CICD_GIT_TAG  | Git tag name, set on tag event.  |
| CICD_EVENT  | Event that triggered the build (push, pull_request or tag).  |
| CICD_PIPELINE_ID  | Rancher ID for the pipeline.  |
| CICD_EXECUTION_SEQUENCE  | Build number of the pipeline.  |	
| CICD_EXECUTION_ID  | Combination of {CICD_PIPELINE_ID}-{CICD_EXECUTION_SEQUENCE}.  |
| CICD_REGISTRY  | Address for the Docker registry for the previous publish image step, available in the Kubernetes manifest file of a Deploy YAML step.  |
| CICD_IMAGE  | Name of the image built from the previous publish image step, available in the Kubernetes manifest file of a Deploy YAML step. It does not contain the image tag.  |	

	
	
	
	
	
	
	
	
	
	
	