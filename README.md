# MEC Sandbox Ansible (Multi-node Best Practices)

This repository provides an **Ansible-based automation framework** to set up a multi-node Kubernetes cluster with best practices for container runtimes, networking (CNI), kernel tuning, and development tools.

---

## 📌 Features

* Automated provisioning of **Kubernetes master and worker nodes**
* Support for **containerd** and **Docker** runtimes
* Configurable **CNI (Calico)** for pod networking
* Preconfigured **Helm** installation
* Development environments: **Golang** and **Node.js**
* Kernel optimization for Kubernetes workloads
* Best practices for **role separation** and **inventory management**

---

## ⚡ Pre-requisites

Before running the playbooks, ensure:

1. You have **Ansible** installed on your control machine.
2. You have **SSH access** to all remote nodes (master & workers, if applicable).  

   > **Note:** If your playbooks are running on `localhost` (control machine itself), **SSH is not required**. SSH setup is only necessary for remote worker or master nodes.  

   For remote worker nodes, follow these steps:

```bash
# Generate a new SSH key (ED25519)
ssh-keygen -t ed25519 -C "<your-username>@<your-local-host>"

# Copy the public key to the remote host
ssh-copy-id -i ~/.ssh/id_ed25519.pub <your-username>@<remote-host-ip>
```

> Replace `<remote-host-ip>` with the IP of your worker node.

---

## 📂 Project Structure

```
mec-sandbox-ansible-best-practices-multinode/
├── ansible.cfg                # Ansible configuration
├── requirements.yml           # External role/collection dependencies
├── site.yml                   # Main playbook entrypoint
├── inventories/
│   └── dev/
│       ├── hosts.ini          # Inventory file (IP addresses & groups)
│       └── group_vars/
│           └── all.yml        # Global variables
└── roles/
    ├── common/                # Base setup (packages, users, system prep)
    ├── kernel/                # Kernel tuning & modules for Kubernetes
    ├── containerd/            # Install & configure containerd runtime
    ├── docker/                # Install Docker runtime & daemon configs
    ├── cni_calico/            # Deploy Calico CNI plugin
    ├── kubernetes/
    │   ├── common/            # Common Kubernetes configs
    │   ├── master/            # Master node setup (API server, etcd, controller)
    │   └── worker/            # Worker node join configuration
    ├── helm/                  # Install Helm package manager
    └── dev_env/
        ├── golang/            # Install Go environment
        └── node/              # Install Node.js environment (via NVM)
```

---

## 🛠️ Roles & Tasks Overview

| Role                  | Purpose                                 |
| --------------------- | --------------------------------------- |
| **common**            | Base system setup and dependencies      |
| **kernel**            | Kernel modules, sysctl, network tuning  |
| **containerd**        | Install & configure containerd runtime  |
| **docker**            | Optional Docker setup & configuration   |
| **cni\_calico**       | Deploy Calico networking                |
| **kubernetes/common** | Install kubeadm, kubelet, kubectl       |
| **kubernetes/master** | Initialize master & control-plane setup |
| **kubernetes/worker** | Join worker nodes (requires SSH)        |
| **helm**              | Install Helm for package management     |
| **dev\_env/golang**   | Setup Go development environment        |
| **dev\_env/node**     | Setup Node.js/NVM environment           |

---

## 🚀 Running the Playbooks

### ⚡ Worker Nodes (Optional)

If you want to add worker nodes to your cluster, you need to **uncomment both the inventory entries and the worker play in `site.yml`**.

1. Update the **inventory file** with your node IPs:

`inventories/dev/hosts.ini`

```ini
[k8s_masters]
#localhost ansible_connection=local ansible_python_interpreter=auto_silent ansible_user=xflow
<control-node> ansible_connection=local ansible_python_interpreter=auto_silent ansible_user=<username>
# Optional: define worker nodes here. Uncomment to enable workers
#[k8s_workers]
#worker1 ansible_host=192.168.40.59 ansible_user=ubuntu # change ansible_user if needed
#worker2 ansible_host=192.168.56.12 ansible_user=ubuntu
```

2. Uncomment the worker play in `site.yml`:

```yaml
# Uncomment to run worker setup
#- hosts: k8s_workers
#  become: true
#  vars_prompt:
#    - name: ansible_become_pass
#      prompt: "Enter sudo password for workers"
#      private: true
#  roles:
#    - common
#    - kernel
#    - containerd
#    - kubernetes/common
#    - kubernetes/worker
```

3. Run the main playbook:

```bash
ansible-playbook -i inventories/dev/hosts.ini site.yml -K
```

> `-K` prompts for sudo password if required. You can also export `ANSIBLE_BECOME_PASSWORD` or configure passwordless sudo.

## Variables You May Want to Tweak

* `container_runtime`: `"containerd"` (default) or `"docker"`
* `kube_version`: `"1.29.*"`
* `pod_network_cidr`: `"192.168.0.0/16"`
* `calico_version`: `"v3.30.0"`
* `install_dev_env`: `false` → set to `true` to enable Node/Go tooling

## Tags

You can run just parts of the setup with `--tags` or skip parts with `--skip-tags`. (The roles here are intentionally simple and do not define custom tags; feel free to add them if you want finer control.)

## 📖 Notes

* Ensure worker nodes have SSH access configured before running.
* Use `--tags` if you want to run specific roles (e.g. `--tags kubernetes,helm`).

---

## Notes on Best Practices Applied

* **Idempotent modules**: prefer `apt`, `get_url`, `apt_repository`, `dpkg_selections`, `sysctl`, `modprobe` over shell commands where possible.
* **Handlers for restarts**: containerd/docker restarts are centralized.
* **Separation of concerns**: kernel tuning, runtime, Kubernetes bootstrap, CNI, and dev tools are distinct roles.
* **Inventory & vars**: all tunables live under `group_vars/all.yml` for clarity.
* **Pin versions**: Kubernetes and Calico versions are parameterized.
* **Local-first**: defaults target a single-node control-plane (useful for development or testing).

---
