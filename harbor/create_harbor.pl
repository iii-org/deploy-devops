#!/usr/bin/perl
use Socket;
use Sys::Hostname;

my $p_config = '../env.pl';
if (-e $p_config) {
	require($p_config);
}

if (!defined($harbor_url) || $harbor_url eq '') {
	my $host = hostname();
	$harbor_url = inet_ntoa(scalar gethostbyname($host || 'localhost'));
}

print("Install Harbor URL: https://$harbor_url\n");
$os_m = `uname -m`;
$os_m =~ s/\n|\r//;
$cmd="sudo curl -L \"https://github.com/docker/compose/releases/download/1.27.4/docker-compose-Linux-$os_m\" -o /usr/local/bin/docker-compose; sudo chmod  +x /usr/local/bin/docker-compose";
print("Install Docker Compose\n-----\n$cmd\n\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n\n");

$cmd="cd ~; sudo mkdir -p /data/harbor";
$cmd.="; wget https://github.com/goharbor/harbor/releases/download/v2.1.0/harbor-offline-installer-v2.1.0.tgz";
$cmd.="; tar xvf harbor-offline-installer-v2.1.0.tgz";
print("Download and Unpack the Installer (V2.1)\n-----\n$cmd\n\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n\n");

$cmd="mkdir -p ~/harbor/data/certs";
$cmd.="; cd ~/harbor/data/certs";
$cmd.="; openssl genrsa -out ca.key 4096";
$cmd.="; openssl req -x509 -new -nodes -sha512 -days 3650  -subj \"/C=TW/ST=Taipei/L=Taipei/O=iii/OU=dti/CN=$harbor_url\" -key ca.key  -out ca.crt";
$cmd.="; openssl genrsa -out $harbor_url.key 4096";
$cmd.="; openssl req -sha512 -new -subj \"/C=TW/ST=Taipei/L=Taipei/O=iii/OU=dti/CN=$harbor_url\" -key $harbor_url.key -out $harbor_url.csr";
$cmd.="; cat > $harbor_url.v3.ext <<-EOF \n";
$cmd.="authorityKeyIdentifier=keyid,issuer\n";
$cmd.="basicConstraints=CA:FALSE\n";
$cmd.="keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment\n";
$cmd.="extendedKeyUsage = serverAuth\n";
$cmd.="subjectAltName = IP:$harbor_url\n";
$cmd.="[alt_names]\n";
$cmd.="DNS.1=$harbor_url\n";
$cmd.="DNS.2=$harbor_url\n";
$cmd.="DNS.3=iiidevops1\n";
$cmd.="EOF\n";
print("Generate a Certificate Authority Certificate\n-----\n$cmd\n\n");
$cmd_msg = `$cmd`;
$cmd="cd ~/harbor/data/certs";
$cmd.="; openssl x509 -req -sha512 -days 3650 -extfile $harbor_url.v3.ext -CA ca.crt -CAkey ca.key -CAcreateserial -in $harbor_url.csr -out $harbor_url.crt";
$cmd.="; openssl x509 -inform PEM -in $harbor_url.crt -out $harbor_url.cert";
$cmd_msg .= `$cmd`;
print("-----\n$cmd_msg\n\n");

$cmd="cd ~/harbor/data/certs";
$cmd.="; sudo mkdir -p /data/harbor/cert/";
$cmd.="; sudo cp $harbor_url.crt /data/harbor/cert/";
$cmd.="; sudo cp $harbor_url.key /data/harbor/cert/";
$cmd.="; sudo mkdir -p /etc/docker/certs.d/$harbor_url:5443/";
$cmd.="; sudo cp $harbor_url.cert /etc/docker/certs.d/$harbor_url:5443/";
$cmd.="; sudo cp $harbor_url.key /etc/docker/certs.d/$harbor_url:5443/";
$cmd.="; sudo cp ca.crt /etc/docker/certs.d/$harbor_url:5443/";
$cmd.="; cd ~/harbor; cat > harbor.yml <<-EOF \n";
$cmd.="hostname: $harbor_url\n";
$cmd.="http:\n";
$cmd.="  port: 5080\n";
$cmd.="https:\n";
$cmd.="  port: 5443\n";
$cmd.="  certificate: /data/harbor/cert/$harbor_url.crt\n";
$cmd.="  private_key: /data/harbor/cert/$harbor_url.key\n";
$cmd.="harbor_admin_password: Harbor12345\n";
$cmd.="database:\n";
$cmd.="  password: root123\n";
$cmd.="  max_idle_conns: 50\n";
$cmd.="  max_open_conns: 1000\n";
$cmd.="data_volume: /data\n";
$cmd.="clair:\n";
$cmd.="  updaters_interval: 12\n";
$cmd.="trivy:\n";
$cmd.="  ignore_unfixed: false\n";
$cmd.="  skip_update: false\n";
$cmd.="  insecure: false\n";
$cmd.="jobservice:\n";
$cmd.="  max_job_workers: 10\n";
$cmd.="notification:\n";
$cmd.="  webhook_job_max_retry: 10\n";
$cmd.="chart:\n";
$cmd.="  absolute_url: disabled\n";
$cmd.="log:\n";
$cmd.="  level: info\n";
$cmd.="  local:\n";
$cmd.="    rotate_count: 50\n";
$cmd.="    rotate_size: 200M\n";
$cmd.="    location: /var/log/harbor\n";
$cmd.="_version: 2.0.0\n";
$cmd.="proxy:\n";
$cmd.="  http_proxy:\n";
$cmd.="  https_proxy:\n";
$cmd.="  no_proxy:\n";
$cmd.="  components:\n";
$cmd.="    - core\n";
$cmd.="    - jobservice\n";
$cmd.="    - clair\n";
$cmd.="    - trivy\n\n";
$cmd.="EOF\n";
print("Provide the Certificates to Harbor and Docker\n-----\n$cmd\n\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n\n");

$cmd="cd ~/harbor; sudo ./install.sh";
print("Install Harbor\n-----\n$cmd\n\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n\n");
