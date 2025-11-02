#!/bin/bash
# Script to verify Jenkins configuration

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

JENKINS_URL="http://localhost:8080"
JENKINS_USER="Admin"
JENKINS_PASSWORD="admin"

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_header() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════╗"
    echo "║   🔍 Jenkins Configuration Check         ║"
    echo "╚═══════════════════════════════════════════╝"
    echo -e "${NC}"
}

check_jenkins_running() {
    print_info "Checking if Jenkins is running..."
    if curl -s "${JENKINS_URL}" > /dev/null 2>&1; then
        print_success "Jenkins is running"
        return 0
    else
        print_error "Jenkins is not accessible at ${JENKINS_URL}"
        return 1
    fi
}

check_auth() {
    print_info "Checking authentication..."
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -u "${JENKINS_USER}:${JENKINS_PASSWORD}" "${JENKINS_URL}/api/json")
    
    if [ "$HTTP_CODE" = "200" ]; then
        print_success "Authentication successful (Admin user configured)"
        return 0
    else
        print_error "Authentication failed (HTTP ${HTTP_CODE})"
        return 1
    fi
}

check_folder() {
    local folder_name="$1"
    local encoded_name=$(echo "$folder_name" | sed 's/ /%20/g')
    
    print_info "Checking folder: ${folder_name}..."
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -u "${JENKINS_USER}:${JENKINS_PASSWORD}" \
        "${JENKINS_URL}/job/${encoded_name}/api/json")
    
    if [ "$HTTP_CODE" = "200" ]; then
        print_success "Folder '${folder_name}' exists"
        return 0
    else
        print_error "Folder '${folder_name}' not found (HTTP ${HTTP_CODE})"
        return 1
    fi
}

check_job() {
    local job_path="$1"
    local encoded_path=$(echo "$job_path" | sed 's/ /%20/g')
    
    print_info "Checking job: ${job_path}..."
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -u "${JENKINS_USER}:${JENKINS_PASSWORD}" \
        "${JENKINS_URL}/job/${encoded_path}/api/json")
    
    if [ "$HTTP_CODE" = "200" ]; then
        print_success "Job '${job_path}' exists"
        return 0
    else
        print_error "Job '${job_path}' not found (HTTP ${HTTP_CODE})"
        return 1
    fi
}

list_jobs_in_folder() {
    local folder_name="$1"
    local encoded_name=$(echo "$folder_name" | sed 's/ /%20/g')
    
    print_info "Jobs in '${folder_name}':"
    curl -s -u "${JENKINS_USER}:${JENKINS_PASSWORD}" \
        "${JENKINS_URL}/job/${encoded_name}/api/json?tree=jobs[name]" | \
        python3 -c "import sys, json; jobs = json.load(sys.stdin).get('jobs', []); [print(f\"  - {job['name']}\") for job in jobs]" 2>/dev/null || \
        echo "  Could not list jobs"
}

print_header

# Check Jenkins is running
if ! check_jenkins_running; then
    echo ""
    echo "Please start Jenkins with: ./start-local.sh"
    exit 1
fi

echo ""
echo "Waiting for Jenkins to be fully ready..."
sleep 5

# Check authentication
check_auth

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Checking Folder Structure"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

check_folder "Whanos base images"
check_folder "Projects"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Checking Base Image Jobs"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

check_job "Whanos base images/whanos-c"
check_job "Whanos base images/whanos-java"
check_job "Whanos base images/whanos-javascript"
check_job "Whanos base images/whanos-python"
check_job "Whanos base images/whanos-befunge"
check_job "Whanos base images/Build all base images"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Checking Root Jobs"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

check_job "link-project"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Jobs Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

list_jobs_in_folder "Whanos base images"
echo ""
list_jobs_in_folder "Projects"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_success "Configuration check complete!"
echo ""
print_info "Jenkins URL: ${JENKINS_URL}"
print_info "Username: ${JENKINS_USER}"
print_info "Password: ${JENKINS_PASSWORD}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
