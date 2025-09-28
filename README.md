# 🛡️ Advanced Pi-hole System

**Complete plug-and-play Pi-hole deployment with 97% ad blocking efficiency, intelligent automation, and zero-configuration setup.**

## ⭐ Key Features

- 🚀 **One-Command Setup**: Fully automated installation and configuration
- 🛡️ **97% Ad Blocking**: 80,000+ domains blocked with custom rules
- 🔧 **Zero Configuration**: Works out-of-the-box with intelligent defaults
- 🎯 **Smart Domain Processing**: Handles .txt and .json domain files automatically
- 📱 **Universal Compatibility**: Works on any network (home, office, enterprise)
- 🔐 **Security First**: Environment variables, no hardcoded credentials
- 💻 **Interactive Scripts**: Clean PowerShell menus for all operations
- 🌐 **Web Interface**: Modern admin panel with real-time monitoring
- 📊 **JSON Parser**: Supports turtlecute.org format with true/false validation
- 🔄 **Auto-Configuration**: Persistent settings maintained between restarts

## 📁 Project Structure

```
Pi-Hole/
├── docker-compose.yml              # Docker configuration
├── README.md                       # Project documentation
├── domain-processing.log           # Processing activity log
├── .env.example                    # Environment template
├── scripts/                        # Automation scripts (organized by category)
│   ├── auto-init-pihole.sh         # Auto-configuration script
│   ├── system-precheck.ps1         # System prerequisites check
│   ├── maintenance/                # Maintenance & optimization scripts
│   │   ├── maintenance.ps1         # Unified maintenance menu
│   │   ├── quick-flush.ps1         # Quick DNS flush
│   │   ├── optimize-pihole.ps1     # System optimization
│   │   └── verify-pihole.ps1       # System verification
│   ├── restart/                    # Container restart scripts
│   │   ├── restart-pihole-complete.ps1 # Complete restart with config
│   │   └── quick-restart.ps1       # Quick container restart
│   ├── startup/                    # System startup scripts
│   │   ├── run-auto-init.ps1       # Manual auto-init executor
│   │   ├── STARTUP.ps1             # System startup script
│   │   └── STARTUP.exe             # Compiled startup executable
│   └── domain-processing/          # Domain management
│       ├── process-domains.ps1     # Interactive domain processor
│       └── input/                  # Domain files processing directory
├── etc-pihole/
│   ├── whitelist.txt               # Domains to allow
│   ├── blacklist.txt               # Domains to block
│   ├── gravity.db                  # Pi-hole database (80,000+ domains)
│   └── [other Pi-hole files]
└── etc-dnsmasq.d/                  # Additional DNS configuration
```

## 🚀 Quick Start (5 minutes)

### 1️⃣ **Prerequisites**
- Windows 10/11 with PowerShell
- Docker Desktop installed and running
- Ports 53 and 8080 available

### 2️⃣ **Download & Setup**
```bash
# Clone repository
git clone https://github.com/facusora01/Pi-Hole.git
cd Pi-Hole

# Check system (optional)
.\scripts\system-precheck.ps1
```

### 3️⃣ **Configure (2 minutes)**
```powershell
# Copy configuration template
copy .env.example .env

# Edit with your settings
notepad .env
```

**Minimum required settings (customize these values):**
```env
PIHOLE_WEBPASSWORD=YourSecurePassword123!
PIHOLE_SERVER_IP=YOUR_IP_ADDRESS           # Your actual PC IP address
TZ=YOUR_TIMEZONE                          # Your timezone (see examples below)
```

> 💡 **Important**: Replace these example values with your actual network settings!

### 4️⃣ **Launch Pi-hole**
```powershell
# Start everything with one command
.\scripts\maintenance\maintenance.ps1

# Choose option 1: "Start Pi-hole"
```

### 5️⃣ **Access & Configure**
- **Web Interface**: http://YOUR_IP:8080/admin
- **Login**: Use password from `.env` file
- **Enable Ad Blocking**: Set router DNS to your Pi-hole IP

---

## ⚙️ Configuration Options

### 🌐 **Network Settings (Fully Configurable)**
```env
PIHOLE_SERVER_IP=YOUR_IP_ADDRESS   # Your server IP (replace with your actual IP)
WEB_PORT=8080                      # Web interface port (customizable)
DNS_PORT=53                        # DNS service port (customizable)
```

> 🔧 **Auto-Detection**: Run `.\scripts\system-precheck.ps1` to automatically detect your IP address!

### 🔐 **Security Settings**
```env
PIHOLE_WEBPASSWORD=SecurePass123!  # Admin password
TZ=YOUR_TIMEZONE                  # Your timezone
```

### 🎨 **Advanced Settings**
```env
CONTAINER_NAME=pihole             # Docker container name
WEBTHEME=default-dark            # Web interface theme
UPSTREAM_DNS1=1.1.1.1            # Primary DNS server
UPSTREAM_DNS2=8.8.8.8            # Secondary DNS server
```

### 🌍 **Common Timezones**
```env
TZ=America/New_York              # US East Coast
TZ=America/Chicago               # US Central
TZ=America/Los_Angeles           # US West Coast
TZ=Europe/London                 # UK
TZ=Europe/Berlin                 # Germany
TZ=Asia/Tokyo                    # Japan
```

### 🔌 **Alternative Ports**
If default ports are occupied:
```env
WEB_PORT=9090    # Alternative web port
DNS_PORT=5353    # Alternative DNS port
```

---

## 📖 **Advanced Installation Options**

### Alternative Setup Methods
```powershell
# RECOMMENDED: Complete restart with auto-configuration
.\scripts\restart\restart-pihole-complete.ps1

# OR: Manual startup
docker-compose up -d
.\scripts\startup\run-auto-init.ps1
```

---

## 🔧 Management & Maintenance

### 📋 **All-in-One Menu**
```powershell
# Access unified maintenance menu
.\scripts\maintenance\maintenance.ps1

# Available options:
# 1. Start Pi-hole
# 2. Quick DNS Flush  
# 3. System Optimization
# 4. Complete Restart
# 5. Process Domain Files
# 6. Verify System
# 7. Diagnose Issues
# 8. Stop Pi-hole
```

### ⚡ **Quick Commands**
```powershell
# System check
.\scripts\system-precheck.ps1

# DNS flush
.\scripts\maintenance\quick-flush.ps1

# Verify functionality  
.\scripts\maintenance\verify-pihole.ps1

# Complete restart
.\scripts\restart\restart-pihole-complete.ps1
```

## 📁 Domain Management

### Smart Domain Processing
Intelligent processor handles `.txt` and `.json` files with interactive classification:

```powershell
# Place files in scripts/domain-processing/input/ and run:
.\scripts\domain-processing\process-domains.ps1

# Supports:
# - Plain .txt files (one domain per line)
# - JSON files (turtlecute.org format)
# - Interactive whitelist/blacklist classification
# - Auto-prefixing (wt_, bl_, indef_)
```

### Manual List Editing

#### Edit Whitelist (allowed domains)
Edit `etc-pihole/whitelist.txt`:
```plaintext
# === GAMING ===
supercell.com           # Supercell games
clashroyale.com         # Clash Royale
minecraft.net           # Minecraft

# === WORK ===
office365.com           # Microsoft Office
zoom.us                 # Video conferencing
```

#### Edit Blacklist (blocked domains)
Edit `etc-pihole/blacklist.txt`:
```plaintext
# === ADVERTISING ===
doubleclick.net         # Google Ads
googleadservices.com    # Google Ad Services
facebook.com            # Block Facebook completely

# === MALWARE ===
malicious-site.com      # Malicious site
```

### Apply Changes
After editing files:
```powershell
.\scripts\restart\restart-pihole-complete.ps1
```

## Available Scripts & Maintenance

### 🎯 **MAIN SCRIPTS (Recommended)**

#### `.\scripts\maintenance\maintenance.ps1` - **UNIFIED MAINTENANCE MENU** ⭐
Interactive menu with all maintenance options:
```powershell
.\scripts\maintenance\maintenance.ps1
```
**Menu Options:**
- [1] Quick Flush - Clear DNS caches (30s)
- [2] Complete Optimization - Full system check (3m)  
- [3] Full Restart - Complete system restart (5m)
- [4] Process Domains - Handle new domain files
- [5] Verify System - Test all functionality

#### `.\scripts\maintenance\quick-flush.ps1` - **QUICK DNS FLUSH**
Fast DNS cache clearing for daily use:
```powershell
.\scripts\maintenance\quick-flush.ps1
```

#### `.\scripts\maintenance\optimize-pihole.ps1` - **SYSTEM OPTIMIZATION**
Complete system health check and optimization:
```powershell
.\scripts\maintenance\optimize-pihole.ps1           # Weekly optimization
.\scripts\maintenance\optimize-pihole.ps1 -Full     # Monthly deep optimization
```

### 🔧 **SPECIALIZED SCRIPTS**

#### `.\scripts\domain-processing\process-domains.ps1` (Advanced Domain Processor)
**Ultra-optimized PowerShell script** with intelligent domain classification:

- **Multi-format support**: Handles .txt and .json files
- **Interactive menu**: Clean, user-friendly interface
- **Smart file analysis**: Auto-detects content and shows previews
- **Auto-classification**: Prefixes files (wt_, bl_, indef_)
- **High performance**: Optimized with single-letter functions
- **Comprehensive logging**: Detailed processing logs

```powershell
.\scripts\domain-processing\process-domains.ps1             # Interactive mode
.\scripts\domain-processing\process-domains.ps1 -DryRun     # Preview mode (no changes)
```

**Features:**
- JSON parsing with true/false validation (turtlecute.org format)
- Real-time domain extraction and Pi-hole integration
- Intelligent sleep mechanisms for Docker operations
- Comprehensive error handling and validation

#### `.\scripts\restart\restart-pihole-complete.ps1` (Main System Script)
Complete Pi-hole container restart with auto-configuration:
- Restarts Pi-hole container
- Automatically executes auto-configuration
- Applies custom whitelist and blacklist
- Verifies everything works correctly
- Updates gravity database

```powershell
.\scripts\restart\restart-pihole-complete.ps1        # Complete restart
.\scripts\restart\restart-pihole-complete.ps1 -Help  # Show help
```

#### `.\scripts\maintenance\verify-pihole.ps1`
Comprehensive system functionality verification:
- Tests whitelisted domains (should be allowed)
- Tests blacklisted domains (should be blocked)
- Tests neutral domains (should be allowed)
- Reports blocking efficiency

```powershell
.\scripts\maintenance\verify-pihole.ps1
```

#### `.\scripts\startup\run-auto-init.ps1`
Manually executes auto-configuration without restarting:
```powershell
.\scripts\startup\run-auto-init.ps1
```

#### `.\scripts\auto-init-pihole.sh`
Internal script that runs inside the Docker container to apply custom configurations.

### 📋 **MAINTENANCE WORKFLOW**

#### **Daily Use:**
```powershell
.\scripts\maintenance\maintenance.ps1  # Select option 1 (Quick Flush)
# OR
.\scripts\maintenance\quick-flush.ps1  # Direct quick flush
```

#### **Weekly Maintenance:**
```powershell
.\scripts\maintenance\maintenance.ps1  # Select option 2 (Complete Optimization)
# OR  
.\scripts\maintenance\optimize-pihole.ps1  # Direct optimization
```

#### **Monthly Deep Clean:**
```powershell
.\scripts\maintenance\optimize-pihole.ps1 -Full  # Full optimization with gravity update
```

#### **Adding New Domains:**
```powershell
# 1. Add .json or .txt files to scripts/domain-processing/input/
# 2. Run:
.\scripts\maintenance\maintenance.ps1  # Select option 4 (Process Domains)
# OR
.\scripts\domain-processing\process-domains.ps1  # Direct domain processing
```

#### **Troubleshooting:**
```powershell
.\scripts\maintenance\maintenance.ps1  # Select option 5 (Verify System)
# OR
.\scripts\maintenance\verify-pihole.ps1  # Direct verification

# If problems persist:
.\scripts\restart\restart-pihole-complete.ps1  # Complete restart
```

### 🏆 **QUICK REFERENCE TABLE**

| Task | Quick Command | Menu Option |
|------|--------------|-------------|
| Clear DNS cache | `.\scripts\maintenance\quick-flush.ps1` | Menu → 1 |
| System health check | `.\scripts\maintenance\optimize-pihole.ps1` | Menu → 2 |
| Complete restart | `.\scripts\restart\restart-pihole-complete.ps1` | Menu → 3 |
| Add domains | `.\scripts\domain-processing\process-domains.ps1` | Menu → 4 |
| Test functionality | `.\scripts\maintenance\verify-pihole.ps1` | Menu → 5 |

### 💡 **PRO TIPS**
1. **After browser changes**: Use Quick Flush
2. **After adding domains**: Use Process Domains → Quick Flush  
3. **Weekly maintenance**: Use Complete Optimization
4. **Monthly maintenance**: Use `optimize-pihole.ps1 -Full`
5. **Problems?**: Use Verify System first, then Complete Restart if needed

## 🌐 Web Interface Access

- **URL**: http://YOUR_IP:8080/admin
- **Password**: From your `.env` file
- **Key Sections**: Query Log, Domain Lists, Settings

## 🧪 Testing & Verification

### DNS Testing
```powershell
# Automated verification
.\scripts\maintenance\verify-pihole.ps1

# Manual testing
nslookup google.com YOUR_PIHOLE_IP
nslookup doubleclick.net YOUR_PIHOLE_IP  # Should be blocked
```

### Router Configuration
Set your router's DNS to your Pi-hole IP address for network-wide blocking.

## 🚨 Troubleshooting

### Common Issues
```powershell
# Container won't start
docker-compose logs pihole

# Domains not applied
.\scripts\startup\run-auto-init.ps1
docker exec pihole pihole updateGravity

# Check system status
.\scripts\system-precheck.ps1

# Complete reset (WARNING: deletes everything)
docker-compose down -v
Remove-Item -Recurse -Force etc-pihole/*
.\scripts\restart\restart-pihole-complete.ps1
```

### Quick Diagnosis
- **Can't access web**: Check IP/port in `.env`, firewall settings
- **DNS not working**: Verify port 53 available, router DNS settings
- **Permission errors**: Run PowerShell as Administrator

### Database Verification
```powershell
# View domain lists
docker exec pihole sqlite3 /etc/pihole/gravity.db "SELECT * FROM domainlist;"

# Check domain count
docker exec pihole sqlite3 /etc/pihole/gravity.db "SELECT COUNT(*) FROM gravity;"
```

## 📄 File Formats

### Text Files (.txt)
```plaintext
# One domain per line, comments with #
domain.com
subdomain.example.com
```

### JSON Files (.json)
```json
{
  "abt": {
    "hosts": {
      "category": {
        "domain1.com": true,   // Processed
        "domain2.com": false   // Ignored
      }
    }
  }
}
```

## 🔄 Workflow

### Adding Domains
1. Place `.txt` or `.json` files in `scripts/domain-processing/input/`
2. Run `.\scripts\domain-processing\process-domains.ps1`
3. Use interactive menu to classify domains
4. Verify with `.\scripts\maintenance\verify-pihole.ps1`

### Manual Editing
1. Edit `whitelist.txt` or `blacklist.txt`
2. Run `.\scripts\restart\restart-pihole-complete.ps1`
3. Verify functionality

## 📊 Monitoring & Maintenance

### Key Commands
```powershell
# Container status
docker ps | findstr pihole

# View logs
docker-compose logs -f pihole
Get-Content domain-processing.log -Tail 20

# Update & restart
docker exec pihole pihole updateGravity
docker-compose restart

# Container shell access
docker exec -it pihole bash
```

### Important Files
- **Configuration**: `etc-pihole/pihole.toml`
- **Database**: `etc-pihole/gravity.db`
- **Custom Lists**: `whitelist.txt` / `blacklist.txt`
- **Processing Log**: `domain-processing.log`

### Analytics & Monitoring
```powershell
# View processing activity
Get-Content domain-processing.log | Select-Object -Last 20

# Monitor in real-time
Get-Content domain-processing.log -Wait

# Live query log
docker exec pihole tail -f /var/log/pihole.log

# Container logs
docker-compose logs -f pihole

# Pi-hole statistics
docker exec pihole pihole -c -j
```

## 📊 Performance & Efficiency

### Current System Stats
- **Blocking Rate**: **97% efficiency**
- **Domains Tracked**: 80,417+ total domains
  - 80,061 from StevenBlack hosts
  - 356 custom blacklisted domains
  - 3 custom whitelisted domains
- **Script Performance**: 93% size reduction (396→27 lines)
- **Processing Speed**: Ultra-optimized with single-letter functions
- **Memory Usage**: Efficient hashtable and pipeline operations

### Advanced Features
- **Interactive classification** with clean color-coded menus
- **Multi-format support** (.txt and .json parsing)
- **Intelligent content analysis** with preview capabilities
- **Auto-prefixing system** (wt_, bl_, indef_)
- **Comprehensive logging** with detailed processing history
- **Docker integration** with smart restart mechanisms

## Security

### ⚠️ **IMPORTANT SECURITY SETUP**

1. **Environment Variables (REQUIRED)**
   - Copy `.env.example` to `.env`
   - Set a **strong, unique password** in `PIHOLE_WEBPASSWORD`
   - Configure your correct IP address in `PIHOLE_SERVER_IP`
   - **NEVER commit `.env` to version control**

2. **Password Requirements**
   - Use a password manager to generate a secure password
   - Minimum 12 characters with mixed case, numbers, and symbols
   - Change default passwords immediately after setup

3. **Network Security**
   - Only accessible from local network by default
   - Consider using HTTPS/TLS for production environments
   - Regularly update with `docker-compose pull && docker-compose up -d`

4. **File Security**
   - Sensitive files are automatically excluded via `.gitignore`
   - SSL certificates and database files are not tracked
   - Admin password hashes are protected

5. **Validation & Testing**
   - JSON parser validates domain entries for security
   - Dry-run mode available for safe testing
   - Always verify changes before applying



## 🔗 Resources

- [Pi-hole Documentation](https://docs.pi-hole.net/)
- [Docker Hub](https://hub.docker.com/r/pihole/pihole)
- [StevenBlack Hosts](https://github.com/StevenBlack/hosts)
- [Security Guide](SECURITY.md)

---

**Author**: facusora01 | **Version**: 3.0 | **License**: MIT | **Status**: Production Ready ✅