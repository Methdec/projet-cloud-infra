# Rapport de Projet Cloud Computing : Automatisation et Conteneurisation

## 1. Introduction et contexte
[cite_start]Dans un contexte de transformation numérique, la PME souhaitant moderniser ses services est confrontée à la fragilité de son infrastructure historique[cite: 3, 4]. [cite_start]La méthode traditionnelle de déploiement manuel sur serveur unique engendre des risques majeurs : impossibilité de reproduire l'environnement, maintenance complexe et absence de résilience en cas de défaillance matérielle[cite: 4].
[cite_start]Ce projet vise à concevoir une solution industrialisée respectant les standards de l'industrie : automatisation complète, virtualisation des ressources et conteneurisation des services applicatifs[cite: 5, 8, 9, 10, 11, 12].

## 2. Présentation de l'architecture
L'architecture adoptée est une structure **3-tiers** modulaire. [cite_start]Ce découpage logique permet de séparer les responsabilités de chaque composant afin de faciliter la maintenance et d'accroître la sécurité[cite: 21, 22, 23].




1. [cite_start]**Reverse Proxy (Tier 1)** : Basé sur **Nginx**, il agit comme une passerelle sécurisée recevant les requêtes HTTP externes, terminant la connexion, et redirigeant le trafic interne vers l'application[cite: 22, 47].
2. **Application (Tier 2)** : Instance **Flask** (Python) conteneurisée. [cite_start]C'est ici que réside la logique métier de l'application[cite: 22, 35].
3. [cite_start]**Base de données (Tier 3)** : Instance **PostgreSQL** isolée, stockant les données de manière persistante, inaccessible directement depuis l'extérieur du réseau virtuel[cite: 23].

## 3. Description de l'infrastructure virtualisée
[cite_start]L'infrastructure a été déployée sur un environnement **KVM/libvirt**[cite: 59].
- [cite_start]**Gestion des ressources** : L'utilisation de **Terraform** permet de déclarer l'état souhaité de l'infrastructure[cite: 16]. [cite_start]Le code définit le nombre de CPUs, la mémoire allouée (512 Mo par VM) et le stockage (volumes persistants de 10 Go par VM)[cite: 27, 28].
- **Reproductibilité** : Le fichier `main.tf` centralise la configuration réseau et système. [cite_start]Cela garantit que chaque environnement déployé est identique au précédent, éliminant les variations de configuration manuelle[cite: 31].
- **Sécurité initiale** : L'injection de clés SSH via `cloud-init` permet un accès sécurisé immédiat, sans mot de passe, dès le démarrage des machines virtuelles.

## 4. Présentation du déploiement automatisé
Le déploiement est scindé en deux phases distinctes pour une modularité maximale :
1. [cite_start]**Phase de Provisioning (Terraform)** : Terraform interroge l'hyperviseur pour créer les disques virtuels, configurer les interfaces réseau et démarrer les instances[cite: 28, 29].
2. **Phase de Configuration (Ansible)** : Une fois les machines en ligne, Ansible prend le relais. [cite_start]Il automatise l'installation des dépendances (`apt update`, `docker.io`) et procède au déploiement des conteneurs via le module `docker_container`[cite: 30, 41]. [cite_start]Cette méthode "push" permet de configurer l'ensemble du parc serveur en une seule commande, assurant la cohérence de l'état applicatif[cite: 31, 53].

## 5. Description de la conteneurisation
[cite_start]Chaque service est exécuté au sein de son propre conteneur **Docker**[cite: 41].
- [cite_start]**Encapsulation** : L'application Flask et ses bibliothèques Python sont isolées du système d'exploitation hôte[cite: 52].
- **Maintenance** : Cette approche permet de mettre à jour un service (ex: passage à une nouvelle version de Nginx) sans réinstaller tout le serveur.
- **Portabilité** : Le conteneur peut être migré d'un environnement de test vers une plateforme de production sans modification du code applicatif.

## 6. Analyse et justification des choix techniques
- **Pourquoi le 3-tiers ?** Ce découpage est crucial pour la sécurité. [cite_start]Il permet de placer la base de données dans un segment réseau protégé, empêchant toute attaque directe depuis Internet[cite: 48, 51].
- [cite_start]**Avantages de l'automatisation** : L'automatisation réduit les risques d'erreur humaine (configuration oubliée, version de dépendance incorrecte) et optimise les temps de rétablissement en cas de sinistre[cite: 53].
- **Limites de la solution** : Cette architecture actuelle est "monolithique" au niveau de ses instances (une seule VM par rôle). [cite_start]Pour une montée en charge massive, l'ajout d'un orchestrateur comme Kubernetes ou d'un cluster Nginx serait nécessaire pour gérer la haute disponibilité[cite: 55].

## 7. Conclusion
Ce projet illustre l'efficacité des pratiques DevOps modernes. La combinaison de Terraform et Ansible offre une agilité inégalée, transformant le déploiement de services complexes en une procédure standardisée et vérifiable. Cette infrastructure est prête à évoluer pour répondre aux besoins futurs de l'entreprise, tout en offrant une base stable et sécurisée.
