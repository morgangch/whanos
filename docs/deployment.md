# 🚀 Whanos Deployment Guide

This guide provides complete instructions for deploying the Whanos infrastructure.

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Server Requirements](#server-requirements)
- [Step-by-Step Deployment](#step-by-step-deployment)
- [Post-Deployment Configuration](#post-deployment-configuration)
- [Troubleshooting](#troubleshooting)
- [Upgrade Guide](#upgrade-guide)

---

## Prerequisites

### Required Software

- **Ansible** 2.9 or higher
- **SSH access** to all target servers
- **Python 3** on all target servers
- **Git** for cloning the repository

### Required Knowledge

- Basic Linux administration
- Understanding of Docker concepts
- Basic Kubernetes knowledge
- Familiarity with Jenkins

---

## Server Requirements

### Minimum Hardware

| Component | CPU | RAM | Disk | Network |
|-----------|-----|-----|------|---------|
| **Jenkins** | 2 cores | 4 GB | 50 GB | 1 Gbps |
| **Registry** | 2 cores | 4 GB | 100 GB | 1 Gbps |
| **K8s Master** | 2 cores | 4 GB | 50 GB | 1 Gbps |
| **K8s Worker** | 2 cores | 8 GB | 100 GB | 1 Gbps |

### Recommended Hardware

| Component | CPU | RAM | Disk | Network |
|-----------|-----|-----|------|---------|
| **Jenkins** | 4 cores | 8 GB | 100 GB | 10 Gbps |
| **Registry** | 4 cores | 8 GB | 500 GB | 10 Gbps |
| **K8s Master** | 4 cores | 8 GB | 100 GB | 10 Gbps |
| **K8s Worker** | 8 cores | 16 GB | 500 GB | 10 Gbps |

### Operating System

- Ubuntu 20.04 LTS or 22.04 LTS
- Debian 11 or 12
- CentOS 8+ (with modifications)

### Network Requirements

- All servers must be able to communicate with each other
- Ports to open:
  - 22 (SSH)
  - 80, 443 (HTTP/HTTPS)
  - 5000 (Docker Registry)
  - 6443 (Kubernetes API)
  - 8080 (Jenkins)
  - 10250-10255 (Kubernetes components)
  - 30000-32767 (Kubernetes NodePort services)

---

## Step-by-Step Deployment

### Step 1: Prepare Servers

1. **Update all servers**
   ```bash
   # Run on each server
   sudo apt update && sudo apt upgrade -y
   sudo reboot
   ```

2. **Configure SSH access**
   ```bash
   # On your control machine
   ssh-keygen -t rsa -b 4096
   
   # Copy to all servers
   ssh-copy-id root@jenkins-server
   ssh-copy-id root@registry-server
   ssh-copy-id root@k8s-master
   ssh-copy-id root@k8s-worker-1
   ssh-copy-id root@k8s-worker-2
   ```

3. **Verify connectivity**
   ```bash
   ansible all -i ansible/inventories/production/hosts.yaml -m ping
   ```

### Step 2: Clone Repository

```bash
git clone https://github.com/morgangch/whanos.git
cd whanos
```

### Step 3: Configure Inventory

1. **Edit hosts file**
   ```bash
   vim ansible/inventories/production/hosts.yaml
   ```
   
   Update with your actual IPs:
   ```yaml
   all:
     children:
       jenkins:
         hosts:
           jenkins-server:
             ansible_host: YOUR_JENKINS_IP
       registry:
         hosts:
           registry-server:
             ansible_host: YOUR_REGISTRY_IP
       k8s_cluster:
         children:
           kube_control_plane:
             hosts:
               k8s-master:
                 ansible_host: YOUR_MASTER_IP
           kube_node:
             hosts:
               k8s-worker-1:
                 ansible_host: YOUR_WORKER1_IP
               k8s-worker-2:
                 ansible_host: YOUR_WORKER2_IP
   ```

2. **Configure variables**
   ```bash
   vim ansible/inventories/production/group_vars/all.yaml
   ```
   
   Update important variables:
   ```yaml
   jenkins_admin_user: Admin
   jenkins_admin_password: YOUR_SECURE_PASSWORD
   docker_registry_password: YOUR_SECURE_PASSWORD
   ```

### Step 4: Run Pre-flight Checks

```bash
# Check Ansible syntax
ansible-playbook --syntax-check \
  -i ansible/inventories/production/hosts.yaml \
  ansible/playbooks/setup.yml

# Dry run
ansible-playbook --check \
  -i ansible/inventories/production/hosts.yaml \
  ansible/playbooks/setup.yml
```

### Step 5: Deploy Infrastructure

```bash
# Full deployment
ansible-playbook \
  -i ansible/inventories/production/hosts.yaml \
  ansible/playbooks/setup.yml \
  -v

# This will:
# 1. Install Docker on all nodes
# 2. Set up Docker Registry
# 3. Install and configure Jenkins
# 4. Deploy Kubernetes cluster
# 5. Configure Whanos integration
```

**Expected Duration:** 20-40 minutes depending on network speed

### Step 6: Verify Deployment

1. **Check Jenkins**
   ```bash
   curl http://JENKINS_IP:8080
   # Should return Jenkins web page
   ```

2. **Check Docker Registry**
   ```bash
   curl http://REGISTRY_IP:5000/v2/
   # Should return: {}
   ```

3. **Check Kubernetes**
   ```bash
   # SSH to master node
   ssh root@k8s-master
   kubectl get nodes
   # Should show all nodes in Ready state
   
   kubectl get pods -A
   # Should show system pods running
   ```

---

## Post-Deployment Configuration

### Step 1: Access Jenkins

1. **Open Jenkins in browser**
   ```
   http://JENKINS_IP:8080
   ```

2. **Login with credentials**
   - Username: `Admin` (or as configured)
   - Password: From `group_vars/all.yaml`

### Step 2: Build Base Images

1. **Navigate to "Whanos base images" folder**
2. **Click "Build all base images"**
3. **Click "Build Now"**
4. **Wait for all images to build** (10-15 minutes)

### Step 3: Configure Git Credentials (Optional)

For private repositories:

1. **Jenkins Dashboard** → **Manage Jenkins** → **Credentials**
2. **Add Credentials**
   - Kind: Username with password
   - Scope: Global
   - ID: `git-credentials`
   - Username: Your Git username
   - Password: Your Git token/password

### Step 4: Link First Project

1. **Click on "link-project" job**
2. **Build with Parameters**
   - Repository URL: `https://github.com/username/repo.git`
   - Display Name: `my-first-app`
   - Branch: `main`
   - Git Credentials: (select if private repo)
3. **Click "Build"**

### Step 5: Test Deployment

1. **Push changes to your repository**
   ```bash
   cd your-app
   echo "Hello Whanos" > test.txt
   git add test.txt
   git commit -m "Test Whanos deployment"
   git push origin main
   ```

2. **Watch Jenkins build**
   - Jenkins should automatically start a build
   - Check build logs for progress

3. **Verify Kubernetes deployment**
   ```bash
   kubectl get pods -n my-first-app
   kubectl get svc -n my-first-app
   ```

---

## Troubleshooting

### Jenkins Issues

**Issue:** Cannot access Jenkins
```bash
# Check Jenkins service
ssh root@jenkins-server
systemctl status jenkins

# Check logs
journalctl -u jenkins -f

# Restart Jenkins
systemctl restart jenkins
```

**Issue:** Jenkins build fails
- Check build logs in Jenkins UI
- Verify Docker is running: `docker ps`
- Check registry connectivity: `docker pull registry.local:5000/whanos-c`

### Docker Registry Issues

**Issue:** Cannot push to registry
```bash
# Check registry is running
ssh root@registry-server
docker ps | grep registry

# Check registry logs
docker logs registry

# Restart registry
docker restart registry
```

**Issue:** Insecure registry error
```bash
# Add to /etc/docker/daemon.json on all nodes
{
  "insecure-registries": ["REGISTRY_IP:5000"]
}

# Restart Docker
systemctl restart docker
```

### Kubernetes Issues

**Issue:** Nodes not ready
```bash
# Check node status
kubectl describe node NODE_NAME

# Check kubelet
systemctl status kubelet
journalctl -u kubelet -f

# Restart kubelet
systemctl restart kubelet
```

**Issue:** Pods not starting
```bash
# Check pod status
kubectl describe pod POD_NAME -n NAMESPACE

# Check logs
kubectl logs POD_NAME -n NAMESPACE

# Check events
kubectl get events -n NAMESPACE --sort-by='.lastTimestamp'
```

### Network Issues

**Issue:** Nodes cannot communicate
```bash
# Test connectivity
ping k8s-master
telnet k8s-master 6443

# Check firewall
sudo ufw status
sudo iptables -L

# Disable firewall temporarily for testing
sudo ufw disable
```

---

## Upgrade Guide

### Upgrading Whanos

1. **Backup current configuration**
   ```bash
   # Backup registry data
   ssh root@registry-server
   docker exec registry tar czf /backup/registry-$(date +%F).tar.gz /var/lib/registry
   
   # Backup Jenkins home
   ssh root@jenkins-server
   tar czf /backup/jenkins-$(date +%F).tar.gz /var/lib/jenkins
   ```

2. **Pull latest changes**
   ```bash
   cd whanos
   git pull origin main
   ```

3. **Review changes**
   ```bash
   git log --oneline -10
   git diff HEAD~1
   ```

4. **Run deployment playbook**
   ```bash
   ansible-playbook \
     -i ansible/inventories/production/hosts.yaml \
     ansible/playbooks/deploy.yml \
     -v
   ```

5. **Rebuild base images**
   - Go to Jenkins
   - Run "Build all base images"

### Rolling Back

If upgrade fails:

```bash
# Restore from backup
cd whanos
git checkout PREVIOUS_VERSION

# Redeploy
ansible-playbook \
  -i ansible/inventories/production/hosts.yaml \
  ansible/playbooks/deploy.yml
```

---

## Security Best Practices

1. **Change default passwords**
   ```bash
   vim ansible/inventories/production/group_vars/all.yaml
   # Update all password fields
   ```

2. **Enable registry authentication**
   ```yaml
   docker_registry_auth_enabled: true
   docker_registry_username: admin
   docker_registry_password: STRONG_PASSWORD
   ```

3. **Use HTTPS**
   - Configure SSL certificates for Jenkins
   - Configure TLS for Docker Registry
   - Use cert-manager for Kubernetes Ingress

4. **Regular updates**
   ```bash
   # Update base images monthly
   ansible-playbook -i inventory deploy.yml --tags update
   ```

5. **Backup regularly**
   - Automate backups using cron
   - Store backups off-site
   - Test restoration procedures

---

## Performance Tuning

### Jenkins

```groovy
// In Jenkins > Manage Jenkins > System Configuration
// Set executor count based on available CPU cores
// Recommended: CPU_CORES - 1
```

### Docker Registry

```yaml
# Increase registry cache
storage:
  cache:
    blobdescriptor: redis
```

### Kubernetes

```bash
# Adjust resource limits in whanos.yml
resources:
  limits:
    cpu: "2000m"
    memory: "2Gi"
  requests:
    cpu: "500m"
    memory: "512Mi"
```

---

## Support

For issues and questions:
- Check logs first
- Review troubleshooting section
- Open an issue on GitHub
- Check EPITECH documentation

---

**Happy deploying! 🚀**
