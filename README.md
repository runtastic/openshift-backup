# Openshift-backup

Openshift resource state backup to git

### Git structure

```
_global_ - global resources such as Node, ClusterRole, StorageClass
_grafana_ - grafana configs (when grafana enabled)
<namespace> - such as kube-system, default, etc...
 |_ <ResourceType> - folder for each resource type
    |_ <resource-name.yaml> - file for each resource
```

### Build Image

**Create a new project in OpenShift**

`$ oc new-project openshift-backup`

**Start a new build in OpenShift using this repo as source**

`$ oc new-build git@github.com:runtastic/openshift-backup.git`

### Deployment

Yaml manifests are in [deploy folder](./deploy).

#### Create Deployment Key

Github and gitlab support adding key only for one repository

* Create repo
* Generate ssh key `ssh-keygen -f ./new_key`
* Add new ssh key to repo with write access
* Save key to [1_config_map.yaml](./deploy/1_config_map.yaml) (see comments in file)

#### Testing Deployment

I recommend to run it periodically with kubernetes' CronJob resource, if you want to test how it works without waiting then can change running schedule or create pod with same parameters

### Commands

* `openshift_backup backup` - pull remote git repository, save kubernetes state, make git commit in local repository
* `openshift_backup push` - push changes to remote repository
* `openshift_backup help` - shows help

Docker image by default runs `openshift_backup backup && openshift_backup push`

### Allow container to run without random UUID (as root)

`$ oc edit scc anyuid`

And add the service-account you created using [0_service_account.yaml](./deploy/0_service_account.yaml)
to the list of allowed users

```yaml
kind: SecurityContextConstraints
metadata:
  annotations:
    kubernetes.io/description: anyuid provides all features of the restricted SCC
      but allows users to run with any UID and any GID.
  name: anyuid
priority: 10
readOnlyRootFilesystem: false
requiredDropCapabilities:
- MKNOD
runAsUser:
  type: RunAsAny
seLinuxContext:
  type: MustRunAs
supplementalGroups:
  type: RunAsAny
users:
- system:serviceaccount:openshift-backup:openshift-backup
```

### Config

* `GIT_REPO_URL` - remote git URL like `git@github.com:kuberhost/kube-backup.git` (required)
* `BACKUP_VERBOSE` use 1 to enable verbose logging
* `TARGET_PATH` - local git repository folder, default `./openshift_state`
* `SKIP_NAMESPACES` - namespaces to exclude, separated by coma (,)
* `ONLY_NAMESPACES` - whitelist namespaces
* `GLOBAL_RESOURCES` - override global resources list, default is `node, apiservice, clusterrole, clusterrolebinding, podsecuritypolicy, storageclass, persistentvolume, customresourcedefinition, mutatingwebhookconfiguration, validatingwebhookconfiguration, priorityclass`
* `EXTRA_GLOBAL_RESOURCES` - use it to add resources to `GLOBAL_RESOURCES` list
* `SKIP_GLOBAL_RESOURCES` - blacklist global resources
* `RESOURCES` - default list of namespaces resources, see `OpenshiftBackup::TYPES`
* `EXTRA_RESOURCES` - use it to add resources to `RESOURCES` list
* `SKIP_RESOURCES` - exclude resources
* `SKIP_OBJECTS` - use it to skip individual objects, such as `kube-backup/ConfigMap/kube-backup-ssh-config` (separated by coma, spaces around coma ignored)
* `GIT_USER` - default is `kube-backup`
* `GIT_EMAIL` - default is `kube-backup@$(HOSTNAME)`
* `GIT_BRANCH` - Git branch, default is `master`
* `GIT_PREFIX` - Path to the subdirectory in your repository
* `GRAFANA_URL` - grafana api URL, e.g. `https://grafana.my-cluster.com`
* `GRAFANA_TOKEN` - grafana API token, create at https://your-grafana/org/apikeys
* `TZ` - timezone of commit times. e.g. `:Europe/Berlin`

### Security

To avoid man in a middle attack it's recommended to provide `known_hosts` file. Default `known_hosts` contain keys for github.com, gitlab.com and bitbucket.org

#### Custom Resources

Let's say we have a cluster with prometheus and certmanager, they register custom resources and we want to add them in backup.

Get list of custom resource definitions:
```
$ kubectl get crd

NAME                                    CREATED AT
alertmanagers.monitoring.coreos.com     2018-06-27T10:33:00Z
certificates.certmanager.k8s.io         2018-06-27T09:39:43Z
clusterissuers.certmanager.k8s.io       2018-06-27T09:39:43Z
issuers.certmanager.k8s.io              2018-06-27T09:39:44Z
prometheuses.monitoring.coreos.com      2018-06-27T10:33:00Z
prometheusrules.monitoring.coreos.com   2018-06-27T10:33:00Z
servicemonitors.monitoring.coreos.com   2018-06-27T10:33:00Z
```

Or get more useful output:
```
$ kubectl get crd -o json | jq -r '.items | (.[] | [.spec.names.singular, .spec.group, .spec.scope]) | @tsv'
alertmanager    monitoring.coreos.com  Namespaced
certificate     certmanager.k8s.io     Namespaced
clusterissuer   certmanager.k8s.io     Cluster
issuer          certmanager.k8s.io     Namespaced
prometheus      monitoring.coreos.com  Namespaced
prometheusrule  monitoring.coreos.com  Namespaced
servicemonitor  monitoring.coreos.com  Namespaced
```

Set env variables in container spec:
```yaml
env:
  - name: EXTRA_GLOBAL_RESOURCES
    value: clusterissuer
  - name: EXTRA_RESOURCES
    value: alertmanager, prometheus, prometheusrule, servicemonitor, certificate, issuer
```

---

Special thanks to Pieter Lange for [original idea](https://github.com/pieterlange/kube-backup/)
