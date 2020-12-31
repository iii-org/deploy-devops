#!/usr/bin/perl
# Install Harbor service script
#
use FindBin qw($Bin);
my $p_config = "$Bin/../env.pl";
if (!-e $p_config) {
	print("The configuration file [$p_config] does not exist!\n");
	exit;
}
require($p_config);

$prgname = substr($0, rindex($0,"/")+1);
$logfile = "$Bin/$prgname.log";
log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);

$home_dir = "$data_dir/harbor";

log_print("Install Harbor URL: https://$harbor_ip\n");
$cmd_msg = `/usr/local/bin/docker-compose -v`;
if (index($cmd_msg, 'version')<0) {
	$os_m = `uname -m`;
	$os_m =~ s/\n|\r//;
	$cmd="sudo curl -L \"https://github.com/docker/compose/releases/download/1.27.4/docker-compose-Linux-$os_m\" -o /usr/local/bin/docker-compose; sudo chmod  +x /usr/local/bin/docker-compose";
	log_print("Install Docker Compose\n-----\n$cmd\n\n");
	$cmd_msg = `$cmd`;
	log_print("-----\n$cmd_msg\n\n");
	# Check docker-compose
	$cmd_msg = `/usr/local/bin/docker-compose -v`;
	if (index($cmd_msg, 'version')<0) {
		log_print("Instal docker-compose failed!\n$cmd_msg\n\n");
		exit;
	}
}
else {
	log_print("-----\n$cmd_msg\n\n");
}

# Check Harbor is working
$cmd_msg = `curl -k --location --request POST 'https://$harbor_ip:5443/api/v2.0/registries' 2>&1`;
#{"errors":[{"code":"UNAUTHORIZED","message":"UnAuthorized"}]}
$isWorking = index($cmd_msg, 'UNAUTHORIZED')<0?0:1;
if ($isWorking) {
	log_print("Harbor is running, I skip the installation!\n\n");
	exit;
}

$cmd_option = "wget -O $data_dir/harbor-offline-installer-v2.1.2.tgz  https://github.com/goharbor/harbor/releases/download/v2.1.2/harbor-offline-installer-v2.1.2.tgz;";
$chk_file = "$data_dir/harbor-offline-installer-v2.1.2.tgz";
$md5_value = substr(`md5sum $chk_file`, 0, 32); # 37a84e078504546c24e6fb99f80f6d05
if ($md5_value eq '37a84e078504546c24e6fb99f80f6d05') {
	$cmd_option = '';
}
$cmd = <<END;
sudo mkdir -p $home_dir;
$cmd_option
tar xvf $chk_file -C $data_dir;
END
log_print("Download and Unpack the Installer (V2.1)\n-----\n$cmd\n\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg\n\n");

# Generate a Certificate Authority Certificate
$certfile = "$home_dir/certs/$harbor_ip.cert";
$keyfile = "$home_dir/certs/$harbor_ip.key";
$cafile = "$home_dir/certs/ca.crt";
if (!-e $certfile || !-e $keyfile || !-e $cafile) {
	log_print("Generate a Certificate Authority Certificate...\n");
	$cmd_msg = gen_harbor_ca();
	log_print("-----\n$cmd_msg\n\n");
}
else {
	log_print("Use an existing Certificate Authority Certificate.\n");
}


$cmd =<<END;
sudo mkdir -p /etc/docker/certs.d/$harbor_ip:5443/;
sudo cp $home_dir/certs/$harbor_ip.cert /etc/docker/certs.d/$harbor_ip:5443/;
sudo cp $home_dir/certs/$harbor_ip.key /etc/docker/certs.d/$harbor_ip:5443/;
sudo cp $home_dir/certs/ca.crt /etc/docker/certs.d/$harbor_ip:5443/;
END

$harbor_yml =<<EOF;
hostname: $harbor_ip
http:
  port: 5080
https:
  port: 5443
  certificate: $home_dir/certs/$harbor_ip.crt
  private_key: $home_dir/certs/$harbor_ip.key
harbor_admin_password: $harbor_admin_password
database:
  password: $harbor_db_password
  max_idle_conns: 50
  max_open_conns: 1000
data_volume: $home_dir/data
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

open(FH, '>', "$home_dir/harbor.yml") or die $!;
print FH $harbor_yml;
close(FH);

log_print("Provide the Certificates to Harbor and Docker\n-----\n$cmd\n\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg\n\n");

$cmd="cd $home_dir; sudo ./install.sh";
log_print("Install Harbor\n-----\n$cmd\n\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg\n\n");

# Check Harbor service is working
$cmd = "curl -k --location --request POST 'https://$harbor_ip:5443/api/v2.0/registries'";
#{"errors":[{"code":"UNAUTHORIZED","message":"UnAuthorized"}]}
$chk_key = 'UNAUTHORIZED!';
$isChk=1;
$count=0;
$wait_sec=600;
while($isChk && $count<$wait_sec) {
	log_print('.');
	$cmd_msg = `$cmd 2>&1`;
	$isChk = (index($cmd_msg, $chk_key)<0)?1:0;
	$count ++;
	sleep($isChk);
}
log_print("-----\n$cmd_msg-----\n");
if ($isChk) {
	log_print("Failed to deploy Harbor!\n");
	log_print("-----\n$cmd_msg-----\n");
	exit;
}
log_print("Successfully deployed Harbor!\n");

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
WorkingDirectory=$home_dir
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



sub gen_harbor_ca {

$cmd = <<END;
mkdir -p $home_dir/certs;
cd $home_dir/certs;
openssl genrsa -out ca.key 4096;
openssl req -x509 -new -nodes -sha512 -days 3650  -subj "/C=TW/ST=Taipei/L=Taipei/O=iii/OU=dti/CN=$harbor_ip" -key ca.key  -out ca.crt;
openssl genrsa -out $harbor_ip.key 4096;
openssl req -sha512 -new -subj "/C=TW/ST=Taipei/L=Taipei/O=iii/OU=dti/CN=$harbor_ip" -key $harbor_ip.key -out $harbor_ip.csr;
END
	$cmd_msg = `$cmd`;

$harbor_ca = <<EOF;
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = IP:$harbor_ip
[alt_names]
DNS.1=$harbor_ip
DNS.2=$harbor_ip
DNS.3=iiidevops1
EOF

	$extfile = "$home_dir/certs/$harbor_ip.v3.ext";
print("[$extfile]\n");
	open(FH, '>', $extfile) or die $!;
	print FH $harbor_ca;
	close(FH);

$cmd = <<END;
cd $home_dir/certs;
openssl x509 -req -sha512 -days 3650 -extfile $harbor_ip.v3.ext -CA ca.crt -CAkey ca.key -CAcreateserial -in $harbor_ip.csr -out $harbor_ip.crt;
openssl x509 -inform PEM -in $harbor_ip.crt -out $harbor_ip.cert;
END
	$cmd_msg .= `$cmd`;
	
	return($cmd_msg);
}

sub log_print {
	my ($p_msg) = @_;

    print "$p_msg";
	
	open(FH, '>>', $logfile) or die $!;
	print FH $p_msg;
	close(FH);	

    return;
}
