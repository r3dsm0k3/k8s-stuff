# k8s-troubleshooting and some utility scripts

**kubelet.sh**

_K8s orphan pod issue_

Potential fix for https://github.com/kubernetes/kubernetes/issues/60987

_How to run_

```sh
bash kubelet.sh
```
> please note `sh kubelet.sh` wont work, this needs bash. You can also do `./kubelet.sh` but just not sh.


**remove_osd.sh**

_Remove OSD from ceph cluster_

This is a small shell script which may be executed by the cluster administrator before they remove a node from the cluster.
This ensure the osds are removed from the node, data is replicated to other nodes.

### Assumptions
* kubectl is at `/var/lib/rcplatform/rc-manager/kubectl`
* kubernetes cluster is reachable.

# How to run
`remove_osd.sh $HOSTNAME_TO_BE_REMOVED`


### considerations
*ps: It is hacky, and depends on the timings which is not ideal. As a todo, should watch the state of cephcluster before purging the osd.*


**k3s.sh**
Small script to boot a multi node k3s cluster on multipass
