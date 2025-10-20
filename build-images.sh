#!/bin/bash
# Quick script to build all Whanos base images locally

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

REGISTRY="localhost:5000"

echo -e "${BLUE}Building Whanos Base Images...${NC}"
echo ""

cd images

for lang in c java javascript python befunge; do
    echo -e "${BLUE}Building whanos-$lang...${NC}"
    docker build -t ${REGISTRY}/whanos-$lang:latest -f $lang/Dockerfile.base $lang/
    docker push ${REGISTRY}/whanos-$lang:latest
    echo -e "${GREEN}✅ whanos-$lang built and pushed${NC}"
    echo ""
done

echo -e "${GREEN}All base images built successfully!${NC}"
echo ""
echo "Images in registry:"
curl -s http://localhost:5000/v2/_catalog | jq '.'
