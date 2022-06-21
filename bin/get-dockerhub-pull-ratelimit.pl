#!/usr/bin/perl
# Get dockerhub pull ratelimit
#
use JSON::MaybeXS qw(encode_json decode_json);

$token_cmd = "curl -s \"https://auth.docker.io/token?service=registry.docker.io&scope=repository:ratelimitpreview/test:pull\"";
$token_cmd_msg = `$token_cmd`;
$token = decode_json($token_cmd_msg)->{'token'};
$pull_limit_cmd = "curl -s --head 'Content-Type: application/json' -H \"Authorization: Bearer $token\" https://registry-1.docker.io/v2/ratelimitpreview/test/manifests/latest | grep -e '200 OK' -e 'ratelimit'";
$pull_limit_msg = `$pull_limit_cmd`;
print("$pull_limit_msg");