# 🐋 Whanos — Projet DevOps Complet

> **Objectif :** Créer une infrastructure capable de **déployer automatiquement une application** sur un cluster Kubernetes à partir d’un simple **push Git**.

---

## 🧠 Introduction

**Whanos** est une infrastructure DevOps visant à automatiser tout le cycle de vie d’une application, en combinant plusieurs technologies majeures :

* 🐳 **Docker** — Containerisation
* ⚙️ **GitHub Actions / Jenkins** — Automatisation
* 🧩 **Ansible** — Gestion de configuration
* ☸️ **Kubernetes** — Orchestration

L’objectif est de permettre à un développeur de **déployer automatiquement** une application dans un cluster, simplement en **poussant du code** dans un dépôt compatible Whanos.

---

## ⚙️ Fonctionnement Général

Lorsqu’un dépôt compatible est mis à jour :

1. **Récupération** du dépôt Git.
2. **Analyse** du contenu pour déterminer la technologie utilisée.
3. **Containerisation** de l’application en image Docker (basée sur une image Whanos).
4. **Publication** de l’image sur un registre Docker.
5. **Déploiement automatique** sur un cluster Kubernetes si un fichier `whanos.yml` est présent.

---

## 📁 Dépôt Compatible Whanos

### Structure requise

* Une application unique dans un dossier `app/` à la racine du dépôt.

### Langages supportés

| Langage        | Détection                      | Compilation / Exécution   | Image de base       |
| -------------- | ------------------------------ | ------------------------- | ------------------- |
| **C**          | `Makefile` à la racine         | `make` → `compiled-app`   | `whanos-c`          |
| **Java**       | `pom.xml` dans `app/`          | `mvn package` → `app.jar` | `whanos-java`       |
| **JavaScript** | `package.json` à la racine     | `node .`                  | `whanos-javascript` |
| **Python**     | `requirements.txt` à la racine | `python -m app`           | `whanos-python`     |
| **Befunge**    | `main.bf` dans `app/`          | Libre                     | `whanos-befunge`    |

> 💡 Un dépôt ne doit correspondre qu’à **un seul critère** de détection.

---

## 🧱 Spécifications des Images Whanos

### Caractéristiques générales

* Basées sur des **images officielles Docker**.
* Utilisent **bash** (`/bin/bash`) pour la construction.
* Travaillent dans un répertoire `/app`.
* Suppriment les fichiers inutiles après compilation.
* Définissent la **commande d’exécution** selon le langage.

### Deux types d’images

#### 1. **Standalone**

* Fonctionnent sans configuration externe.
* Utilisées lorsque le dépôt **n’a pas de Dockerfile**.

#### 2. **Base**

* Servent de **base personnalisable** pour les applications avec un `Dockerfile`.
* Doivent être **construites indépendamment** :

  ```bash
  docker build -t whanos-something - < Dockerfile.base
  ```

---

## 🧩 Jenkins — Automatisation CI/CD

### Configuration générale

* Prise en charge des **dépôts privés** (GitHub, GitLab, etc.).
* Pas d’inscription libre.
* Utilisateur obligatoire : `Admin` (droits complets).

### Structure Jenkins

```
Jenkins
├── Whanos base images/
│   ├── whanos-c
│   ├── whanos-java
│   ├── ...
│   └── Build all base images
├── Projects/
│   └── (Jobs créés dynamiquement)
└── link-project
```

### Jobs Jenkins

| Type de job               | Fonction                                                      |
| ------------------------- | ------------------------------------------------------------- |
| **Base image jobs**       | Construisent chaque image de base pour Docker.                |
| **Build all base images** | Déclenche tous les jobs précédents.                           |
| **link-project**          | Crée un job pour un dépôt donné et l’intègre à Whanos.        |
| **Jobs de projet**        | Vérifient les commits, buildent et déploient automatiquement. |

---

## ☸️ Kubernetes — Déploiement Automatique

### Fichier `whanos.yml`

Contient les paramètres de déploiement :

```yaml
deployment:
  replicas: 2
  resources:
    limits:
      cpu: "500m"
      memory: "512Mi"
  ports: [80, 443]
```

### Exigences

* Minimum **2 nœuds** dans le cluster.
* Les **ports exposés** doivent être accessibles depuis l’extérieur.
* Le déploiement doit être documenté.

---

## 🚀 Déploiement de l’Infrastructure

### Technologie recommandée

* **Ansible** pour la gestion et le déploiement automatisé.

### Exigences

* Playbooks **idempotents**.
* Utilisation maximale de **modules Ansible**.
* Variables d’environnement pour personnaliser le déploiement.

> 🔧 L’utilisation de **Ansible Galaxy** et de **kubespray** est autorisée et encouragée.

---

## 🧾 Structure du Dépôt de Livraison

```
/
├── images/
│   ├── c/
│   │   ├── Dockerfile.base
│   │   └── Dockerfile.standalone
│   ├── java/
│   └── ...
├── docs/
│   └── (Documentation technique)
├── jenkins/
│   └── (scripts ou fichiers de configuration)
└── kubernetes/
    └── (fichiers de déploiement)
```

> Tout fichier non présent dans le dépôt sera considéré comme **codé en dur**.

---

## 🧑‍⚖️ Évaluation

### Critères

* Fonctionnalité complète du pipeline.
* Qualité du code et respect des bonnes pratiques.
* Clarté et propreté du dépôt.
* Accessibilité de l’infrastructure en ligne.
* Facilité de **redeployabilité**.

---

## 💡 Conseils et Extensions

* Explorez davantage **Docker** et **Jenkins** pour des fonctionnalités avancées.
* Vous pouvez ajouter :

  * De nouveaux langages (C++, Go, Rust, Brainfuck…)
  * Support de plusieurs branches
  * Un ASCII Art Whanos dans les logs Jenkins
  * Plus d’options dans `whanos.yml`
* Évitez **Docker-in-Docker** dans Jenkins !
* Pensez à utiliser un **registre Docker privé**.

---

## 🔗 Ressources

* [Docker Registry](https://hub.docker.com/_/registry)
* [Kubespray](https://github.com/kubernetes-sigs/kubespray)
* [Kubernetes Resource Management](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#resource-requests-and-limits-of-pod-and-container)

---

Excellent 👌 — voici un **plan d’architecture complet, hiérarchisé et cohérent** du projet **Whanos**, tel qu’il serait déployé dans un environnement DevOps moderne.
Ce plan intègre les 4 technologies-clés (**Docker, Jenkins, Ansible, Kubernetes**) et décrit comment elles interagissent pour réaliser le **déploiement automatique d’applications** à partir de dépôts Git compatibles.

---

# 🏗️ Architecture Complète du Projet **Whanos**

> **Objectif global :**
> Automatiser tout le cycle de vie d’une application — du push Git jusqu’à la mise en production —
> via une infrastructure intégrant **Docker**, **Jenkins**, **Kubernetes** et **Ansible**.

---

## 🔹 1. Vue d’ensemble

```text
          ┌────────────────────────────┐
          │       Dépôt Git (Dev)      │
          │  - app/                    │
          │  - whanos.yml              │
          └────────────┬───────────────┘
                       │ (git push)
                       ▼
          ┌────────────────────────────┐
          │         Jenkins CI/CD       │
          │ - link-project job          │
          │ - Build image pipeline      │
          │ - Déploiement K8s           │
          └────────────┬───────────────┘
                       │ (Docker build/push)
                       ▼
          ┌────────────────────────────┐
          │       Docker Registry       │
          │ - whanos-* images           │
          │ - app images                │
          └────────────┬───────────────┘
                       │ (kubectl apply)
                       ▼
          ┌────────────────────────────┐
          │      Cluster Kubernetes     │
          │ - 2+ nodes (worker/master)  │
          │ - Namespaces par projet     │
          │ - Pods, Services, Ingress   │
          └────────────┬───────────────┘
                       │ (Ansible deploy)
                       ▼
          ┌────────────────────────────┐
          │        Ansible Host         │
          │ - Playbooks d’installation  │
          │ - Déploiement automatisé    │
          └────────────────────────────┘
```

---

## 🔹 2. Composants principaux

### 🧱 2.1 Jenkins (CI/CD Engine)

#### Rôle :

* Gère **l’intégration continue (CI)** et le **déploiement continu (CD)**.
* Exécute automatiquement les étapes :

  1. Clonage du dépôt Git.
  2. Détection du langage / techno.
  3. Construction de l’image Docker.
  4. Publication sur le registre.
  5. Déploiement sur Kubernetes.

#### Structure :

```
/var/lib/jenkins/
├── jobs/
│   ├── Whanos base images/
│   │   ├── whanos-c/
│   │   ├── whanos-java/
│   │   ├── whanos-python/
│   │   ├── whanos-javascript/
│   │   └── whanos-befunge/
│   ├── Build all base images/
│   ├── link-project/
│   └── Projects/
│       ├── project-1/
│       ├── project-2/
│       └── ...
└── config/
    └── credentials.xml
```

#### Détails techniques :

* **Plugins :**

  * Git / GitHub / GitLab
  * Docker / Docker Pipeline
  * Kubernetes CLI / Credentials Binding
* **Sécurité :**

  * Utilisateur unique `Admin`
  * Accès SSH/HTTPS aux dépôts privés

---

### 🐳 2.2 Docker Registry (Images)

#### Rôle :

Stocker les **images Whanos** (de base et standalone) et les **images construites** pour les applications déployées.

#### Organisation :

```
registry.whanos.local/
├── whanos-c
├── whanos-java
├── whanos-python
├── whanos-javascript
├── whanos-befunge
└── apps/
    ├── myapp:latest
    └── api-service:v1.2
```

#### Points clés :

* Peut utiliser le **Docker Registry officiel** (`registry:2`).
* Authentification Jenkins → Registry.
* Nettoyage automatique des images obsolètes (cron/Ansible).

---

### ☸️ 2.3 Kubernetes Cluster

#### Rôle :

Héberge les applications déployées via les images construites.

#### Structure typique :

```
Cluster Kubernetes (min. 2 nodes)
├── master-node
│   ├── API Server
│   ├── Scheduler
│   ├── Controller Manager
│   └── etcd
└── worker-nodes
    ├── kubelet
    ├── kube-proxy
    ├── Pods (app containers)
    └── Services / Ingress
```

#### Organisation des déploiements :

Chaque application liée par `link-project` dispose :

* d’un **namespace dédié**
* d’un **Deployment** (`replicas` défini dans `whanos.yml`)
* d’un **Service** (ClusterIP / NodePort)
* d’un **Ingress** si port exposé

#### Exemple d’objet déployé :

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: myapp-ns
spec:
  replicas: 2
  template:
    spec:
      containers:
      - name: myapp
        image: registry.whanos.local/apps/myapp:latest
        ports:
        - containerPort: 80
```

---

### 🧩 2.4 Ansible (Déploiement & Configuration)

#### Rôle :

* Installe et configure **toute l’infrastructure Whanos** :

  * Jenkins + plugins
  * Docker + Registry
  * Cluster Kubernetes (via **Kubespray**)
* Assure la **reproductibilité** et l’**idempotence**.

#### Structure des playbooks :

```
ansible/
├── inventories/
│   └── production/
│       ├── hosts.yaml
│       └── group_vars/
│           ├── all.yaml
│           └── k8s_cluster.yaml
├── roles/
│   ├── jenkins/
│   ├── docker-registry/
│   ├── kubernetes/
│   └── whanos-config/
└── playbooks/
    ├── setup.yml
    ├── deploy.yml
    └── teardown.yml
```

#### Variables typiques :

```yaml
jenkins_admin_user: "Admin"
jenkins_admin_password: "securepassword"
docker_registry_url: "registry.whanos.local"
k8s_cluster_nodes:
  - master.whanos.local
  - worker1.whanos.local
  - worker2.whanos.local
```

---

## 🔹 3. Flux de Déploiement Automatisé

### Étape 1 — Push Git

Le développeur pousse son code vers un dépôt Whanos-compatible.

### Étape 2 — Jenkins Trigger

Le job `link-project` détecte la modification (poll SCM).

### Étape 3 — Build Docker

Jenkins :

* Identifie le langage (Makefile, pom.xml, etc.)
* Construit l’image à partir de la bonne base (`whanos-xxx`)
* Push l’image dans le Docker Registry.

### Étape 4 — Déploiement Kubernetes

* Si `whanos.yml` existe :

  * Jenkins applique les manifests (générés ou templates)
  * Le pod est lancé sur le cluster
* Sinon, build-only.

### Étape 5 — Monitoring / Logs

* Jenkins journalise toutes les étapes.
* Kubectl / Lens / Grafana peuvent être utilisés pour le suivi.

---

## 🔹 4. Sécurité & Accès

| Composant      | Sécurité / Accès                                  |
| -------------- | ------------------------------------------------- |
| **Jenkins**    | Authentification admin + credentials Git/Registry |
| **Registry**   | Auth HTTP Basic ou token                          |
| **Kubernetes** | RBAC par namespace                                |
| **Ansible**    | Connexions SSH sécurisées avec clé privée         |

---

## 🔹 5. Extensions possibles

* 🌐 Intégration HTTPS via **Ingress NGINX + Cert-Manager**
* 📊 Monitoring : **Prometheus + Grafana**
* 🔐 Vault / Secret Manager pour les credentials
* 🧠 Support de nouveaux langages (Go, Rust, C++…)
* 🧰 Interface web “Whanos Dashboard” (optionnel)

---

## 🔹 6. Vue Résumée Technique

| Technologie    | Rôle                      | Déploiement             | Liens                   |
| -------------- | ------------------------- | ----------------------- | ----------------------- |
| **Docker**     | Containerisation des apps | Jenkins + Registry      | Docker Hub / Local      |
| **Jenkins**    | CI/CD                     | Ansible (via Docker/VM) | Git + Docker + K8s      |
| **Kubernetes** | Orchestration             | Kubespray (Ansible)     | Nodes / Pods / Services |
| **Ansible**    | Automatisation infra      | Ansible Control Node    | Configure tout le reste |
