# Harbor + private CA Usage:

## Harbor Environment
* URL - https://10.20.0.71:5443/
* User ID: jonathan (created by iiidevops administrator)
* Project ID: modbus-tcp (created by iiidevops project manager)

## Local Settings (Linux)
* Install docker service

  Ref - https://hub.docker.com/search?q=&type=edition&offering=community&operating_system=linux
* Check docker version
  ```bash
  docker -v
  ```

  ```bash
  localadmin@iiidevops-74:~$ docker -v
  Docker version 20.10.1, build 831ebea
  ```

* Trust Harbor Server IP
  ```bash
  sudo vi /etc/docker/daemon.json
  ```
  
  ```
  {
      "insecure-registries":["10.20.0.71:5443"]
  }
  ```
  
* Restart docker service
  ```bash 
  sudo systemctl restart docker.service
  ```
  
* Login harbor
  ```bash 
  sudo docker login https://10.20.0.71:5443/
  ```
 
  ```
  localadmin@iiidevops-74:~$ sudo docker login https://10.20.0.71:5443/
  Username: jonathan
  Password:
  WARNING! Your password will be stored unencrypted in /root/.docker/config.json.
  Configure a credential helper to remove this warning. See
  https://docs.docker.com/engine/reference/commandline/login/#credentials-store
 
  Login Succeeded
  ```

## Local Settings (Windows)
* Install docker service

  Ref - https://hub.docker.com/editions/community/docker-ce-desktop-windows
* Check docker version
  ```dos
  docker -v
  ```

  ```dos
  C:\Users\jonathan>docker -v
  Docker version 20.10.0, build 7287ab3
  ```

* Trust Harbor Server IP & Restart docker service
![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/docker_windows_setting.png?raw=true)  
  
* Login harbor
  ```dos
  docker login https://10.20.0.71:5443/
  ```
 
  ```
  C:\Users\jonathan>docker login https://10.20.0.71:5443/
  Username: jonathan
  Password:
  Login Succeeded
  ```
