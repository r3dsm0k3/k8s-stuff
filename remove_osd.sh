#!/bin/sh
if [ "$#" -ne 1 ]; then
    echo "You must enter the hostname to be deleted as an argument"
    return 0
fi
KUBECTL_BINARY="/var/lib/rcplatform/rc-manager/kubectl"
HOST=$1

OSD_POD=$($KUBECTL_BINARY get po -n rc-system -l "failure-domain=$HOST" -o jsonpath='{.items[0].metadata.name}')
OPERATOR_POD=$($KUBECTL_BINARY get po -n rc-system -l "app=rook-ceph-operator" -o jsonpath='{.items[0].metadata.name}')
ROOK_CONNECTION_ARGS="--connect-timeout=15 --cluster=rc-system --conf=/var/lib/rook/rc-system/rc-system.config --keyring=/var/lib/rook/rc-system/client.admin.keyring"
#get the osd
OSD_NUM=$($KUBECTL_BINARY exec -n rc-system $OPERATOR_POD -- ceph osd tree $ROOK_CONNECTION_ARGS --format json | jq -r --arg host $HOST '.nodes[] | select(.type == "host" and .name == $host) | .children[0]')
OSD="osd.$OSD_NUM"
#out osd
$KUBECTL_BINARY exec -n rc-system $OPERATOR_POD -- ceph osd out $OSD $ROOK_CONNECTION_ARGS
sleep 10
$KUBECTL_BINARY exec -n rc-system $OPERATOR_POD -- ceph osd crush remove $OSD $ROOK_CONNECTION_ARGS
sleep 10
$KUBECTL_BINARY exec -n rc-system $OPERATOR_POD -- ceph auth del $OSD $ROOK_CONNECTION_ARGS
sleep 20
echo "marking osd as down..."
$KUBECTL_BINARY exec -n rc-system $OPERATOR_POD -- ceph osd down $OSD $ROOK_CONNECTION_ARGS
echo "removing osd..."
sleep 60
$KUBECTL_BINARY exec -n rc-system $OPERATOR_POD -- ceph osd rm $OSD $ROOK_CONNECTION_ARGS
sleep 10
#remove the config map
echo "removing configmap..."
$KUBECTL_BINARY delete cm rook-ceph-osd-$HOST-config -n rc-system 
#remove the deployment
echo "removing deployment..."
$KUBECTL_BINARY delete deployment rook-ceph-osd-$OSD_NUM -n rc-system

echo "sleeping for a minute..."
sleep 60

echo "All done.It is safe to delete the nodes right now.\n"

echo "current status"

$KUBECTL_BINARY exec -n rc-system $OPERATOR_POD -- ceph osd status $ROOK_CONNECTION_ARGS
