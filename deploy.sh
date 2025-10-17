#!/bin/bash

# Script de déploiement pour serveur Linux
# Usage: ./deploy.sh [--force] [--no-build]

set -e

# Configuration
PROJECT_NAME="watermark"
COMPOSE_FILE="docker-compose.yml"
ENV_FILE=".env"

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction de logging
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Vérification des prérequis
check_prerequisites() {
    log "Vérification des prérequis..."
    
    # Vérifier Docker
    if ! command -v docker &> /dev/null; then
        error "Docker n'est pas installé"
    fi
    
    # Vérifier Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        error "Docker Compose n'est pas installé"
    fi
    
    # Vérifier le fichier docker-compose.yml
    if [ ! -f "$COMPOSE_FILE" ]; then
        error "Fichier $COMPOSE_FILE introuvable"
    fi
    
    # Vérifier le fichier .env
    if [ ! -f "$ENV_FILE" ]; then
        warn "Fichier $ENV_FILE introuvable, création d'un fichier par défaut"
        create_default_env
    fi
    
    log "Prérequis validés"
}

# Créer un fichier .env par défaut
create_default_env() {
    cat > "$ENV_FILE" << EOF
# Environment Configuration
ENV=prod

# CORS Configuration
PROD_CORS_ORIGINS=https://img.floalz.fr

# Logging Configuration
LOGGING_LEVEL=INFO

# Port Configuration
HTTP_PORT=80
HTTPS_PORT=443
EOF
    log "Fichier $ENV_FILE créé avec les valeurs par défaut"
}

# Vérifier les certificats SSL
check_ssl_certificates() {
    log "Vérification des certificats SSL..."
    
    if [ ! -d "nginx/ssl" ]; then
        warn "Répertoire nginx/ssl introuvable, création..."
        mkdir -p nginx/ssl
    fi
    
    if [ ! -f "nginx/ssl/cert.pem" ] || [ ! -f "nginx/ssl/key.pem" ]; then
        warn "Certificats SSL manquants dans nginx/ssl/"
        warn "Vous devez placer vos certificats cert.pem et key.pem dans nginx/ssl/"
        warn "L'application fonctionnera en HTTP uniquement sans certificats SSL"
    else
        log "Certificats SSL trouvés"
    fi
}

# Nettoyer les anciens conteneurs
cleanup_old_containers() {
    log "Nettoyage des anciens conteneurs..."
    
    # Arrêter les conteneurs existants
    if docker-compose -f "$COMPOSE_FILE" ps -q | grep -q .; then
        log "Arrêt des conteneurs existants..."
        docker-compose -f "$COMPOSE_FILE" down
    fi
    
    # Nettoyer les images inutilisées
    log "Nettoyage des images inutilisées..."
    docker image prune -f
}

# Construire les images
build_images() {
    if [ "$1" != "--no-build" ]; then
        log "Construction des images Docker..."
        docker-compose -f "$COMPOSE_FILE" build --no-cache
    else
        log "Construction des images ignorée (--no-build)"
    fi
}

# Démarrer les services
start_services() {
    log "Démarrage des services..."
    docker-compose -f "$COMPOSE_FILE" up -d
    
    # Attendre que les services soient prêts
    log "Attente du démarrage des services..."
    sleep 10
    
    # Vérifier le statut des services
    if docker-compose -f "$COMPOSE_FILE" ps | grep -q "Up"; then
        log "Services démarrés avec succès"
    else
        error "Échec du démarrage des services"
    fi
}

# Vérifier le statut des services
check_services_status() {
    log "Vérification du statut des services..."
    
    # Attendre que les services soient prêts
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if docker-compose -f "$COMPOSE_FILE" ps | grep -q "Up"; then
            log "Tous les services sont démarrés"
            return 0
        fi
        
        attempt=$((attempt + 1))
        log "Tentative $attempt/$max_attempts - Attente du démarrage des services..."
        sleep 10
    done
    
    warn "Certains services ne sont pas encore démarrés"
    docker-compose -f "$COMPOSE_FILE" ps
}

# Afficher les informations de déploiement
show_deployment_info() {
    log "Déploiement terminé avec succès"
    echo ""
    echo "=== Informations de déploiement ==="
    echo "Services déployés:"
    docker-compose -f "$COMPOSE_FILE" ps
    echo ""
    echo "Logs des services:"
    echo "  docker-compose logs -f"
    echo ""
    echo "Arrêter les services:"
    echo "  docker-compose down"
    echo ""
    echo "Redémarrer un service:"
    echo "  docker-compose restart <service_name>"
    echo ""
}

# Fonction principale
main() {
    local force_rebuild=false
    local no_build=false
    
    # Analyser les arguments
    for arg in "$@"; do
        case $arg in
            --force)
                force_rebuild=true
                ;;
            --no-build)
                no_build=true
                ;;
            *)
                echo "Usage: $0 [--force] [--no-build]"
                echo "  --force     Force la reconstruction même si des conteneurs existent"
                echo "  --no-build  Ignore la construction des images"
                exit 1
                ;;
        esac
    done
    
    log "Début du déploiement de $PROJECT_NAME"
    
    check_prerequisites
    check_ssl_certificates
    
    if [ "$force_rebuild" = true ]; then
        cleanup_old_containers
    fi
    
    build_images $no_build
    start_services
    check_services_status
    show_deployment_info
    
    log "Déploiement terminé avec succès"
}

# Exécuter le script
main "$@"
