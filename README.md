# AlphaCare - Application Mobile pour la gestion des soins

## Description

Le backend de l'application **AlphaCare**, une solution IoT intelligente dédiée à la **santé et au suivi médical des bébés**. Ce backend gère l'authentification, les comptes utilisateurs (parents et médecins), les profils de bébés, les rendez-vous médicaux, ainsi que toutes les données de suivi de santé (température, poids, soins, etc.).

## Fonctionnalités principales

### Pour les Médecins :
- **Gestion du profil** : Création et mise à jour du profil médical.
- **Consultations à distance** : Accès aux rendez-vous programmés et possibilité de consultations à distance.
- **Suivi des patients** : Accès aux dossiers médicaux des patients et suivi des historiques médicaux.
- **Gestion des rendez-vous** : Prise en charge et mise à jour des horaires de consultation.

### Pour les Parents :
- **Création de compte** : Les parents peuvent créer un compte pour leur enfant et suivre leur santé.
- **Suivi de la santé de l'enfant** : Enregistrement et suivi des paramètres médicaux tels que la température, les allergies, etc.
- **Prise de rendez-vous** : Prendre des rendez-vous avec les médecins et suivre les consultations passées.
- **Notifications** : Recevoir des rappels pour les rendez-vous et les actions de suivi.

## Stack Technique

- **Frontend** : Flutter pour la création de l'application mobile, avec des interfaces optimisées pour les parents et les médecins.
- **Backend** : Node.js avec Express.js pour gérer la logique serveur et les API.
- **Base de données** : MongoDB pour stocker les données des utilisateurs (médecins et parents), les dossiers médicaux et les rendez-vous.

## Installation

### 1. Clone le dépôt

```bash
git clone [https://github.com/doosr/alphacare.git](https://github.com/doosr/backend-AlphaCare)
cd backend-AlphaCare
```

### 2. Installation des dépendances backend

Dans le répertoire du backend (`backend`), exécute les commandes suivantes :

```bash
cd backend
npm install
```

### 3. Lancer le serveur

```bash
npm start
```

Cela démarre le serveur Node.js, qui écoute les requêtes sur le port `3000` par défaut.

### 4. Installation des dépendances frontend

Dans le répertoire Flutter (`flutter_app`), exécute les commandes suivantes :

```bash
cd flutter_app
flutter pub get
```

### 5. Lancer l'application Flutter

```bash
flutter run
```

Cela démarre l'application mobile sur un émulateur ou un appareil physique.

## Configuration de MongoDB

1. Crée un cluster MongoDB sur [MongoDB Atlas](https://www.mongodb.com/cloud/atlas) ou configure MongoDB localement.
2. Ajoute tes informations de connexion à la base de données MongoDB dans le fichier `.env` du répertoire backend :

```env
MONGODB_URI=mongodb+srv://<username>:<password>@cluster0.mongodb.net/alphacare?retryWrites=true&w=majority
```

## Contribution

1. Fork le projet
2. Crée une branche pour ta fonctionnalité (`git checkout -b feature/ma-fonctionnalite`)
3. Commit tes changements (`git commit -m 'Ajout de la fonctionnalité X'`)
4. Pousse ta branche (`git push origin feature/ma-fonctionnalite`)
5. Ouvre une pull request

## Licence

Distribué sous la licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus de détails.
