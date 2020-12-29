#!/usr/bin/perl
use FindBin qw($Bin);

$prgname = substr($0, rindex($0,"/")+1);
$logfile = "$Bin/$prgname.log";
$home_dir = "$Bin/../../";
log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);

my $p_config = "$Bin/../env.pl";
if (-e $p_config) {
	require($p_config);
}
else {
	log_print("Cannot find configuration setting information file '$p_config'! \n");
	exit;
}

log_print("Install Harbor URL: https://$harbor_url\n");
$cmd_msg = `/usr/local/bin/docker-compose -v`;
if (index($cmd_msg, 'version')<0) {
	$os_m = `uname -m`;
	$os_m =~ s/\n|\r//;
	$cmd="sudo curl -L \"https://github.com/docker/compose/releases/download/1.27.4/docker-compose-Linux-$os_m\" -o /usr/local/bin/docker-compose; sudo chmod  +x /usr/local/bin/docker-compose";
	log_print("Install Docker Compose\n-----\n$cmd\n\n");
	$cmd_msg = `$cmd`;
	log_print("-----\n$cmd_msg\n\n");
}
else {
	log_print("-----\n$cmd_msg\n\n");
}

$cmd_option = "wget -O $home_dir/harbor-offline-installer-v2.1.2.tgz  https://github.com/goharbor/harbor/releases/download/v2.1.2/harbor-offline-installer-v2.1.2.tgz;";
$chk_file = "$home_dir/harbor-offline-installer-v2.1.2.tgz";
$md5_value = substr(`md5sum $chk_file`, 0, 32); # 37a84e078504546c24e6fb99f80f6d05
if ($md5_value eq '37a84e078504546c24e6fb99f80f6d05') {
	$cmd_option = '';
}
$cmd = <<END;
sudo mkdir -p /data/harbor;
$cmd_option
rm -rf $home_dir/harbor;
tar xvf $chk_file;
END
log_print("Download and Unpack the Installer (V2.1)\n-----\n$cmd\n\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg\n\n");

$cmd = <<END;
mkdir -p $home_dir/harbor/data/certs;
cd $home_dir/harbor/data/certs;
openssl genrsa -out ca.key 4096;
openssl req -x509 -new -nodes -sha512 -days 3650  -subj "/C=TW/ST=Taipei/L=Taipei/O=iii/OU=dti/CN=$harbor_url" -key ca.key  -out ca.crt;
openssl genrsa -out $harbor_url.key 4096;
openssl req -sha512 -new -subj "/C=TW/ST=Taipei/L=Taipei/O=iii/OU=dti/CN=$harbor_url" -key $harbor_url.key -out $harbor_url.csr;
END
log_print("Generate a Certificate Authority Certificate\n-----\n$cmd\n\n");
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
cd $home_dir/harbor/data/certs;
openssl x509 -req -sha512 -days 3650 -extfile $harbor_url.v3.ext -CA ca.crt -CAkey ca.key -CAcreateserial -in $harbor_url.csr -out $harbor_url.crt;
openssl x509 -inform PEM -in $harbor_url.crt -out $harbor_url.cert;
END
$cmd_msg .= `$cmd`;
log_print("-----\n$cmd_msg\n\n");

$cmd =<<END;
cd $home_dir/harbor/data/certs;
sudo mkdir -p /data/harbor/cert/;
sudo cp $harbor_url.crt /data/harbor/cert/;
sudo cp $harbor_url.key /data/harbor/cert/;
sudo mkdir -p /etc/docker/certs.d/$harbor_url:5443/;
sudo cp $harbor_url.cert /etc/docker/certs.d/$harbor_url:5443/;
sudo cp $harbor_url.key /etc/docker/certs.d/$harbor_url:5443/;
sudo cp ca.crt /etc/docker/certs.d/$harbor_url:5443/;
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

log_print("Provide the Certificates to Harbor and Docker\n-----\n$cmd\n\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg\n\n");

$cmd="cd $home_dir/harbor; sudo ./install.sh";
log_print("Install Harbor\n-----\n$cmd\n\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg\n\n");

# Create reboot auto start service
# Ref - https://stackoverflow.com/questions/43671482/how-to-run-docker-compose-up-d-at-system-start-up
$docker_compose_app_service =<<EOF;
[Unit]
Description=Docker Compose Application Service
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$Bin../../harbor
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target

EOF

open(FH, '>', "/etc/systemd/system/docker-compose-app.service") or die $!;
print FH $docker_compose_app_service;
close(FH);

$cmd = "sudo systemctl enable docker-compose-app";
log_print("Set the Harbor service to start automatically after the system boot..\n-----\n$cmd\n\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg\n\n");

exit;

sub log_print {
	my ($p_msg) = @_;

    print "$p_msg";
	
	open(FH, '>>', $logfile) or die $!;
	print FH $p_msg;
	close(FH);	

    return;
}
