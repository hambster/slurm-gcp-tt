# Slurm on Google Cloud Platform

The following describes setting up a Slurm cluster using [Google Cloud
Platform](https://cloud.google.com), bursting out from an on-premise cluster to
nodes in Google Cloud Platform and setting a multi-cluster/federated setup with
a cluster that resides in Google Cloud Platform.

Also, checkout the [Slurm on GCP code lab](https://codelabs.developers.google.com/codelabs/hpc-slurm-on-gcp/).

The supplied scripts can be modified to work with your environment.

SchedMD provides professional services to help you get up and running in the
cloud environment. [SchedMD Commercial Support](https://www.schedmd.com/support.php)

Issues and/or enhancement requests can be submitted to
[SchedMD's Bugzilla](https://bugs.schedmd.com).

Also, join comunity discussions on either the
[Slurm User mailing list](https://slurm.schedmd.com/mail.html) or the
[Google Cloud & Slurm Community Discussion Group](https://groups.google.com/forum/#!forum/google-cloud-slurm-discuss).


# Contents

* [Stand-alone Cluster in Google Cloud Platform](#stand-alone-cluster-in-google-cloud-platform)
  * [Install using Deployment Manager](#install-using-deployment-manager)
  * [Install using Terraform](#install-using-terraform)
  * [Image-based Scaling](#image-based-scaling)
  * [Installing Custom Packages](#installing-custom-packages)
  * [Accessing Compute Nodes](#accessing-compute-nodes)
  * [OS Login](#os-login)
  * [Preemptible VMs](#preemptible-vms)
* [Bursting out from on-premise cluster](#bursting-out-from-on-premise-cluster)
  * [Bursting out playground](#bursting-out-playground)
* [Multi-Cluster / Federation](#multi-cluster-federation)
  * [Playground](#playground)


## Stand-alone Cluster in Google Cloud Platform

The supplied scripts can be used to create a stand-alone cluster in Google Cloud
Platform. The scripts setup the following scenario:

* 1 - controller node
* N - login nodes
* Multiple partitions with their own machine type, gpu type/count, disk size,
  disk type, cpu platform, and maximum node count.


The default image for the instances is CentOS 7.

On the controller node, slurm is installed in:
/apps/slurm/<slurm_version>
with the symlink /apps/slurm/current pointing to /apps/slurm/<slurm_version>.

The login nodes mount /apps and /home from the controller node.


### Install using Deployment Manager

To deploy, you must have a GCP account and either have the
[GCP Cloud SDK](https://cloud.google.com/sdk/downloads)
installed on your computer or use the GCP
[Cloud Shell](https://cloud.google.com/shell/).

Steps:
1. Edit the `slurm-cluster.yaml` file and specify the required values

   For example:

    ```
    imports:
    - path: slurm.jinja
    
    resources:
    - name: slurm-cluster
      type: slurm.jinja
      properties:
        cluster_name            : g1
    
        zone                    : us-central1-b
        region                  : us-central1
        cidr                    : 10.10.0.0/16
    
      # Optional network configuration fields
      # READ slurm.jinja.schema for prerequisites
        # vpc_net                   : < my-vpc >
        # vpc_subnet                : < my-subnet >
        # shared_vpc_host_project    : < my-shared-vpc-project-name >
    
        controller_machine_type : n1-standard-2
        # controller_disk_type      : pd-standard
        # controller_disk_size_gb   : 50
        # controller_labels         :
        #   key1 : value1
        #   key2 : value2
        # controller_service_account: default
        # controller_scopes         :
        # - https://www.googleapis.com/auth/cloud-platform
        # cloudsql                  :
        #   server_ip: <cloudsql ip>
        #   user: slurm
        #   password: verysecure
        #   # Optional
        #   db_name: slurm_accounting
    
        login_machine_type        : n1-standard-2
        # login_disk_type           : pd-standard
        # login_disk_size_gb        : 10
        # login_labels              :
        #   key1 : value1
        #   key2 : value2
        # login_node_count          : 0
        # login_node_service_account: default
        # login_node_scopes         :
        #   - https://www.googleapis.com/auth/devstorage.read_only
        #   - https://www.googleapis.com/auth/logging.write
    
      # Optional network storage fields
      # network_storage is mounted on all instances
      # login_network_storage is mounted on controller and login instances
        # network_storage           :
        #   - server_ip: <storage host>
        #     remote_mount: /home
        #     local_mount: /home
        #     fs_type: nfs
        # login_network_storage     :
        #   - server_ip: <storage host>
        #     remote_mount: /net_storage
        #     local_mount: /shared
        #     fs_type: nfs
    
        compute_image_machine_type  : n1-standard-2
        # compute_image_disk_type   : pd-standard
        # compute_image_disk_size_gb: 10
        # compute_image_labels      :
        #   key1 : value1
        #   key2 : value2
    
      # Optional compute configuration fields
        # external_compute_ips      : False
        # private_google_access     : True
    
        # controller_secondary_disk         : True
        # controller_secondary_disk_type    : pd-standard
        # controller_secondary_disk_size_gb : 300
    
        # compute_node_service_account : default
        # compute_node_scopes          :
        #   -  https://www.googleapis.com/auth/devstorage.read_only
        #   -  https://www.googleapis.com/auth/logging.write
    
        # Optional timer fields
        # suspend_time              : 300
    
        # slurm_version             : 19.05-latest
        # ompi_version              : v3.1.x
    
        partitions :
          - name              : debug
            machine_type      : n1-standard-2
            static_node_count : 2
            max_node_count    : 10
            zone              : us-central1-a
        # Optional compute configuration fields
    
            # cpu_platform           : Intel Skylake
            # preemptible_bursting   : False
            # compute_disk_type      : pd-standard
            # compute_disk_size_gb   : 10
            # compute_labels         :
            #   key1 : value1
            #   key2 : value2
            # compute_image_family   : custom-image
        # Optional GPU configuration fields
    
            # gpu_type               : nvidia-tesla-v100
            # gpu_count              : 8
    
    
        # Additional partition
    
          # - name           : partition2
            # machine_type   : n1-standard-16
            # max_node_count : 20
            # zone           : us-central1-b
        # Optional compute configuration fields
    
            # cpu_platform           : Intel Skylake
            # preemptible_bursting   : False
            # compute_disk_type      : pd-standard
            # compute_disk_size_gb   : 10
            # compute_labels         :
            #   key1 : value1
            #   key2 : value2
            # compute_image_family   : custom-image
            # network_storage        :
            #   - server_ip: none
            #     remote_mount: <gcs bucket name>
            #     local_mount: /data
            #     fs_type: gcsfuse
            #     mount_options: file_mode=664,dir_mode=775,allow_other
            #
    
        # Optional GPU configuration fields
            # gpu_type               : nvidia-tesla-v100
            # gpu_count              : 8

   ```

   **NOTE:** For a complete list of available options and their definitions,
   check out the [schema file](slurm.jinja.schema).

2. Spin up the cluster.

   Assuming that you have gcloud configured for your account, you can just run:

   ```
   $ gcloud deployment-manager deployments [--project=<project id>] create slurm --config slurm-cluster.yaml
   ```

3. Check the cluster status.

   You can see that status of the deployment by viewing:
   https://console.cloud.google.com/deployments

   and viewing the new instances:
   https://console.cloud.google.com/compute/instances

   To verify the deployment, ssh to the login node and run `sinfo` to see how
   many nodes have registered and are in an idle state.

   A message will be broadcast to the terminal when the installation is
   complete. If you log in before the installation is complete, you will either
   need to re-log in after the installation is complete or start a new shell
   (e.g. /bin/bash) to get the correct bash profile.

   ```
   $ gcloud compute [--project=<project id>] ssh [--zone=<zone>] g1-login0
   ...
   [bob@g1-login0 ~]$ sinfo
   PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
   debug*       up   infinite      8  idle~ g1-compute-0-[1-9]
   debug*       up   infinite      2   idle g1-compute-0-[0-1]
   ```

   **NOTE:** By default, Slurm will hide nodes that are in a power_save state --
   "cloud" nodes. The GCP Slurm scripts configure **PrivateData=cloud** in the
   slurm.conf so that the "cloud" nodes are always shown. This is done so that
   nodes that get marked down can be easily seen.

4. Submit jobs on the cluster.

   ```
   [bob@g1-login0 ~]$ sbatch -N2 --wrap="srun hostname"
   Submitted batch job 2
   [bob@g1-login0 ~]$ cat slurm-2.out
   g1-compute-0-0
   g1-compute-0-1
   ```

5. Tearing down the deployment.

   ```
   $ gcloud deployment-manager [--project=<project id>] deployments delete slurm
   ```

   **NOTE:** If additional resources (instances, networks) are created other
   than the ones created from the default deployment then they will need to be
   destroyed before deployment can be removed.

### Install using Terraform

To deploy, you must have a GCP account and either have the
[GCP Cloud SDK](https://cloud.google.com/sdk/downloads) and
[Terraform](https://www.terraform.io/downloads.html)
installed on your computer or use the GCP
[Cloud Shell](https://cloud.google.com/shell/).

Steps:
1. cd to tf/examples/basic
2. Edit the `basic.tfvars` file and specify the required values
3. Deploy the cluster
   ```
   $ terraform init
   $ terraform apply -var-file=basic.tfvars
   ```
4. Tearing down the cluster

   ```
   $ terraform destroy -var-file=basic.tfvars
   ```

   **NOTE:** If additional resources (instances, networks) are created other
   than the ones created from the default deployment then they will need to be
   destroyed before deployment can be removed.

### Image-based Scaling
   The deployment will create a <cluster_name>-compute-\#-image instance, where
   \# is the index in the array of partitions, for each partition that is a base
   compute instance image. After installing necessary packages, the instance
   will be stopped and an image of the instance will be created. Subsequent
   bursted compute instances will use this image -- shortening the creation and
   boot time of new compute instances. While the compute image is running, the
   respective partitions will be marked as "down" to prevent jobs from
   launching until the image is created. After the image is created, the
   partition will be put into an "up" state and jobs can then run.

   **NOTE:** When creating a compute image that has gpus attached, the process
   can take about 10 minutes.

   If the compute image needs to be updated, it can be done with the following
   command:
   ```
   $ gcloud compute images create <cluster_name>-compute-#-image-$(date '+%Y-%m-%d-%H-%M-%S') \
                                  --source-disk <instance name> \
                                  --source-disk-zone <zone> --force \
                                  --family <cluster_name>-compute-#-image-family
   ```

   Existing images can be viewed on the console's [Images](https://console.cloud.google.com/compute/images)
   page.

### Installing Custom Packages
   There are two files: custom-controller-install, custom-compute-install in
   the scripts directory that can be used to add custom installations for the
   given instance type. The files will be executed during startup of the
   instance types.

### Accessing Compute Nodes

   There are multiple ways to connect to the compute nodes:
   1. If the compute nodes have external IPs you can connect directly to the
      compute nodes. From the [VM Instances](https://console.cloud.google.com/compute/instances)
      page, the SSH drop down next to the compute instances gives several
      options for connecting to the compute nodes.
   2. Whether the compute nodes have external IPs or not, they can be connected
      to from within the cluster. By default, the instances are setup with
      GCP's OSLogin.For information on managing access to instances see the
      [OSLogin documentation](https://cloud.google.com/compute/docs/instances/managing-instance-access).

      In general, you can click the "SSH" button next to the instance with an
      external IP on the [VM Instances](https://console.cloud.google.com/compute/instances)
      page. From this node you can ssh to compute nodes.

### OS Login

   By default, all instances are configured with
   [OS Login](https://cloud.google.com/compute/docs/oslogin).

   > OS Login lets you use Compute Engine IAM roles to manage SSH access to
   > Linux instances and is an alternative to manually managing instance access
   > by adding and removing SSH keys in metadata.
   > https://cloud.google.com/compute/docs/instances/managing-instance-access

   This allows user uid and gids to be consistent across all instances.

   When sharing a cluster with non-admin users, the following IAM rules are
   recommended:

   1. Create a group for all users in admin.google.com.
   2. At the project level in IAM, grant the **Compute Viewer** and **Service
      Account User** roles to the group.
   3. At the instance level for each login node, grant the **Compute OS Login**
      role to the group.
      1. Make sure the **Info Panel** is shown on the right.
      2. On the compute instances page, select the boxes to the left of the
         login nodes.
      3. Click **Add Members** and add the **Compute OS Login** role to the group.
   4. At the organization level, grant the **Compute OS Login External User**
      role to the group if the users are not part of the organization.
   5. To allow ssh to login nodes without external IPs, configure IAP for the
      group.
      1. Go to the [Identity-Aware Proxy page](https://console.cloud.google.com/security/iap?_ga=2.207343252.68494128.1583777071-470618229.1575301916)
      2. Select project
      3. Click **SSH AND TCP RESOURCES** tab
      4. Select boxes for login nodes
      5. Add group as a member with the **IAP-secured Tunnel User** role
      6. Reference: https://cloud.google.com/iap/docs/enabling-compute-howto

   This allows users to access the cluster only through the login nodes.

### Preemptible VMs
   With preemptible_bursting on, when a node is found preempted, or stopped,
   the slurmsync script will mark the node as "down" and will attempt to
   restart the node. If there were any batch jobs on the preempted node, they
   will be requeued -- interactive (e.g. srun, salloc) jobs can't be requeued.

## Bursting out from on-premise cluster

Bursting out from an on-premise cluster is done by configuring the
**ResumeProgram** and the **SuspendProgram** in the slurm.conf. The scripts
*resume.py*, *suspend.py* and *startup-script.py* in the scripts directory can
be modified and used to create new compute instances in a GCP project. See the
[Slurm Elastic Computing](https://slurm.schedmd.com/elastic_computing.html) for
more information.

Pre-reqs:
1. VPN between on-prem and GCP
2. bidirectional DNS between on-premise and GCP
3. Open ports to on-premise
   1. slurmctld
   2. slurmdbd
   3. SrunPortRange


Steps:
1. Create a base instance

   Create a bare image and install and configure the packages (including Slurm)
   that you are used to for a Slurm compute node. Then create an image
   from it creating a family either in the form
   "<cluster_name>-compute-#-image-family" or in a name of your choosing.


2. Create a service account that will have access to create and delete
   instances in the remote project.

3. Install scripts

   Install the *resume.py*, *suspend.py*, *slurmsync.py* and
   *config.yaml.example* from the slurm-gcp repository's scripts directory to a
   location on the slurmctld. Rename config.yaml.example to config.yaml and
   modify the approriate values.
   
   Add the compute_image_family to each partition if different than the naming
   schema, "<cluster_name>-compute-#-image-family".


4. Modify slurm.conf:

   ```
   PrivateData=cloud
   
   SuspendProgram=/path/to/suspend.py
   ResumeProgram=/path/to/resume.py
   ResumeFailProgram=/path/to/suspend.py
   SuspendTimeout=600
   ResumeTimeout=600
   ResumeRate=0
   SuspendRate=0
   SuspendTime=300
   
   # Tell Slurm to not power off nodes. By default, it will want to power
   # everything off. SuspendExcParts will probably be the easiest one to use.
   #SuspendExcNodes=
   #SuspendExcParts=
   
   SchedulerParameters=salloc_wait_nodes
   SlurmctldParameters=cloud_dns,idle_on_node_suspend
   CommunicationParameters=NoAddrCache
   LaunchParameters=enable_nss_slurm
   
   SrunPortRange=60001-63000
   ```

5. Add a cronjob/crontab to call slurmsync.py

   e.g.
   ```
   */1 * * * * /path/to/slurmsync.py
   ```

6. Test

   Try creating and deleting instances in GCP by calling the commands directly as SlurmUser.
   ```
   ./resume.py g1-compute-0-0
   ./suspend.py g1-compute-0-0
   ```

### Bursting out playground

You can use the deployment scripts to create a playground to test bursting from
an on-premise cluster by using two separate projects in GCP. This requires
setting up a gateway-to-gateway VPN in GCP between the two projects. The
following are the steps to do this.

1. Create two projects in GCP (e.g. project1, project2).
2. Create a slurm cluster in both projects using the deployments scripts.

   e.g.
   ```
   $ cat slurm-cluster.yaml
   resources:
   - name: slurm-cluster
     type: slurm.jinja
     properties:
       ...
       cluster_name            : g1
       ...
       cidr                    : 10.10.0.0/16
       ....

   $ gcloud deployment-manager --project=<project1> deployments create slurm --config slurm-cluster.yaml

   $ cat slurm-cluster.yaml
   resources:
   - name: slurm-cluster
     type: slurm.jinja
     properties:
       ...
       cluster_name            : g1
       ...
       cidr                    : 10.20.0.0/16
       ....

   $ gcloud deployment-manager --project=<project2> deployments create slurm --config slurm-cluster.yaml
   ```

   We use the deployment scripts to setup the network and compute image. Once
   project2 is up, all instances except the compute images in project2 should be
   deleted.

4. Setup a gateway-to-gateway VPN.

   For each project, from the GCP console, create a VPN by going to
   Hybrid Connectivity->VPN->Create VPN connection.

   Choose Classic VPN.

   Fill in the following fields:
   ```
   Gateway:
   Name       : slurm-vpn
   Network    : choose project's network
   Region     : choose same region as project2's
   IP Address : choose or create a static IP

   Tunnels:
   Name                     : slurm-vpn-tunnel
   Remote peer IP Address   : static IP of other project
   IKE version              : IKEv2
   Shared secret            : string used by both vpns
   Routing options          : Policy-based
   Remote network IP ranges : IP range of network of other project (Enter 10.20.0.0/16 for project1 and 10.10.0.0/16 for project2)
   Local subnetworks        : Choose networks for each project.
   Local IP ranges          : Should be filled in with the subnetwork's IP range.
   ```
   Then click Create.

   If all goes well then the VPNs should show a green check mark for the VPN
   tunnels.

6. Modify *config.yaml* in the
   /apps/slurm/scripts directory on project1's controller instance to
   communicate with project2 information.

   Modify the following fields with the appropriate values:
   e.g.
   ```
   project: slurm-184304
   region: us-west1
   zone: us-west1-b
   cluster_subnet: slurm-subnetwork2

   google_app_cred_path: /path/to/<file>.json
   ```

7. By default, project1 won't be able to resolve the instances in project2.
   here are two ways to work around this.

   **DNS Peering**

   DNS Peering can be set up so that project1 can resolve instances in
   project2 and vice versa.

   https://cloud.google.com/dns/zones/#peering-zones

   1. On project1's GCP Console, navigate to Network service->Cloud DNS
   2. Create zone
   3. Fill in the following fields:
   ```
   Zone type    : Private
   Zone name    : project1
   DNS Name     : <suffix on DNS zone in project2. e.g "c.<project2>.internal">
   Options      : DNS Peering
   Networks     : slurm-network
   Peer project : <project2>
   Peer network : slurm-network2
   ```
   4. Create

   Now from project1, you should be able to resolve hostnames in project2.

   e.g.
   ```
   [root@g1-controller ~]$ nslookup <instance>.c.<project2>.internal
   ```

   In order for Slurm to be able to reference the nodes by the short name, the
   DNS search path of project2 needs to be added to the controller and each
   login node's /etc/resolve.conf.

   e.g.
   ```
   /etc/resolve.conf
   # Generated by NetworkManager
   search c.<project1>.internal google.internal
   search c.<project2>.internal google.internal
   nameserver 169.254.169.254
   ```

   The same steps can be followed to create a peering zone from project2 to
   project1. This avoids the need to add the controller to /etc/hosts.

   **NodeAddrs**

   Without hostname resolution, Slurm needs the IP address' of the compute
   nodes to communicate with them. The following configuration changes need to
   be done for this setup:

   1. cloud_dns needs to be removed from SlurmctldParameters.
   2. Hierarchical node communications need to be disabled by setting
      TreeWidth to 65533.
   3. Update resume.py to notify controller of instance's IP address.

   e.g.
   ```
   # slurm.conf
   TreeWidth=65533
   #SlurmctldParameters=cloud_dns,idle_on_node_suspend
   SlurmctldParameters=idle_on_node_suspend

   # resume.py
   UPDATE_NODE_ADDRS = True
   ```

   Then restart slurmctld and all slurmd's.

8. Configure the instances to be able to find the controller node.

   If project2 has been set up with DNS peering back to project1, then
   project1's DNS search path of project1 needs to be added to the compute nodes in
   project2. Otherwise the controller's IP address can be added to instance's
   /etc/hosts. You can find the controller's internal IP address by navigating
   to Compute Engine in project1's GCP Console.

   To do this modify *startup-script.py* (/apps/slurm/scripts/startup-script.py.

   e.g.
   ```
   diff --git a/scripts/startup-script.py b/scripts/startup-script.py
   index 4933efa..481ad4b 100644
   --- a/scripts/startup-script.py
   +++ b/scripts/startup-script.py
   @@ -1006,6 +1006,12 @@ SELINUXTYPE=targeted

    def main():

   +    f = open('/etc/resolv.conf', 'a')
   +    f.write("""
   +search c.<project1>.internal google.internal
   +""")
   +    f.close()
   +
        hostname = socket.gethostname()

        setup_selinux()
   ```

   or

   ```
   diff --git a/scripts/startup-script.py b/scripts/startup-script.py
   index 4933efa..a31cdf4 100644
   --- a/scripts/startup-script.py
   +++ b/scripts/startup-script.py
   @@ -1006,6 +1006,12 @@ SELINUXTYPE=targeted

    def main():

   +    f = open('/etc/hosts', 'a')
   +    f.write("""
   +<controller ip> <controller hostname>
   +""")
   +    f.close()
   +
        hostname = socket.gethostname()

        setup_selinux()
   ```

9. Since the scripts rely on getting the Slurm configuration and binaries
   from the shared /apps file system, the firewall on the project1 must be
   modified to allow NFS through.

   1. On project1's GCP Console, navigate to VPC network->Firewall rules
   2. Click CREATE FIREWALL RULE at the top of the page.
   3. Fill in the following fields:
      ```
      Name                 : nfs
      Network              : slurm-network
      Priority             : 1000
      Direction of traffic : Ingress
      Action to match      : Allow
      Targets              : Specified target tags
      Target tags          : controller
      Source Filter        : IP ranges
      Source IP Ranges     : 0.0.0.0/0
      Second source filter : none
      Protocols and ports  : Specified protocols and ports
      tcp:2049,1110,4045; udp:2049,1110,4045
      ```
   4. Click Create

10. Open ports on project1 for project2 to be able to contact the slurmctld
    (tcp:6819-6830) and the slurmdbd (tcp:6819) on project1.

    1. On project1's GCP Console, navigate to VPC network->Firewall rules
    2. Click CREATE FIREWALL RULE at the top of the page.
    3. Fill in the following fields:
       ```
       Name                 : slurm
       Network              : slurm-network
       Priority             : 1000
       Direction of traffic : Ingress
       Action to match      : Allow
       Targets              : Specified target tags
       Target tags          : controller
       Source Filter        : IP ranges
       Source IP Ranges     : 0.0.0.0/0
       Second source filter : none
       Protocols and ports  : Specified protocols and ports
       tcp:6819-6830
       ```
    4. Click Create

11. Open ports on project2 for project1 to be able to contact the slurmd's
    (tcp:6818) in project2.

    1. On project2's GCP Console, navigate to VPC network->Firewall rules
    2. Click CREATE FIREWALL RULE at the top of the page.
    3. Fill in the following fields:
       ```
       Name                 : slurmd
       Network              : project2-network
       Priority             : 1000
       Direction of traffic : Ingress
       Action to match      : Allow
       Targets              : Specified target tags
       Target tags          : compute
       Source Filter        : IP ranges
       Source IP Ranges     : 0.0.0.0/0
       Second source filter : none
       Protocols and ports  : Specified protocols and ports
       tcp:6818
       ```
    4. Click Create

12. If you plan to use srun to submit jobs from the login nodes to the compute
    nodes in project2, then ports need to be opened up for the compute nodes to
    be able to talk back to the login nodes. srun open's several ephemeral ports
    for communications. It's recommended to define which ports srun can use when
    using a firewall. This is done by defining SrunPortRange=<IP Range> in the
    slurm.conf.

    e.g.
    ```
    SrunPortRange=60001-63000
    ```

    These ports need to opened up in project1 and project2's firewalls.

    1. On project1 and project2's GCP Consoles, navigate to VPC network->Firewall rules
    2. Click CREATE FIREWALL RULE at the top of the page.
    3. Fill in the following fields:
       ```
       Name                 : srun
       Network              : slurm-network
       Priority             : 1000
       Direction of traffic : Ingress
       Action to match      : Allow
       Targets              : All instances in the network
       Source Filter        : IP ranges
       Source IP Ranges     : 0.0.0.0/0
       Second source filter : none
       Protocols and ports  : Specified protocols and ports
       tcp:60001-63000
       ```
    4. Click Create

13. Slurm should now be able to burst out into project2.

14. Image-based nodes on project2.

    Because deployment manager created an image in project1, project2 will
    install from scratch for every bursted-out compute node. In order to create
    a base image for bursting, the following can be done.

    e.g.
    From the controller:
    ```
    [root@g1-controller scripts]# sudo su - slurm
    [slurm@g1-controller ~]$ cd /apps/slurm/scripts/
    [slurm@g1-controller scripts]$ ./resume.py proj2-compute-image

    # Wait until the instance is fully installed. You can verify this by ssh'ing to
    # the instance and verify that there are no messages about installing in the
    # motd.

    [slurm@g1-controller scripts]$ gcloud compute images create <cluster_name>-compute-#-image-$(date '+%Y-%m-%d-%H-%M-%S') \
                                                                --source-disk proj2-compute-image \
                                                                --source-disk-zone <zone> --force \
                                                                --family <cluster_name>-compute-#-image-family \
                                                                --project <project2>

    Where # is the partition index.

    # Then either stop or delete the proj2-compute-#-image instance.
    ```

    Once the image is created, EXTERNAL_IP can be set to False in resume.py.

## Multi-Cluster / Federation
Slurm allows you to use a central SlurmDBD for multiple clusters. By doing this
it also allows the clusters to be able to communicate with each other. This is
done by the client commands first checking with the SlurmDBD for the requested
cluster's IP address and port which the client can then communicate directly
with the cluster.

For more information see:  
[Multi-Cluster Operation](https://slurm.schedmd.com/multi_cluster.html)  
[Federated Scheduling Guide](https://slurm.schedmd.com/federation.html)

**NOTE:** Either all clusters and the SlurmDBD must share the same MUNGE key
or use a separate MUNGE key for each cluster and another key for use between
each cluster and the SlurmDBD. In order for cross-cluster interactive jobs to
work, the clusters must share the same MUNGE key. See the following for more
information:  
[Multi-Cluster Operation](https://slurm.schedmd.com/multi_cluster.html)  
[Accounting and Resource Limits](https://slurm.schedmd.com/accounting.html)

**NOTE:** All clusters attached to a single SlurmDBD must share the same user
space (e.g. same uids across all the clusters).

### Playground

1. Create another project in GCP (e.g. project3) and create another Slurm
   cluster using the deployment scripts -- except with a different cluster name
   (e.g. g2) and possible IP range.

2. Open ports on project1 so that project3 can communicate with project1's
   slurmctld (tcp:6820) and slurmdbd (tcp:6819).

   1. On project1's GCP Console, navigate to VPC network->Firewall rules
   2. Click CREATE FIREWALL RULE at the top of the page.
   3. Fill in the following fields:
      ```
      Name                 : slurm
      Network              : slurm-network
      Priority             : 1000
      Direction of traffic : Ingress
      Action to match      : Allow
      Targets              : Specified target tags
      Target tags          : controller
      Source Filter        : IP ranges
      Source IP Ranges     : 0.0.0.0/0
      Second source filter : none
      Protocols and ports  : Specified protocols and ports
      tcp:6820,6819
      ```
   4. Click Create

3. In project3 open up ports for slurmctld (tcp:6820) so that project1 can
   communicate with project3's slurmctld.
   1. On project3's GCP Console, navigate to VPC network->Firewall rules
   2. Click CREATE FIREWALL RULE at the top of the page.
   3. Fill in the following fields:
      ```
      Name                 : slurm
      Network              : slurm-network
      Priority             : 1000
      Direction of traffic : Ingress
      Action to match      : Allow
      Targets              : Specified target tags
      Target tags          : controller
      Source Filter        : IP ranges
      Source IP Ranges     : 0.0.0.0/0
      Second source filter : none
      Protocols and ports  : Specified protocols and ports
      tcp:6820
      ```
   4. Click Create

4. Optional ports for interactive jobs.

   If you plan to use srun to submit jobs from one cluster to another, then
   ports need to be opened up for srun to be able to communicate with the
   slurmds on the remote cluster and ports need to be opened for the
   slurmds to be able to talk back to the login nodes on the remote cluster.
   srun open's several ephemeral ports for communications. It's recommended to
   define which ports srun can use when using a firewall. This is done by
   defining SrunPortRange=<IP Range> in the slurm.conf.

   e.g.
   ```
   SrunPortRange=60001-63000
   ```

   **NOTE:** In order for cross-cluster interactive jobs to work, the compute
   nodes must be accessible from the login nodes on each cluster
   (e.g. a vpn connection between project1 and project3).

   slurmd ports:  
   1. On project1 and project3's GCP Console, navigate to VPC network->Firewall rules
   2. Click CREATE FIREWALL RULE at the top of the page.
   3. Fill in the following fields:
      ```
      Name                 : slurmd
      Network              : slurm-network
      Priority             : 1000
      Direction of traffic : Ingress
      Action to match      : Allow
      Targets              : Specified target tags
      Target tags          : compute
      Source Filter        : IP ranges
      Source IP Ranges     : 0.0.0.0/0
      Second source filter : none
      Protocols and ports  : Specified protocols and ports
      tcp:6818
      ```
   4. Click Create

   srun ports:  
   1. On project1 and project3's GCP Consoles, navigate to VPC network->Firewall rules
   2. Click CREATE FIREWALL RULE at the top of the page.
   3. Fill in the following fields:
      ```
      Name                 : srun
      Network              : slurm-network
      Priority             : 1000
      Direction of traffic : Ingress
      Action to match      : Allow
      Targets              : All instances in the network
      Source Filter        : IP ranges
      Source IP Ranges     : 0.0.0.0/0
      Second source filter : none
      Protocols and ports  : Specified protocols and ports
      tcp:60001-63000
      ```
   4. Click Create

5. Modify both project1 and project3's slurm.confs to talk to the slurmdbd
   on project1's external IP.

   e.g.
   ```
   AccountingStorageHost=<external IP of project1's controller instance>
   ```

6. Add the cluster to project1's database.

   e.g.
   ```
   $ sacctmgr add cluster g2
   ```

7. Add user and account associations to the g2 cluster.

   In order for a user to run a job on a cluster, the user must have an
   association on the given cluster.

   e.g.
   ```
   $ sacctmgr add account <default account> [cluster=<cluster name>]
   $ sacctmgr add user <user> account=<default account> [cluster=<cluster name>]
   ```

8. Restart the slurmctld on both controllers.

   e.g.
   ```
   $ systemctl restart slurmctld
   ```

9. Verify that the slurmdbd shows both slurmctld's have registered with their
   external IP addresses.

   * When the slurmctld registers with the slurmdbd, the slurmdbd records the
     IP address the slurmctld registered with. This then allows project1 to
     communicate with project3 and vice versa.

   e.g.
   ```
   $ sacctmgr show clusters format=cluster,controlhost,controlport
      Cluster     ControlHost  ControlPort
   ---------- --------------- ------------
           g1 ###.###.###.###         6820
           g2 ###.###.###.###         6820
   ```
10. Now you can communicate with each cluster from the other side.

    e.g.
    ```
    [bob@login0 ~]$ sinfo -Mg1,g2
    CLUSTER: g1
    PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
    debug*       up   infinite      8  idle~ g1-compute-0-[2-9]
    debug*       up   infinite      2   idle g1-compute-0-[0-1]

    CLUSTER: g2
    PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
    debug*       up   infinite      8  idle~ g2-compute-0-[2-9]
    debug*       up   infinite      2   idle g2-compute-0-[0-1]

    [bob@login0 ~]$ sbatch -Mg1 --wrap="srun hostname; sleep 300"
    Submitted batch job 17 on cluster g1

    [bob@login0 ~]$ sbatch -Mg2 --wrap="srun hostname; sleep 300"
    Submitted batch job 8 on cluster g2

    [bob@login0 ~]$ squeue -Mg1,g2
    CLUSTER: g1
                 JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
                    17     debug     wrap      bob  R       0:31      1   g1-compute-0-0

    CLUSTER: g2
                 JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
                     8     debug     wrap      bob  R       0:12      1   g2-compute-0-0
    ```
