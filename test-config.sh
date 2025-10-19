#!/bin/bash
# Quick test script for Whanos deployment

echo "╔═══════════════════════════════════════════╗"
echo "║      🔍 Whanos Configuration Test        ║"
echo "╚═══════════════════════════════════════════╝"
echo ""

cd ansible

echo "📋 1. Checking Ansible configuration..."
if [ -f "ansible.cfg" ]; then
    echo "✅ ansible.cfg found"
else
    echo "❌ ansible.cfg missing"
    exit 1
fi

echo ""
echo "📋 2. Checking inventory..."
if [ -f "inventories/production/hosts.yaml" ]; then
    echo "✅ hosts.yaml found"
else
    echo "❌ hosts.yaml missing"
    exit 1
fi

echo ""
echo "📋 3. Checking playbooks..."
for playbook in setup.yml deploy.yml teardown.yml; do
    if [ -f "playbooks/$playbook" ]; then
        echo "✅ $playbook found"
        echo "   Checking syntax..."
        ansible-playbook playbooks/$playbook --syntax-check 2>&1 | grep -q "playbook:" && echo "   ✅ Syntax OK" || echo "   ❌ Syntax error"
    else
        echo "❌ $playbook missing"
    fi
done

echo ""
echo "📋 4. Checking roles..."
for role in jenkins docker-registry kubernetes whanos-config; do
    if [ -d "roles/$role" ]; then
        echo "✅ Role $role found"
        [ -f "roles/$role/tasks/main.yml" ] && echo "   ✅ tasks/main.yml" || echo "   ❌ tasks/main.yml missing"
    else
        echo "❌ Role $role missing"
    fi
done

echo ""
echo "📋 5. Checking Docker images..."
cd ..
for lang in c java javascript python befunge; do
    if [ -f "images/$lang/Dockerfile.base" ] && [ -f "images/$lang/Dockerfile.standalone" ]; then
        echo "✅ $lang images found"
    else
        echo "❌ $lang images missing"
    fi
done

echo ""
echo "📋 6. Checking Jenkins files..."
for file in Jenkinsfile build-base-images.groovy link-project.groovy; do
    if [ -f "jenkins/$file" ]; then
        echo "✅ $file found"
    else
        echo "❌ $file missing"
    fi
done

echo ""
echo "╔═══════════════════════════════════════════╗"
echo "║         Configuration Test Complete       ║"
echo "╚═══════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "1. Update ansible/inventories/production/hosts.yaml with your server IPs"
echo "2. Update ansible/inventories/production/group_vars/all.yaml with passwords"
echo "3. Run: ./deploy.sh ping (to test connectivity)"
echo "4. Run: ./deploy.sh setup (to deploy infrastructure)"
