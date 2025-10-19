# 🐋 Whanos - Automated DevOps Infrastructure

![Whanos Banner](https://img.shields.io/badge/DevOps-Whanos-blue?style=for-the-badge)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat&logo=docker&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=flat&logo=kubernetes&logoColor=white)
![Jenkins](https://img.shields.io/badge/Jenkins-D24939?style=flat&logo=jenkins&logoColor=white)
![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=flat&logo=ansible&logoColor=white)

**Whanos** is a complete DevOps infrastructure that automatically deploys applications to a Kubernetes cluster from a simple Git push. It combines Docker, Jenkins, Ansible, and Kubernetes to provide a seamless CI/CD experience.

---

## 📋 Table of Contents

- [Features](#-features)
- [Architecture](#-architecture)
- [Quick Start](#-quick-start)
- [Supported Languages](#-supported-languages)
- [Project Structure](#-project-structure)
- [Configuration](#-configuration)
- [Usage](#-usage)
- [Documentation](#-documentation)

---

## ✨ Features

- 🚀 **Automatic Deployment** - Push code, get deployed applications
- 🐳 **Multi-Language Support** - C, Java, JavaScript, Python, Befunge
- ☸️ **Kubernetes Integration** - Automatic orchestration and scaling
- 🔧 **Jenkins CI/CD** - Complete automation pipeline
- 📦 **Private Docker Registry** - Secure image storage
- 🎯 **Simple Configuration** - Just add a `whanos.yml` file
- 🔒 **Security First** - Authentication and RBAC support
- 📊 **Production Ready** - Designed for real-world deployments

---

## 🏗️ Architecture

```
┌─────────────────┐
│   Git Push      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Jenkins CI/CD  │  ◄─── Detects language
│  - Build         │       Builds Docker image
│  - Test          │       Pushes to registry
│  - Deploy        │       Deploys to K8s
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Docker Registry │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Kubernetes    │
│   - Pods        │
│   - Services    │
│   - Ingress     │
└─────────────────┘
```

---

## 🚀 Quick Start

### Prerequisites

- Minimum 3 servers (1 for Jenkins, 1 for Registry, 2+ for Kubernetes)
- Ubuntu 20.04+ / Debian 11+
- Ansible 2.9+
- SSH access to all servers

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/morgangch/whanos.git
   cd whanos
   ```

2. **Configure inventory**
   ```bash
   cd ansible/inventories/production
   vim hosts.yaml
   ```
   
   Update with your server IPs:
   ```yaml
   all:
     children:
       jenkins:
         hosts:
           jenkins-server:
             ansible_host: 192.168.1.10
       registry:
         hosts:
           registry-server:
             ansible_host: 192.168.1.11
       k8s_cluster:
         children:
           kube_control_plane:
             hosts:
               master-node:
                 ansible_host: 192.168.1.20
           kube_node:
             hosts:
               worker-node-1:
                 ansible_host: 192.168.1.21
               worker-node-2:
                 ansible_host: 192.168.1.22
   ```

3. **Configure variables**
   ```bash
   vim ansible/inventories/production/group_vars/all.yaml
   ```

4. **Deploy infrastructure**
   ```bash
   # Using the helper script (recommended)
   ./deploy.sh setup
   
   # Or directly with Ansible
   cd ansible
   ansible-playbook playbooks/setup.yml
   ```

5. **Access Jenkins**
   - Open `http://<jenkins-ip>:8080`
   - Login with credentials from `group_vars/all.yaml`
   - Run "Build all base images" job

6. **Link your first project**
   - Click on "link-project" job
   - Enter your Git repository URL
   - Watch it build and deploy automatically!

---

## 💻 Supported Languages

| Language | Detection | Build Command | Requirements |
|----------|-----------|---------------|--------------|
| **C** | `Makefile` at root | `make` | Produces `compiled-app` |
| **Java** | `app/pom.xml` | `mvn package` | Produces `app.jar` |
| **JavaScript** | `package.json` at root | `npm install` | Uses Node.js |
| **Python** | `requirements.txt` at root | `pip install` | Python 3.11+ |
| **Befunge** | `app/main.bf` | Interpreter | Befunge-93 |

---

## 📁 Project Structure

```
whanos/
├── ansible/                    # Infrastructure automation
│   ├── inventories/           # Server inventories
│   ├── playbooks/             # Deployment playbooks
│   │   ├── setup.yml         # Initial setup
│   │   ├── deploy.yml        # Deploy/update
│   │   └── teardown.yml      # Cleanup
│   └── roles/                 # Ansible roles
│       ├── jenkins/          # Jenkins installation
│       ├── docker-registry/  # Registry setup
│       ├── kubernetes/       # K8s cluster setup
│       └── whanos-config/    # Integration config
├── docs/                      # Documentation
│   ├── architecture.md       # Architecture details
│   ├── deployment.md         # Deployment guide
│   └── README.md            # Docs index
├── images/                    # Docker images
│   ├── c/                    # C base images
│   ├── java/                 # Java base images
│   ├── javascript/           # JavaScript base images
│   ├── python/               # Python base images
│   └── befunge/              # Befunge base images
├── jenkins/                   # Jenkins configurations
│   ├── Jenkinsfile          # Main pipeline
│   ├── build-base-images.groovy  # Build images
│   └── link-project.groovy   # Link new projects
├── kubernetes/                # K8s manifests
│   ├── deployment.yaml      # Deployment template
│   ├── service.yaml         # Service template
│   └── ingress.yaml         # Ingress template
└── whanos_example_apps/       # Example applications

```

---

## ⚙️ Configuration

### Whanos-Compatible Repository

Your repository must have:
- An `app/` directory with your source code
- A language marker file (see [Supported Languages](#-supported-languages))
- Optional: `whanos.yml` for Kubernetes deployment
- Optional: Custom `Dockerfile` (uses base images)

### Example `whanos.yml`

```yaml
deployment:
  replicas: 2
  resources:
    limits:
      cpu: "500m"
      memory: "512Mi"
    requests:
      cpu: "250m"
      memory: "256Mi"
  ports: [80, 443]
  env:
    NODE_ENV: production
    LOG_LEVEL: info
```

---

## 🎯 Usage

### 1. Build Base Images

First time only:
```bash
# In Jenkins, run "Build all base images" job
```

### 2. Link a Project

```bash
# In Jenkins:
# - Click "link-project"
# - Enter: Repository URL, Display Name, Branch
# - Optional: Add Git credentials for private repos
```

### 3. Automatic Deployment

```bash
# Just push to your repository!
git add .
git commit -m "Deploy to Whanos"
git push origin main

# Jenkins will automatically:
# 1. Detect language
# 2. Build Docker image
# 3. Push to registry
# 4. Deploy to Kubernetes (if whanos.yml exists)
```

### 4. Monitor Deployment

```bash
# Check Jenkins build logs
# Check Kubernetes deployment
kubectl get pods -n <your-app-name>
kubectl get svc -n <your-app-name>
```

---

## 📚 Documentation

Detailed documentation is available in the `docs/` directory:

- [Architecture Guide](docs/architecture.md) - System architecture and components
- [Deployment Guide](docs/deployment.md) - Step-by-step deployment instructions
- [Project Specification](projet-basis.md) - Complete project requirements

---

## 🔧 Advanced Configuration

### Custom Dockerfile

If your project has a `Dockerfile`, it will be used instead of the standalone image. Your Dockerfile should use the appropriate Whanos base image:

```dockerfile
FROM whanos-javascript

# Your custom build steps
COPY . /app
RUN npm install

CMD ["node", "server.js"]
```

### Multiple Environments

Configure different branches for dev/staging/prod:
```bash
# In link-project, create multiple jobs:
# - myapp-dev (branch: develop)
# - myapp-staging (branch: staging)
# - myapp-prod (branch: main)
```

---

## 🛠️ Maintenance

### Update Infrastructure

```bash
ansible-playbook -i inventories/production/hosts.yaml playbooks/deploy.yml
```

### Teardown Infrastructure

```bash
# Soft teardown (keep data)
ansible-playbook -i inventories/production/hosts.yaml playbooks/teardown.yml

# Full teardown (remove all data)
ansible-playbook -i inventories/production/hosts.yaml playbooks/teardown.yml \
  --tags remove-data,reset-k8s
```

### Backup Registry Data

```bash
# On registry server
docker exec registry tar czf /tmp/registry-backup.tar.gz /var/lib/registry
docker cp registry:/tmp/registry-backup.tar.gz ./
```

---

## 🤝 Contributing

Contributions are welcome! Feel free to:
- Add support for new languages
- Improve documentation
- Fix bugs
- Add features

---

## 📝 License

This project is part of the EPITECH curriculum.

---

## 👥 Authors

- Morgan GCH - [@morgangch](https://github.com/morgangch)

---

## 🙏 Acknowledgments

- Docker for containerization
- Kubernetes for orchestration
- Jenkins for CI/CD automation
- Ansible for infrastructure management
- Kubespray for Kubernetes deployment

---

**Made with ❤️ for DevOps automation**
