#!/bin/sh

KCONFIG=$1

if [ -z $KCONFIG ]; then
  echo "Usage: $0 KUBECONFIG"
  exit 1
fi
if [ ! -f $KCONFIG ]; then
  echo "File $KCONFIG does not exist."
  exit 1
fi


KBASE=`basename $KCONFIG`

CLUSTERCERT=$KBASE"-cluster-cert.crt"
CLIENTCERT=$KBASE"-client-cert.crt"
CLIENTKEY=$KBASE"-client-key.key"

extract() {
  CONTEXT=`grep -A5 contexts $KCONFIG`

  USER=`grep -A2 users $KCONFIG`

  SERVERNAME=`echo "$CONTEXT" | grep cluster | awk '{print $2}'`
  USERNAME=`echo "$USER" | grep name | awk '{print $3}'`
}

print_data() {
  echo ""
  echo "$CONTEXT"
  echo "$USER"
echo "
creating:
 - a cluster named $SERVERNAME
 - a user named $USERNAME
 - a context named $USERNAME@$SERVERNAME

Please, check for conflicts in .kube/config before going on!
"
}

run_extract() {
  local SERVERNAME=$1
  local HOST=$2
  local USERNAME=$3
  kubectl config set-cluster $SERVERNAME --certificate-authority $CLUSTERCERT --server=$HOST
  kubectl config set-credentials $USERNAME --client-key $CLIENTKEY --client-certificate $CLIENTCERT
  kubectl config set-context $USERNAME@$SERVERNAME --cluster=$SERVERNAME --user=$USERNAME

  echo "Now run:
kuco_import.sh $KCONFIG $KCONFIG
"
}


if [ ! -d .kube ]; then
  echo "Directory .kube does not exist. Please create it first."
  exit 1
fi

if [ ! -w .kube ]; then
  echo "Directory .kube is not writable. Please check permissions."
  exit 1
fi
if ! command -v kubectl &> /dev/null; then
  echo "kubectl command not found. Please install kubectl first."
  exit 1
fi

extract
print_data
read -p "Enter host URL: " HOST
## Test if the user wants to exit
if [ -z "$HOST" ]; then
  echo "No host provided. Exiting."
  exit 1
fi
run_extract $SERVERNAME $HOST $USERNAME
