#!/bin/bash
# Whanos Deployment Helper Script

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ANSIBLE_DIR="${SCRIPT_DIR}/ansible"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_banner() {
    echo -e "${BLUE}"
    cat << "EOF"
╔═══════════════════════════════════════════╗
║         🐋 Whanos Deployment 🐋          ║
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

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check prerequisites
check_prereqs() {
    print_info "Checking prerequisites..."
    
    if ! command -v ansible &> /dev/null; then
        print_error "Ansible is not installed!"
        exit 1
    fi
    
    if ! command -v git &> /dev/null; then
        print_error "Git is not installed!"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Setup infrastructure
setup() {
    print_banner
    print_info "Starting Whanos infrastructure setup..."
    
    cd "${ANSIBLE_DIR}"
    
    ansible-playbook playbooks/setup.yml -v
    
    print_success "Infrastructure setup complete!"
}

# Deploy/Update infrastructure
deploy() {
    print_banner
    print_info "Deploying Whanos infrastructure..."
    
    cd "${ANSIBLE_DIR}"
    
    ansible-playbook playbooks/deploy.yml -v
    
    print_success "Deployment complete!"
}

# Teardown infrastructure
teardown() {
    print_banner
    print_warning "This will teardown the Whanos infrastructure!"
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_info "Teardown cancelled"
        exit 0
    fi
    
    cd "${ANSIBLE_DIR}"
    
    ansible-playbook playbooks/teardown.yml -v
    
    print_success "Teardown complete!"
}

# Check syntax
check() {
    print_info "Checking playbook syntax..."
    
    cd "${ANSIBLE_DIR}"
    
    ansible-playbook playbooks/setup.yml --syntax-check
    ansible-playbook playbooks/deploy.yml --syntax-check
    ansible-playbook playbooks/teardown.yml --syntax-check
    
    print_success "All playbooks are syntactically correct!"
}

# Ping all hosts
ping_hosts() {
    print_info "Pinging all hosts..."
    
    cd "${ANSIBLE_DIR}"
    
    ansible all -m ping
    
    print_success "All hosts responded!"
}

# Show help
show_help() {
    cat << EOF
Whanos Deployment Helper

Usage: $0 [command]

Commands:
    setup       Initial infrastructure setup
    deploy      Deploy/update infrastructure
    teardown    Remove infrastructure
    check       Check playbook syntax
    ping        Test connectivity to all hosts
    help        Show this help message

Examples:
    $0 setup     # Deploy infrastructure for the first time
    $0 deploy    # Update existing infrastructure
    $0 check     # Validate playbooks before running

EOF
}

# Main
main() {
    case "${1:-help}" in
        setup)
            check_prereqs
            setup
            ;;
        deploy)
            check_prereqs
            deploy
            ;;
        teardown)
            check_prereqs
            teardown
            ;;
        check)
            check_prereqs
            check
            ;;
        ping)
            check_prereqs
            ping_hosts
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
