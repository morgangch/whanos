# Whanos Job DSL Files

## Structure

```
jenkins/jobs/
├── folders.dsl           # Crée les dossiers "Whanos base images" et "Projects"
├── whanos-c.dsl          # Job de build whanos-c
├── whanos-java.dsl       # Job de build whanos-java
├── whanos-javascript.dsl # Job de build whanos-javascript
├── whanos-python.dsl     # Job de build whanos-python
├── whanos-befunge.dsl    # Job de build whanos-befunge
├── build-all.dsl         # Job qui trigger tous les builds
└── link-project.dsl      # Job pour lier un repo Git
```

## Vrais fichiers DSL vs Scripts Groovy

### ✅ Vrais fichiers .dsl (actuel)
```groovy
// whanos-c.dsl
freeStyleJob('Whanos base images/whanos-c') {
    displayName('whanos-c')
    description('Build and push whanos-c base image')
    
    steps {
        shell('docker build ...')
    }
}
```

**Avantages** :
- Syntaxe DSL pure
- Un fichier = un job (ou groupe de jobs)
- Facile à organiser et maintenir
- Modification d'un job = modifier uniquement son fichier
- Clear separation of concerns

### ❌ Script .groovy (ancien)
```groovy
// whanos-jobs.groovy
def languages = ['c', 'java', ...]

languages.each { lang ->
    freeStyleJob("whanos-${lang}") {
        // ...
    }
}
```

**Problèmes** :
- Tout dans un seul fichier
- Modification mineure = retraiter tout
- Moins lisible pour job unique

## Fonctionnement

### 1. Démarrage
```
Jenkins démarre
  ↓
Exécute init.groovy.d/01-security.groovy (Admin user)
  ↓
Exécute init.groovy.d/02-folders.groovy (Seed job)
  ↓
Seed job lit jobs/*.dsl
  ↓
Crée tous les jobs
```

### 2. Seed Job
Le seed job pointe vers : `/var/jenkins_home/whanos-jenkins/jobs/*.dsl`

Il va lire **tous les fichiers .dsl** et créer les jobs correspondants.

### 3. Modification d'un job

**Avant (groovy)** :
```bash
# Modifier whanos-jobs.groovy
# Relancer seed job → retraite TOUT
```

**Maintenant (dsl)** :
```bash
# Modifier seulement whanos-c.dsl
# Relancer seed job → retraite uniquement ce qui a changé
```

## Ordre d'exécution

Les fichiers sont traités par ordre alphabétique :

1. `build-all.dsl` - ✅ Peut créer le job (dépend des autres jobs)
2. `folders.dsl` - ✅ Crée les dossiers en premier
3. `link-project.dsl` - ✅ Crée le job link-project
4. `whanos-befunge.dsl` - ✅
5. `whanos-c.dsl` - ✅
6. `whanos-java.dsl` - ✅
7. `whanos-javascript.dsl` - ✅
8. `whanos-python.dsl` - ✅

**Note** : Job DSL est intelligent, il résout les dépendances automatiquement.

## Exemples de fichiers

### folders.dsl
```groovy
folder('Whanos base images') {
    displayName('Whanos base images')
    description('Contains all Whanos base image build jobs')
}

folder('Projects') {
    displayName('Projects')
    description('Contains all linked project jobs')
}
```

### whanos-c.dsl
```groovy
freeStyleJob('Whanos base images/whanos-c') {
    displayName('whanos-c')
    description('Build and push whanos-c base image to Docker registry')
    
    steps {
        shell('''#!/bin/bash
set -e
echo "Building whanos-c base image..."
cd ${WORKSPACE}/../../../images/c
docker build -t whanos-c -f Dockerfile.base .
docker tag whanos-c ${DOCKER_REGISTRY:-localhost:5000}/whanos-c:latest
docker push ${DOCKER_REGISTRY:-localhost:5000}/whanos-c:latest
echo "✅ whanos-c base image built and pushed successfully!"
''')
    }
}
```

### build-all.dsl
```groovy
freeStyleJob('Whanos base images/Build all base images') {
    displayName('Build all base images')
    description('Trigger all whanos base image builds')
    
    steps {
        downstreamParameterized {
            trigger('Whanos base images/whanos-c') {
                block {
                    buildStepFailure('FAILURE')
                    failure('FAILURE')
                    unstable('UNSTABLE')
                }
            }
        }
        // ... autres triggers
    }
}
```

### link-project.dsl
```groovy
freeStyleJob('link-project') {
    displayName('link-project')
    description('Link a Git repository to Whanos')
    
    parameters {
        stringParam('REPOSITORY_URL', '', 'Git repository URL')
        stringParam('DISPLAY_NAME', '', 'Project display name')
        choiceParam('BRANCH', ['main', 'master', 'develop'], 'Branch')
        stringParam('GIT_CREDENTIALS', '', 'Credentials ID (optional)')
    }
    
    steps {
        dsl {
            text('''
freeStyleJob("Projects/${DISPLAY_NAME}") {
    scm {
        git {
            remote { url("${REPOSITORY_URL}") }
            branch("${BRANCH}")
        }
    }
    
    triggers {
        scm('* * * * *')  // Poll every minute
    }
    
    steps {
        shell(\'\'\'
            # Build script here
        \'\'\')
    }
}
''')
            removeAction('DELETE')
            removeViewAction('DELETE')
        }
    }
}
```

## Mise à jour

Pour mettre à jour un job :

1. **Modifier le fichier .dsl correspondant**
   ```bash
   vim jenkins/jobs/whanos-c.dsl
   ```

2. **Relancer le seed job**
   ```bash
   curl -X POST http://localhost:8080/job/whanos-seed-job/build --user Admin:admin
   ```

3. **Job mis à jour automatiquement !** ✅

## Avantages de cette approche

✅ **Modularité** : Un fichier = une responsabilité
✅ **Maintenabilité** : Facile de trouver et modifier un job
✅ **Git-friendly** : Diffs clairs, reviews faciles
✅ **Scalabilité** : Ajouter un nouveau job = créer un nouveau .dsl
✅ **Testabilité** : Peut tester un fichier individuellement
✅ **Documentation** : Le nom du fichier indique son contenu

## Tests

Pour tester un fichier DSL avant de l'appliquer :

```bash
# Copier dans Jenkins
docker cp jenkins/jobs/whanos-c.dsl whanos-jenkins:/tmp/

# Dans Jenkins, aller dans le seed job
# Modifier temporairement le path vers /tmp/whanos-c.dsl
# Lancer le build pour tester
```

## Ordre recommandé pour créer de nouveaux jobs

1. Créer le fichier `.dsl` dans `jenkins/jobs/`
2. Commit et push dans Git
3. Relancer le seed job via API ou UI
4. Vérifier que le job est créé

Exemple :
```bash
# Créer nouveau job
cat > jenkins/jobs/whanos-rust.dsl << 'EOF'
freeStyleJob('Whanos base images/whanos-rust') {
    displayName('whanos-rust')
    description('Build Rust base image')
    steps {
        shell('docker build ...')
    }
}
EOF

# Commit
git add jenkins/jobs/whanos-rust.dsl
git commit -m "Add Rust base image job"

# Relancer seed job
curl -X POST http://localhost:8080/job/whanos-seed-job/build --user Admin:admin

# Done! ✅
```

## Comparaison finale

| Aspect | .groovy (script) | .dsl (fichiers) |
|--------|------------------|-----------------|
| Organisation | Tout dans un fichier | Un fichier par job/groupe |
| Lisibilité | Moyen (loops, logic) | Excellent (déclaratif) |
| Maintenance | Difficile (tout modifier) | Facile (modifier un fichier) |
| Git diff | Large (tout le fichier) | Précis (fichier modifié) |
| Testabilité | Test tout ou rien | Test fichier par fichier |
| Scalabilité | Difficile (fichier grandit) | Facile (ajouter fichiers) |

**Conclusion** : Les vrais fichiers .dsl sont la meilleure approche ! 🚀
