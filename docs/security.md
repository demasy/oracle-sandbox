# Security Policy

## 🔒 Security Overview

This project is designed for **development, training, and evaluation purposes only**. It is not intended for production use. We take security seriously and appreciate the community's help in identifying and addressing vulnerabilities.

---

## 🚨 Reporting a Vulnerability

If you discover a security vulnerability in this project, please help us maintain a safe environment by reporting it responsibly.

### How to Report

**Email:** founder@demasy.io

**Subject Line:** `[SECURITY] Oracle Sandbox Vulnerability Report`

**Please Include:**
- Description of the vulnerability
- Steps to reproduce the issue
- Potential impact assessment
- Any suggested fixes or mitigations (if available)
- Your contact information for follow-up

### What to Expect

1. **Acknowledgment:** We will acknowledge receipt of your report within **48 hours**
2. **Assessment:** We will investigate and assess the severity within **5 business days**
3. **Resolution:** Critical issues will be prioritized and addressed in upcoming releases
4. **Credit:** With your permission, we will acknowledge your contribution in release notes

### Please Do Not

- Publicly disclose the vulnerability before we've had a chance to address it
- Exploit the vulnerability beyond what's necessary to demonstrate it
- Access, modify, or delete data belonging to others

---

## 🛡️ Security Best Practices

### Before First Use

1. **Change ALL Default Passwords**
   ```bash
   # Edit .env file with strong passwords
   ENV_DB_PASSWORD=YourSecurePassword123!
   ENV_APEX_ADMIN_PASSWORD=YourSecureAPEXPassword123!
   ```

2. **Use Strong Passwords**
   - Minimum 12 characters
   - Mix uppercase, lowercase, numbers, and symbols
   - Avoid dictionary words and common patterns

3. **Never Commit Secrets**
   - `.env` file is already in `.gitignore`
   - Never commit credentials to version control
   - Use `.env.example` as a template only

4. **Restrict Network Access**
   - Bind services to `localhost` for local-only access
   - Use firewall rules to restrict container access
   - Consider VPN for remote access to development environment

5. **Keep Software Updated**
   - Regularly pull latest Oracle Database images
   - Update APEX, ORDS, and SQLcl versions
   - Monitor security advisories from Oracle

### Environment Isolation

```bash
# This project is NOT for production use
# For production deployments:
# - Consult Oracle's security guidelines
# - Work with Oracle Support or certified partners
# - Implement proper security hardening
# - Use Oracle's production-grade deployment architectures
```

---

## 🔐 Known Limitations

### Development Environment Only

This environment is **intentionally simplified** for development and learning:

- ❌ **No TLS/SSL encryption** between services
- ❌ **Default passwords** must be changed by users
- ❌ **No audit logging** or security monitoring
- ❌ **No network segmentation** beyond Docker networks
- ❌ **No intrusion detection** systems
- ❌ **No backup/recovery** mechanisms
- ⚠️ **Containers run as root** (future enhancement planned)

### Security Features Not Included

- Enterprise authentication (LDAP/Active Directory)
- Advanced encryption (TDE, network encryption)
- Database Vault or Label Security
- Automatic security patching
- DDoS protection or rate limiting
- Web Application Firewall (WAF)

---

## ✅ What We Do

### Security Measures in Place

- ✅ Environment variables for all sensitive data
- ✅ `.env` file excluded from version control
- ✅ HTTPS URLs for all external downloads
- ✅ No hardcoded credentials in source code
- ✅ Secure file permissions (no `chmod 777`)
- ✅ Custom isolated Docker network
- ✅ Health checks and resource limits
- ✅ Regular security audits before releases

### Continuous Improvement

We regularly:
- Scan for hardcoded secrets
- Review file permissions
- Audit environment variable usage
- Check for insecure dependencies
- Update base Docker images
- Review community security feedback

---

## 📋 Security Checklist for Users

### Initial Setup
- [ ] Copy `.env.example` to `.env`
- [ ] Change all default passwords
- [ ] Update email addresses
- [ ] Review network configuration
- [ ] Verify `.env` is not committed to git

### Regular Maintenance
- [ ] Update Docker images monthly
- [ ] Review container logs for anomalies
- [ ] Monitor resource usage
- [ ] Keep host system patched
- [ ] Review access logs

### Before Sharing
- [ ] Remove any real data from containers
- [ ] Reset to default configuration
- [ ] Verify no credentials in scripts
- [ ] Check `.env` is gitignored
- [ ] Document any custom modifications

---

## 🔗 Resources

### Oracle Security Resources
- [Oracle Database Security Guide](https://docs.oracle.com/en/database/oracle/oracle-database/)
- [APEX Security Best Practices](https://apex.oracle.com/security)
- [Docker Security Documentation](https://docs.docker.com/engine/security/)

### Security Tools
- [Git-secrets](https://github.com/awslabs/git-secrets) - Prevent committing secrets
- [TruffleHog](https://github.com/trufflesecurity/trufflehog) - Find credentials in git history
- [Docker Bench](https://github.com/docker/docker-bench-security) - Security audit for Docker

---

## 📞 Contact

**Security Issues:** founder@demasy.io  
**GitHub:** [@demasy](https://github.com/demasy)  
**Repository:** [oracle-sandbox](https://github.com/demasy/oracle-sandbox)

---

## 📜 Responsible Disclosure

We follow responsible disclosure practices and ask that security researchers do the same. We commit to:

- Acknowledging reports promptly
- Keeping you informed of our progress
- Crediting researchers (with permission)
- Releasing fixes in a timely manner

Thank you for helping keep the Oracle Sandbox project secure! 🙏

---

**Last Updated:** December 3, 2025  
**Version:** 1.0.0
