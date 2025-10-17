# Docker Compose Setup pour Watermark App

Ce projet utilise Docker Compose pour déployer l'application Watermark avec le domaine `img.floalz.fr`.

## Architecture

- **Backend**: FastAPI (Python) sur le port 8000
- **Frontend**: Angular avec Nginx sur le port 80
- **Reverse Proxy**: Nginx principal sur les ports 80/443
- **Domaine**: img.floalz.fr

## Prérequis

1. Docker et Docker Compose installés
2. OpenSSL installé (pour générer les certificats SSL)
3. Le domaine `img.floalz.fr` pointant vers votre serveur

## Installation et Déploiement

### 🚀 Déploiement automatique (Recommandé)

**Sur Linux/Mac :**
```bash
chmod +x deploy.sh
./deploy.sh
```

**Sur Windows :**
```cmd
deploy.bat
```

### 🔧 Déploiement manuel

#### 1. Configuration des variables d'environnement

```bash
# Copier le fichier d'exemple
cp env.example .env

# Modifier les variables si nécessaire
nano .env
```

Variables disponibles :
- `ENV=prod` - Environnement (dev/prod)
- `LOGGING_LEVEL=INFO` - Niveau de logs
- `PROD_CORS_ORIGINS=https://img.floalz.fr` - Origines CORS autorisées
- `API_URL=https://img.floalz.fr/api/` - URL de l'API pour le frontend

#### 2. Générer les certificats SSL

**Pour le développement (certificats auto-signés):**
```bash
# Les certificats sont générés automatiquement par le script de déploiement
```

**Pour la production (Let's Encrypt):**
```bash
# Installer certbot
sudo apt-get install certbot

# Générer les certificats
sudo certbot certonly --webroot -w /var/www/html -d img.floalz.fr

# Copier les certificats
sudo cp /etc/letsencrypt/live/img.floalz.fr/fullchain.pem nginx/ssl/cert.pem
sudo cp /etc/letsencrypt/live/img.floalz.fr/privkey.pem nginx/ssl/key.pem
```

#### 3. Configuration DNS

Assurez-vous que le domaine `img.floalz.fr` pointe vers l'IP de votre serveur :
```
A    img.floalz.fr    -> VOTRE_IP_SERVEUR
```

#### 4. Déploiement

```bash
# Construire et démarrer tous les services
docker-compose up -d --build

# Vérifier le statut
docker-compose ps

# Voir les logs
docker-compose logs -f
```

### 4. Accès à l'application

- **Frontend**: https://img.floalz.fr
- **API**: https://img.floalz.fr/api/

## Commandes utiles

```bash
# Arrêter les services
docker-compose down

# Redémarrer un service spécifique
docker-compose restart backend

# Voir les logs d'un service
docker-compose logs -f backend

# Mettre à jour l'application
docker-compose down
docker-compose up -d --build
```

## Configuration

### Variables d'environnement

Vous pouvez créer un fichier `.env` pour personnaliser la configuration :

```env
# Backend
PYTHONUNBUFFERED=1

# Nginx
NGINX_WORKER_PROCESSES=auto
```

### Sécurité

- Rate limiting configuré pour l'API
- Headers de sécurité activés
- HTTPS forcé avec redirection HTTP
- CORS configuré pour le domaine

### Monitoring

```bash
# Vérifier les logs nginx
docker-compose logs nginx

# Vérifier les logs backend
docker-compose logs backend

# Vérifier les logs frontend
docker-compose logs frontend
```

## Dépannage

### Problèmes courants

1. **Erreur de certificat SSL** : Vérifiez que les certificats sont présents dans `nginx/ssl/`
2. **Service non accessible** : Vérifiez que le DNS pointe vers votre serveur
3. **Erreur de build** : Vérifiez que tous les fichiers Dockerfile sont présents

### Logs utiles

```bash
# Logs complets
docker-compose logs

# Logs nginx
docker-compose logs nginx

# Logs avec timestamps
docker-compose logs -t
```

## Production

Pour la production, assurez-vous de :

1. Utiliser des certificats SSL valides (Let's Encrypt)
2. Configurer un firewall approprié
3. Mettre en place une surveillance des logs
4. Configurer des sauvegardes
5. Utiliser des secrets Docker pour les données sensibles
