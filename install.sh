CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'
local_ip=$(hostname -I | awk '{print $1}')
echo -e "${CYAN}============================================================================${NC}"
echo -e "${CYAN}============================================================================${NC}"
echo -e "${CYAN}===========  GGGG  NN   NN EEEEE TTTTT IIIII DDDDD  =============${NC}"
echo -e "${CYAN}=========== GG  GG NNN  NN EE      T     I   DD  DD =============${NC}"
echo -e "${CYAN}=========== GG     NN N NN EEEE    T     I   DD   D =============${NC}"
echo -e "${CYAN}=========== GG GGG NN  NNN EE      T     I   DD  DD =============${NC}"
echo -e "${CYAN}===========  GGGG  NN   NN EEEEE   T   IIIII DDDDD  =============${NC}"
echo -e "${CYAN}============================================================================${NC}"
echo -e "${CYAN}========================== t.me/gnetid ==================================${NC}"
echo -e "${CYAN}============================================================================${NC}"
echo -e "${CYAN}${NC}"
echo -e "${CYAN}Autoinstall GenieACS.${NC}"
echo -e "${CYAN}${NC}"
echo -e "${CYAN}======================================================================================${NC}"
echo -e "${RED}${NC}"
echo -e "${CYAN}Sebelum melanjutkan, silahkan baca terlebih dahulu. Apakah anda ingin melanjutkan? (y/n)${NC}"
read confirmation

if [ "$confirmation" != "y" ]; then
    echo -e "${CYAN}Install dibatalkan. Tidak ada perubahan dalam ubuntu server anda.${NC}"
    /tmp/install.sh
    exit 1
fi
for ((i = 5; i >= 1; i--)); do
	sleep 1
    echo "Melanjutkan dalam $i. Tekan ctrl+c untuk membatalkan"
done

echo -e "${YELLOW}Memulai instalasi GenieACS...${RESET}"
echo "Menginstal Node.js..."

# Check if Node.js already installed
if command -v node &> /dev/null && command -v npm &> /dev/null; then
    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -ge 16 ]; then
        echo "Node.js sudah terinstall (versi bagus):"
        node -v
        npm -v
    else
        echo "Node.js versi lama terdeteksi, upgrade ke versi 18..."
        # Remove old Node.js packages that conflict
        apt-get remove -y nodejs libnode72 libnode-dev || true
        apt-get autoremove -y
        
        # Install Node.js 18
        apt-get update
        apt-get install -y ca-certificates curl gnupg
        mkdir -p /etc/apt/keyrings
        curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
        NODE_MAJOR=18
        echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
        apt-get update
        apt-get install -y nodejs
        
        if command -v node &> /dev/null && command -v npm &> /dev/null; then
            echo "Node.js berhasil di-upgrade:"
            node -v
            npm -v
        else
            echo -e "${RED}ERROR: Node.js gagal diinstall! Script dihentikan.${NC}"
            exit 1
        fi
    fi
else
    echo "Installing Node.js from NodeSource..."
    # Remove any conflicting packages first
    apt-get remove -y nodejs libnode72 libnode-dev 2>/dev/null || true
    apt-get autoremove -y
    
    # Install Node.js from NodeSource (new method)
    apt-get update
    apt-get install -y ca-certificates curl gnupg
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    NODE_MAJOR=18
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
    apt-get update
    apt-get install -y nodejs
    
    # Verify installation
    if command -v node &> /dev/null && command -v npm &> /dev/null; then
        echo "Node.js berhasil diinstall:"
        node -v
        npm -v
    else
        echo -e "${RED}ERROR: Node.js gagal diinstall! Script dihentikan.${NC}"
        exit 1
    fi
fi

echo "Menginstal MongoDB..."
# Auto-detect Ubuntu version
UBUNTU_CODENAME=$(lsb_release -cs)
echo "Detected Ubuntu version: $UBUNTU_CODENAME"

# Install gnupg if not present
apt-get install -y gnupg curl

# Add MongoDB GPG key (new method for Ubuntu 22+)
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
  gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor

# Add MongoDB repository based on Ubuntu version
case "$UBUNTU_CODENAME" in
  jammy|kinetic|lunar|mantic|noble)
    # Ubuntu 22.04, 22.10, 23.04, 23.10, 24.04
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | \
      tee /etc/apt/sources.list.d/mongodb-org-7.0.list
    ;;
  focal)
    # Ubuntu 20.04
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/7.0 multiverse" | \
      tee /etc/apt/sources.list.d/mongodb-org-7.0.list
    ;;
  bionic)
    # Ubuntu 18.04
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/7.0 multiverse" | \
      tee /etc/apt/sources.list.d/mongodb-org-7.0.list
    ;;
  *)
    # Fallback to jammy for newer versions
    echo "Ubuntu version not explicitly supported, using jammy repository"
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | \
      tee /etc/apt/sources.list.d/mongodb-org-7.0.list
    ;;
esac

apt-get update
apt-get install -y mongodb-org

# Start and enable MongoDB
systemctl start mongod
systemctl enable mongod

# Wait for MongoDB to be ready
echo "Waiting for MongoDB to start..."
sleep 5

# Test MongoDB connection (mongosh for MongoDB 5.0+)
if command -v mongosh &> /dev/null; then
    mongosh --eval 'db.runCommand({ connectionStatus: 1 })'
else
    mongo --eval 'db.runCommand({ connectionStatus: 1 })'
fi

#GenieACS
if !  systemctl is-active --quiet genieacs-{cwmp,fs,ui,nbi}; then
    echo -e "${CYAN}================== Menginstall genieACS CWMP, FS, NBI, UI ==================${NC}"
    npm install -g genieacs@1.2.13
    useradd --system --no-create-home --user-group genieacs || true
    mkdir -p /opt/genieacs
    mkdir -p /opt/genieacs/ext
    chown genieacs:genieacs /opt/genieacs/ext
    cat << EOF > /opt/genieacs/genieacs.env
GENIEACS_CWMP_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-cwmp-access.log
GENIEACS_NBI_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-nbi-access.log
GENIEACS_FS_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-fs-access.log
GENIEACS_UI_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-ui-access.log
GENIEACS_DEBUG_FILE=/var/log/genieacs/genieacs-debug.yaml
GENIEACS_EXT_DIR=/opt/genieacs/ext
GENIEACS_UI_JWT_SECRET=secret
EOF
    chown genieacs:genieacs /opt/genieacs/genieacs.env
    chown genieacs. /opt/genieacs -R
    chmod 600 /opt/genieacs/genieacs.env
    mkdir -p /var/log/genieacs
    chown genieacs. /var/log/genieacs
    # create systemd unit files
## CWMP
    cat << EOF > /etc/systemd/system/genieacs-cwmp.service
[Unit]
Description=GenieACS CWMP
After=network.target

[Service]
User=genieacs
EnvironmentFile=/opt/genieacs/genieacs.env
ExecStart=/usr/bin/genieacs-cwmp

[Install]
WantedBy=default.target
EOF

## NBI
    cat << EOF > /etc/systemd/system/genieacs-nbi.service
[Unit]
Description=GenieACS NBI
After=network.target
 
[Service]
User=genieacs
EnvironmentFile=/opt/genieacs/genieacs.env
ExecStart=/usr/bin/genieacs-nbi
 
[Install]
WantedBy=default.target
EOF

## FS
    cat << EOF > /etc/systemd/system/genieacs-fs.service
[Unit]
Description=GenieACS FS
After=network.target
 
[Service]
User=genieacs
EnvironmentFile=/opt/genieacs/genieacs.env
ExecStart=/usr/bin/genieacs-fs
 
[Install]
WantedBy=default.target
EOF

## UI
    cat << EOF > /etc/systemd/system/genieacs-ui.service
[Unit]
Description=GenieACS UI
After=network.target
 
[Service]
User=genieacs
EnvironmentFile=/opt/genieacs/genieacs.env
ExecStart=/usr/bin/genieacs-ui
 
[Install]
WantedBy=default.target
EOF

# config logrotate
 cat << EOF > /etc/logrotate.d/genieacs
/var/log/genieacs/*.log /var/log/genieacs/*.yaml {
    daily
    rotate 30
    compress
    delaycompress
    dateext
}
EOF
    echo -e "${CYAN}========== Install APP GenieACS selesai... ==============${NC}"
    systemctl daemon-reload
    systemctl enable --now genieacs-{cwmp,fs,ui,nbi}
    systemctl start genieacs-{cwmp,fs,ui,nbi}    
    echo -e "${CYAN}================== Sukses genieACS CWMP, FS, NBI, UI ==================${NC}"
else
    echo -e "${CYAN}============================================================================${NC}"
    echo -e "${CYAN}=================== GenieACS sudah terinstall sebelumnya. ==================${NC}"
fi

#Sukses
echo -e "${CYAN}============================================================================${NC}"
echo -e "${CYAN}========== GenieACS UI akses port 3000. : http://$local_ip:3000 ============${NC}"
echo -e "${CYAN}=================== Informasi: t.me/gnetid =======================${NC}"
echo -e "${CYAN}============================================================================${NC}"
# Copy logo only if genieacs is installed
if [ -d "/usr/lib/node_modules/genieacs/public/" ]; then
    cp -r logo-3976e73d.svg /usr/lib/node_modules/genieacs/public/
    echo -e "${CYAN}Logo berhasil di-copy${NC}"
else
    echo -e "${RED}Warning: GenieACS tidak terinstall dengan benar, skip copy logo${NC}"
fi
echo -e "${CYAN}Sekarang install parameter. Apakah anda ingin melanjutkan? (y/n)${NC}"
read confirmation

if [ "$confirmation" != "y" ]; then
    echo -e "${CYAN}Install dibatalkan..${NC}"
    exit 1
fi

for ((i = 5; i >= 1; i--)); do
    sleep 1
    echo "Lanjut Install Parameter $i. Tekan ctrl+c untuk membatalkan"
done

# Restore database dari folder db yang ada di direktori acs
if [ -d "db" ]; then
    mongorestore --db genieacs --drop db
    systemctl restart genieacs-{cwmp,fs,ui,nbi}
    echo -e "${CYAN}============================================================================${NC}"
    echo -e "${CYAN}=================== VIRTUAL PARAMETER BERHASIL DI INSTALL. =================${NC}"
    echo -e "${CYAN}===Jika ACS URL berbeda, silahkan edit di Admin >> Provosions >> inform ====${NC}"
    echo -e "${CYAN}========== GenieACS UI akses port 3000. : http://$local_ip:3000 ============${NC}"
    echo -e "${CYAN}=================== Informasi: t.me/gnetid =======================${NC}"
    echo -e "${CYAN}============================================================================${NC}"
else
    echo -e "${RED}Folder db tidak ditemukan, skip restore database${NC}"
    echo -e "${CYAN}========== GenieACS UI akses port 3000. : http://$local_ip:3000 ============${NC}"
fi
