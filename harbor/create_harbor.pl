#!/usr/bin/perl
use FindBin qw($Bin);
my $p_config = "$Bin/../env.pl";
if (-e $p_config) {
	require($p_config);
}
else {
	print("Cannot find configuration setting information file '$p_config'! \n");
	exit;
}

print("Install Harbor URL: https://$harbor_url\n");
$os_m = `uname -m`;
$os_m =~ s/\n|\r//;
$cmd="sudo curl -L \"https://github.com/docker/compose/releases/download/1.27.4/docker-compose-Linux-$os_m\" -o /usr/local/bin/docker-compose; sudo chmod  +x /usr/local/bin/docker-compose";
print("Install Docker Compose\n-----\n$cmd\n\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n\n");

$cmd = <<END;
cd ~; sudo mkdir -p /data/harbor \
wget -O harbor-offline-installer-v2.1.0.tgz https://github.com/goharbor/harbor/releases/download/v2.1.0/harbor-offline-installer-v2.1.0.tgz \
tar xvf harbor-offline-installer-v2.1.0.tgz
END
print("Download and Unpack the Installer (V2.1)\n-----\n$cmd\n\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n\n");

$cmd = <<END;
mkdir -p ~/harbor/data/certs \
cd ~/harbor/data/certs \
openssl genrsa -out ca.key 4096 \
openssl req -x509 -new -nodes -sha512 -days 3650  -subj "/C=TW/ST=Taipei/L=Taipei/O=iii/OU=dti/CN=$harbor_url" -key ca.key  -out ca.crt \
openssl genrsa -out $harbor_url.key 4096 \
openssl req -sha512 -new -subj "/C=TW/ST=Taipei/L=Taipei/O=iii/OU=dti/CN=$harbor_url" -key $harbor_url.key -out $harbor_url.csr
END
print("Generate a Certificate Authority Certificate\n-----\n$cmd\n\n");
$cmd_msg = `$cmd`;

$harbor_ca = <<EOF;
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = IP:$harbor_url
[alt_names]
DNS.1=$harbor_url
DNS.2=$harbor_url
DNS.3=iiidevops1
EOF

open(FH, '>', "$Bin/../../harbor/data/certs/$harbor_url.v3.ext") or die $!;
print FH $harbor_ca;
close(FH);

$cmd = <<END;
cd ~/harbor/data/certs
openssl x509 -req -sha512 -days 3650 -extfile $harbor_url.v3.ext -CA ca.crt -CAkey ca.key -CAcreateserial -in $harbor_url.csr -out $harbor_url.crt
openssl x509 -inform PEM -in $harbor_url.crt -out $harbor_url.cert
END
$cmd_msg .= `$cmd`;
print("-----\n$cmd_msg\n\n");

$cmd =<<END;
cd ~/harbor/data/certs
sudo mkdir -p /data/harbor/cert/
sudo cp $harbor_url.crt /data/harbor/cert/
sudo cp $harbor_url.key /data/harbor/cert/
sudo mkdir -p /etc/docker/certs.d/$harbor_url:5443/
sudo cp $harbor_url.cert /etc/docker/certs.d/$harbor_url:5443/
sudo cp $harbor_url.key /etc/docker/certs.d/$harbor_url:5443/
sudo cp ca.crt /etc/docker/certs.d/$harbor_url:5443/
END

$harbor_yml =<<EOF;
hostname: $harbor_url
http:
  port: 5080
https:
  port: 5443
  certificate: /data/harbor/cert/$harbor_url.crt
  private_key: /data/harbor/cert/$harbor_url.key
harbor_admin_password: $harbor_admin_password
database:
  password: $harbor_db_password
  max_idle_conns: 50
  max_open_conns: 1000
data_volume: /data
clair:
  updaters_interval: 12
trivy:
  ignore_unfixed: false
  skip_update: false
  insecure: false
jobservice:
  max_job_workers: 10
notification:
  webhook_job_max_retry: 10
chart:
  absolute_url: disabled
log:
  level: info
  local:
    rotate_count: 50
    rotate_size: 200M
    location: /var/log/harbor
_version: 2.0.0
proxy:
  http_proxy:
  https_proxy:
  no_proxy:
  components:
    - core
    - jobservice
    - clair
    - trivy
EOF

open(FH, '>', "$Bin/../../harbor/harbor.yml") or die $!;
print FH $harbor_yml;
close(FH);

print("Provide the Certificates to Harbor and Docker\n-----\n$cmd\n\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n\n");

$cmd="cd ~/harbor; sudo ./install.sh";
print("Install Harbor\n-----\n$cmd\n\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n\n");
