**How to manually fix ceph disk**

first get the pvc in the deployment.

```
root@mycluster-k8sm-0:/home/rcplatform# k get pvc -n naix
NAME                             STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS    AGE
data-naix-mariadb-0              Bound    pvc-e3bba299-6c85-4f7f-b8a7-b2df35cd9ddf   8Gi        RWO            rc-storage      21d
naix-soln-4867209-pvc            Bound    pvc-5129f8ff-2ed1-4990-9e29-9d33e2ec7dc8   200Gi      RWX            rc-fs-storage   21d
redis-data-naix-redis-master-0   Bound    pvc-2be63d58-7815-41c1-ad5f-789432f550a9   8Gi        RWO            rc-storage      21d
redis-data-naix-redis-slave-0    Bound    pvc-7689c925-f7e1-4d7a-abc2-3c77cd6f2eb8   8Gi        RWO            rc-storage      21d
redis-data-naix-redis-slave-1    Bound    pvc-7d31e9dd-b9e4-4641-89b3-a9ffb167f651   8Gi        RWO            rc-storage      21d
```

lets check where the `data-naix-mariadb-0 ` is mounted on. 
```
root@mycluster-k8sm-0:/home/rcplatform# k get volumeattachments -o wide | grep pvc-e3bba299-6c85-4f7f-b8a7-b2df35cd9ddf
csi-e674804db1948b72d1511a8867e1b9d19455010c108fa89e8cce4fcc51d10624   rc-system.rbd.csi.ceph.com      pvc-e3bba299-6c85-4f7f-b8a7-b2df35cd9ddf   mycluster-k8sw-15   true       21d
```
as you can see from here, ceph csi stores the data in the node `mycluster-k8sw-15` 

login to the node and check the block device information.

```
rcplatform@mycluster-k8sw-15:~$ lsblk
NAME    MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda       8:0    0   512G  0 disk
├─sda1    8:1    0 511.9G  0 part /
├─sda14   8:14   0     4M  0 part
└─sda15   8:15   0   106M  0 part /boot/efi
sdb       8:16   0    32G  0 disk
└─sdb1    8:17   0    32G  0 part /mnt
rbd0    252:0    0     8G  0 disk /var/lib/kubelet/pods/94528e4b-2a2a-4e1d-a8ca-5b37de1cae3a/volumes/kubernetes.io~csi/pvc-e3bba299-6c85-4f7f-b8a7-b2df35cd9ddf/mount
```

as you can see, the device `rbd0` is mapped to the directory `/var/lib/kubelet/pods/xxxx/...`. older versions (<1.3) of ceph carves out a portion of the volume from the disk to be used as the data volume
```
root@mycluster-k8sw-15:/var/lib/kubelet/pods/94528e4b-2a2a-4e1d-a8ca-5b37de1cae3a/volumes/kubernetes.io~csi/pvc-e3bba299-6c85-4f7f-b8a7-b2df35cd9ddf/mount# ll
total 28
drwxrwsrwx 4 root 1001  4096 Mar 26 10:33 ./
drwxr-x--- 3 root root  4096 Mar 26 11:53 ../
drwxrwsr-x 6 1001 1001  4096 Apr 16 12:42 data/
drwxrws--- 2 root 1001 16384 Mar 26 10:33 lost+found/
```
if we were to do `fsck` on  the block device, we can at this point. _But make sure to unmount it_

`sudo fsck.ext4 /dev/rbd0` and it will be checked for integrity and fsck will fix any issues thereof.
