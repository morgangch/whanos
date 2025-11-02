import jenkins.model.*
import hudson.security.*
import org.jenkinsci.plugins.matrixauth.inheritance.*

def instance = Jenkins.getInstance()

// Create admin user with password 'admin' and full rights
// Pass false to constructor to disable signup
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount('Admin', 'admin')
instance.setSecurityRealm(hudsonRealm)

// Set up authorization strategy - Admin has all permissions
def strategy = new GlobalMatrixAuthorizationStrategy()
strategy.add(Jenkins.ADMINISTER, 'Admin')
instance.setAuthorizationStrategy(strategy)

instance.save()

println "✅ Security configured:"
println "   - Admin user created (ID: Admin, password: admin)"
println "   - Admin has all rights"
println "   - User signup is disabled (realm configured with allowsSignup=false)"
