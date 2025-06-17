#!/bin/bash

print_usage () {
  echo "kuco_import.sh FILENAME SERV"
  echo "
Extract certificates and key form FILENAME
and store those on .kube/SERV(-cluster-cert.crt|-user-cert.crt|-user-key.key)
files.
Those filenames should be used in .kube/config as value for:
clusters:
 - cluster:
    certificate-authority
users:
 - user:
    client-certificate
    client-key
"
}

if [ -z $1 ] || [ -z $2 ]; then
  print_usage
  exit 1
fi

FILENAME=$1
SERV=$2

TEMPDIR=$(mktemp -d)

extract_json_to_ku () {
  local JSON=$1
  local TARGET=$2
  local BASEF=$SERV-$TARGET
  kubectl config --kubeconfig=$FILENAME view -o jsonpath=$JSON --raw > $TEMPDIR/$BASEF.b64
  base64 -d -i $TEMPDIR/$BASEF.b64 -o .kube/$BASEF
}

extract_json_to_ku "{.clusters[0].cluster.certificate-authority-data}" "cluster-cert.crt"
extract_json_to_ku "{.users[0].user.client-certificate-data}" "client-cert.crt"
extract_json_to_ku "{.users[0].user.client-key-data}" "client-key.key"

rm -rf "$TEMPDIR"
