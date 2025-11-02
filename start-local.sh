#!/bin/bash
# Whanos Local Setup Script

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_banner() {
    echo -e "${BLUE}"
    cat << "EOF"
╔═══════════════════════════════════════════╗
║      🐋 Whanos Local Setup 🐋           ║
║      Docker + Jenkins + Registry         ║
╚═══════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

check_docker() {
    print_info "Checking Docker..."
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed!"
        echo "Please install Docker: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running!"
        echo "Please start Docker and try again."
        exit 1
    fi
    
    print_success "Docker is ready"
}

check_docker_compose() {
    print_info "Checking Docker Compose..."
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not installed!"
        echo "Please install Docker Compose: https://docs.docker.com/compose/install/"
        exit 1
    fi
    print_success "Docker Compose is ready"
}

check_kubectl() {
    print_info "Checking kubectl..."
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed (optional for local setup)"
        echo "For Kubernetes deployment, install kubectl: https://kubernetes.io/docs/tasks/tools/"
    else
        print_success "kubectl is ready"
    fi
}

start_infrastructure() {
    print_banner
    print_info "Building custom Jenkins image..."
    
    # Build Jenkins image with plugins and init scripts
    if command -v docker-compose &> /dev/null; then
        docker-compose build jenkins
    else
        docker compose build jenkins
    fi
    
    print_success "Jenkins image built!"
    
    print_info "Starting Whanos infrastructure..."
    
    # Start services
    if command -v docker-compose &> /dev/null; then
        docker-compose up -d
    else
        docker compose up -d
    fi
    
    print_success "Infrastructure started!"
    echo ""
    print_info "Waiting for services to be ready..."
    sleep 10
    
    # Wait for Jenkins
    echo -n "Waiting for Jenkins..."
    until curl -s http://localhost:8080 > /dev/null 2>&1; do
        echo -n "."
        sleep 5
    done
    echo ""
    print_success "Jenkins is ready!"
    
    # Wait for Registry
    echo -n "Waiting for Docker Registry..."
    until curl -s http://localhost:5000/v2/ > /dev/null 2>&1; do
        echo -n "."
        sleep 2
    done
    echo ""
    print_success "Docker Registry is ready!"
}

get_jenkins_password() {
    print_info "Getting Jenkins initial admin password..."
    sleep 5
    
    PASSWORD=$(docker exec whanos-jenkins cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null || echo "Not ready yet")
    
    if [ "$PASSWORD" != "Not ready yet" ]; then
        echo ""
        echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║       Jenkins Initial Admin Password:                 ║${NC}"
        echo -e "${GREEN}║       ${PASSWORD}                        ║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
        echo ""
    else
        print_info "Jenkins is still starting, run this to get password later:"
        echo "docker exec whanos-jenkins cat /var/jenkins_home/secrets/initialAdminPassword"
    fi
}

install_docker_in_jenkins() {
    print_info "Installing Docker CLI in Jenkins container..."
    
    docker exec -u root whanos-jenkins bash -c "
        apt-get update -qq && \
        apt-get install -y -qq docker.io curl && \
        usermod -aG docker jenkins && \
        curl -LO https://dl.k8s.io/release/\$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl && \
        chmod +x kubectl && \
        mv kubectl /usr/local/bin/
    " > /dev/null 2>&1
    
    print_success "Docker CLI installed in Jenkins"
}

configure_docker_registry() {
    print_info "Configuring insecure registry..."
    
    # Add registry to Docker daemon config
    DOCKER_CONFIG="/etc/docker/daemon.json"
    
    if [ -f "$DOCKER_CONFIG" ]; then
        print_info "Docker daemon.json already exists, please add manually:"
        echo '  "insecure-registries": ["localhost:5000"]'
    else
        print_info "You may need to configure insecure registry manually"
        echo "Add to /etc/docker/daemon.json:"
        echo '{'
        echo '  "insecure-registries": ["localhost:5000"]'
        echo '}'
        echo "Then restart Docker"
    fi
}

show_info() {
    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║              🎉 Whanos is Ready! 🎉                          ║${NC}"
    echo -e "${BLUE}╠═══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${BLUE}║                                                               ║${NC}"
    echo -e "${BLUE}║  📦 Docker Registry:  http://localhost:5000                  ║${NC}"
    echo -e "${BLUE}║  🔧 Jenkins:          http://localhost:8080                  ║${NC}"
    echo -e "${BLUE}║                                                               ║${NC}"
    echo -e "${BLUE}║  Next steps:                                                  ║${NC}"
    echo -e "${BLUE}║  1. Open Jenkins at http://localhost:8080                    ║${NC}"
    echo -e "${BLUE}║  2. Use the password shown above                             ║${NC}"
    echo -e "${BLUE}║  3. Install suggested plugins                                ║${NC}"
    echo -e "${BLUE}║  4. Create admin user                                        ║${NC}"
    echo -e "${BLUE}║  5. Create jobs manually or use Job DSL                      ║${NC}"
    echo -e "${BLUE}║                                                               ║${NC}"
    echo -e "${BLUE}║  Useful commands:                                             ║${NC}"
    echo -e "${BLUE}║  - Stop:     docker-compose down                             ║${NC}"
    echo -e "${BLUE}║  - Restart:  docker-compose restart                          ║${NC}"
    echo -e "${BLUE}║  - Logs:     docker-compose logs -f                          ║${NC}"
    echo -e "${BLUE}║  - Status:   docker-compose ps                               ║${NC}"
    echo -e "${BLUE}║                                                               ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

stop_infrastructure() {
    print_info "Stopping Whanos infrastructure..."
    
    if command -v docker-compose &> /dev/null; then
        docker-compose down
    else
        docker compose down
    fi
    
    print_success "Infrastructure stopped!"
}

clean_infrastructure() {
    print_info "Cleaning Whanos infrastructure (removing volumes)..."
    
    if command -v docker-compose &> /dev/null; then
        docker-compose down -v
    else
        docker compose down -v
    fi
    
    print_success "Infrastructure cleaned!"
}

main() {
    case "${1:-start}" in
        start)
            check_docker
            check_docker_compose
            check_kubectl
            start_infrastructure
            install_docker_in_jenkins
            get_jenkins_password
            configure_docker_registry
            show_info
            ;;
        stop)
            stop_infrastructure
            ;;
        clean)
            clean_infrastructure
            ;;
        restart)
            stop_infrastructure
            sleep 2
            start_infrastructure
            show_info
            ;;
        logs)
            if command -v docker-compose &> /dev/null; then
                docker-compose logs -f
            else
                docker compose logs -f
            fi
            ;;
        status)
            if command -v docker-compose &> /dev/null; then
                docker-compose ps
            else
                docker compose ps
            fi
            ;;
        password)
            docker exec whanos-jenkins cat /var/jenkins_home/secrets/initialAdminPassword
            ;;
        *)
            echo "Usage: $0 {start|stop|restart|clean|logs|status|password}"
            echo ""
            echo "Commands:"
            echo "  start    - Start Whanos infrastructure"
            echo "  stop     - Stop Whanos infrastructure"
            echo "  restart  - Restart Whanos infrastructure"
            echo "  clean    - Stop and remove all data"
            echo "  logs     - Show logs"
            echo "  status   - Show status"
            echo "  password - Show Jenkins admin password"
            exit 1
            ;;
    esac
}

main "$@"
