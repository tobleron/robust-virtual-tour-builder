# 1881 VPS Security Hardening

## Objective
Apply comprehensive security hardening to the DigitalOcean VPS running the Robust Portal. This is a follow-up to T1877 (Portal HTTPS) and focuses on infrastructure-level security improvements.

## Required Changes

### 1. Firewall Configuration (UFW)
- [ ] Verify current UFW status: `ufw status verbose`
- [ ] Ensure only required ports are open:
  - `22/tcp (OpenSSH)` - SSH access
  - `80/tcp (Nginx HTTP)` - HTTPS redirect
  - `443/tcp (Nginx HTTPS)` - Portal access
- [ ] Deny all other incoming traffic by default
- [ ] Enable UFW if not already enabled: `ufw enable`
- [ ] Log denied connections: `ufw logging on`

### 2. SSH Hardening
- [ ] Verify SSH key-based authentication is working
- [ ] Disable password authentication in `/etc/ssh/sshd_config`:
  ```
  PasswordAuthentication no
  PermitRootLogin prohibit-password  # or 'no' if sudo user exists
  PubkeyAuthentication yes
  ```
- [ ] Disable root login (optional, after creating sudo user):
  ```
  PermitRootLogin no
  ```
- [ ] Change SSH port from 22 to non-standard port (optional, reduces automated attacks)
- [ ] Enable fail2ban for SSH brute-force protection:
  ```bash
  apt install fail2ban
  systemctl enable fail2ban
  systemctl start fail2ban
  ```
- [ ] Configure fail2ban SSH jail in `/etc/fail2ban/jail.local`:
  ```
  [sshd]
  enabled = true
  bantime = 1h
  maxretry = 5
  ```

### 3. User & Permission Audit
- [ ] Create dedicated sudo user for operations (if not exists):
  ```bash
  adduser robustadmin
  usermod -aG sudo robustadmin
  ```
- [ ] Verify file ownership:
  - `/var/lib/robust-vtb` → `robustvtb:robustvtb`
  - `/var/log/robust-vtb` → `robustvtb:robustvtb`
  - `/opt/robust-vtb/bin` → `root:root` (755)
  - `/opt/robust-vtb/current` → mixed (source: 501:staff, cache: robustvtb:robustvtb)
- [ ] Ensure `robustvtb` user has minimal privileges (no sudo, no login shell if possible)

### 4. Automatic Security Updates
- [ ] Enable unattended security updates:
  ```bash
  apt install unattended-upgrades
  dpkg-reconfigure --priority=low unattended-upgrades
  ```
- [ ] Configure update schedule in `/etc/apt/apt.conf.d/20auto-upgrades`:
  ```
  APT::Periodic::Update-Package-Lists "1";
  APT::Periodic::Unattended-Upgrade "1";
  ```

### 5. Monitoring & Logging
- [ ] Verify rsyslog is running: `systemctl status rsyslog`
- [ ] Configure log rotation for portal logs in `/etc/logrotate.d/robust-vtb`
- [ ] Set up basic monitoring (optional):
  - Install `htop`, `iotop`, `nethogs` for troubleshooting
  - Consider `prometheus-node-exporter` for metrics collection

### 6. Database Security
- [ ] Verify SQLite database permissions: `chmod 640 /var/lib/robust-vtb/database.db`
- [ ] Ensure database directory is not world-readable
- [ ] Consider enabling SQLite WAL mode for better concurrency

### 7. Backup Strategy
- [ ] Set up automated database backups:
  ```bash
  # /etc/cron.daily/robust-vtb-backup
  #!/bin/bash
  cp /var/lib/robust-vtb/database.db /var/backups/robust-vtb/db-$(date +%Y%m%d).db
  find /var/backups/robust-vtb -mtime +30 -delete
  ```
- [ ] Test backup restoration procedure
- [ ] Document backup location and restoration steps

## Verification
- [ ] `ufw status` shows only required ports open
- [ ] SSH password authentication is disabled (test from separate session!)
- [ ] fail2ban is active: `fail2ban-client status sshd`
- [ ] Unattended upgrades are configured: `cat /etc/apt/apt.conf.d/20auto-upgrades`
- [ ] All portal functionality still works after hardening
- [ ] Admin can still SSH and manage the server
- [ ] Backup restoration tested successfully

## Notes
- **CRITICAL**: Test SSH changes in a separate session before closing current connection
- Do not lock yourself out of the server
- Document all changes in a runbook for future reference
- This task is portal-only; builder VPS hardening is separate
- Priority: Firewall and SSH hardening are highest priority
- Monitoring and backups are nice-to-have for current scale

## Dependencies
- T1877 (Portal HTTPS) - COMPLETED
- Portal is stable and functional on HTTPS
