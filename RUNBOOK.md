# MEC Sandbox Ansible Deployment Guide

## Inventory Layout

- **k8s_masters** → Control plane (API server, etcd, scheduler, controller-manager)
- **k8s_workers** → Optional worker nodes (run pods, kubelet, container runtime)

Example `inventories/dev/hosts.ini`:
```ini
[k8s_masters]
localhost ansible_connection=local ansible_python_interpreter=auto_silent

[k8s_workers]
# worker1 ansible_host=192.168.1.11 ansible_user=ubuntu
# worker2 ansible_host=192.168.1.12 ansible_user=ubuntu

[all:vars]
ansible_become=true
ansible_become_method=sudo
```

## Running Playbooks

1. Install required collections:
   ```bash
   ansible-galaxy collection install -r requirements.yml
   ```

2. Run site.yml (masters + optional workers):
   ```bash
   ansible-playbook -i inventories/dev/hosts.ini site.yml
   ```

3. Single-node cluster: keep `k8s_workers` empty → only master node runs.

4. Multi-node cluster: add worker nodes under `[k8s_workers]` in inventory.


## Multi-node (Masters + Optional Workers)

If you want to add worker nodes (separate machines), follow these steps:

1. On each worker node prepare SSH access and ensure Ansible can reach them (or run the play locally on that host).
2. Edit `inventories/dev/hosts.ini` and add entries under `[k8s_workers]` like:
   ```ini
   [k8s_workers]
   worker1 ansible_host=192.168.56.11 ansible_user=ubuntu
   worker2 ansible_host=192.168.56.12 ansible_user=ubuntu
   ```
3. Run the playbook for master first (to initialize control plane and produce join script):
   ```bash
   ansible-playbook -K -l k8s_masters site.yml
   ```
   After successful run, a join command will be generated on the master at `/tmp/kube_join_cmd.sh`. You can retrieve it with `scp` or `ansible.builtin.fetch`.
4. Copy the `/tmp/kube_join_cmd.sh` to each worker node (e.g., `/tmp/kube_join_cmd.sh`) so that the worker play can use it. Example using scp:
   ```bash
   scp /tmp/kube_join_cmd.sh user@worker1:/tmp/kube_join_cmd.sh
   ```
   Alternatively, you can fetch it programmatically in Ansible from master and distribute to workers via a small play/role.
5. Run the worker play:
   ```bash
   ansible-playbook -K -l k8s_workers site.yml
   ```

Notes:
- Worker nodes will only run `common`, `kernel`, `container_runtime`, and `kubernetes/worker` roles as requested.
- The `kubernetes/worker` role expects a join script (created on master) at `/tmp/kube_join_cmd.sh`. If you prefer, you can expose the master token & CA hash via a secure variable and run `kubeadm join` directly in the role.