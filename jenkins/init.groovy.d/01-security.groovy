import jenkins.model.*
import hudson.security.*

def instance = Jenkins.getInstance()

// Create admin user with password 'admin' and full rights
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount('Admin', 'admin')
instance.setSecurityRealm(hudsonRealm)

// Set up authorization strategy - Admin has all permissions
def authStrategy = new hudson.security.GlobalMatrixAuthorizationStrategy()
authStrategy.add(Jenkins.ADMINISTER, 'Admin')
instance.setAuthorizationStrategy(authStrategy)

// Disable signup
hudsonRealm.setAllowsSignup(false)

instance.save()

println "✅ Security configured:"
println "   - Admin user created (ID: Admin, password: admin)"
println "   - Admin has all rights"
println "   - User signup is disabled"
