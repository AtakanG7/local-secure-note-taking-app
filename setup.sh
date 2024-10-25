#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

APP_DIR="$HOME/projects/simple-notes"
DATA_DIR="/var/lib/simple-notes"
CONFIG_DIR="/etc/simple-notes"
VENV_DIR="$APP_DIR/venv"
INSTALL_FLAG="$DATA_DIR/.installed"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"

timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

log_info() {
    echo -e "[$(timestamp)] ${GREEN}[INFO]${NC} $1" | tee -a "$DATA_DIR/simple-notes.log"
}

log_warn() {
    echo -e "[$(timestamp)] ${YELLOW}[WARN]${NC} $1" | tee -a "$DATA_DIR/simple-notes.log"
}

log_error() {
    echo -e "[$(timestamp)] ${RED}[ERROR]${NC} $1" | tee -a "$DATA_DIR/simple-notes.log"
}

log_debug() {
    if [ "${DEBUG:-false}" = "true" ]; then
        echo -e "[$(timestamp)] [DEBUG] $1" | tee -a "$DATA_DIR/simple-notes.log"
    fi
}

# Replaced print functions
print_status() {
    log_info "$1"
}

print_warning() {
    log_warn "$1"
}

print_error() {
    log_error "$1"
}

setup_log_rotation() {
    if [ ! -f "/etc/logrotate.d/simple-notes" ]; then
        sudo tee /etc/logrotate.d/simple-notes > /dev/null << EOF
${DATA_DIR}/simple-notes.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 600 $USER $USER
}
EOF
        log_debug "Setup log rotation"
    fi
}

setup_autostart() {
    log_info "Setting up autostart service..."
    
    mkdir -p "$SYSTEMD_USER_DIR"
    log_debug "Created systemd user directory: $SYSTEMD_USER_DIR"
    
    cat > "$SYSTEMD_USER_DIR/simple-notes.service" << END
[Unit]
Description=Simple Notes Application
After=network.target

[Service]
Type=simple
ExecStart=${APP_DIR}/setup.sh --run
Environment=DISPLAY=:0
Restart=on-failure
RestartSec=5
StandardOutput=append:${DATA_DIR}/simple-notes.log
StandardError=append:${DATA_DIR}/simple-notes.log

[Install]
WantedBy=default.target
END

    log_debug "Created systemd service file"
    systemctl --user enable simple-notes.service
    log_debug "Enabled systemd service"
    systemctl --user start simple-notes.service
    log_debug "Started systemd service"
    
    loginctl enable-linger "$USER"
    log_debug "Enabled user session lingering"
    
    log_info "Autostart enabled! The app will start on boot."
    log_warn "Service management commands:"
    echo "  systemctl --user status simple-notes"
    echo "  systemctl --user stop simple-notes"
    echo "  systemctl --user start simple-notes"
    echo "  systemctl --user disable simple-notes"
    echo "  tail -f $DATA_DIR/simple-notes.log    # View logs"
}

check_installation() {
    log_debug "Checking installation status"
    if [ -f "$INSTALL_FLAG" ] && [ "$1" != "--autostart" ]; then
        if [ "$1" = "--run" ]; then
            log_info "Starting app in service mode..."
            source "$VENV_DIR/bin/activate"
            python3 "$APP_DIR/run.py"
            exit 0
        fi
        log_info "Installation detected."
        echo "Options:"
        echo "1) Start the app normally"
        echo "2) Enable autostart on boot"
        echo "3) Exit"
        read -p "Choose an option (1-3): " choice
        
        case $choice in
            1)
                log_info "Starting app normally..."
                source "$VENV_DIR/bin/activate"
                python3 run.py
                exit 0
                ;;
            2)
                setup_autostart
                exit 0
                ;;
            3)
                log_info "Exiting..."
                exit 0
                ;;
            *)
                log_error "Invalid option selected"
                exit 1
                ;;
        esac
    fi
}

setup_directories() {
    log_info "Setting up directories..."
    
    if [ ! -d "$DATA_DIR" ]; then
        log_debug "Creating data directory: $DATA_DIR"
        sudo mkdir -p "$DATA_DIR"
    fi
    
    if [ ! -d "$CONFIG_DIR" ]; then
        log_debug "Creating config directory: $CONFIG_DIR"
        sudo mkdir -p "$CONFIG_DIR"
    fi
    
    log_debug "Setting directory permissions"
    sudo chown "$USER:$USER" "$DATA_DIR"
    sudo chown "$USER:$USER" "$CONFIG_DIR"
    sudo chmod 700 "$DATA_DIR"
    sudo chmod 700 "$CONFIG_DIR"
    
    # Create log file with proper permissions
    touch "$DATA_DIR/simple-notes.log"
    chmod 600 "$DATA_DIR/simple-notes.log"
    
    log_info "Directories created with secure permissions"
}

setup_venv() {
    log_info "Setting up virtual environment..."
    
    python3 -m venv "$VENV_DIR"
    log_debug "Created virtual environment at $VENV_DIR"
    
    source "$VENV_DIR/bin/activate"
    log_debug "Activated virtual environment"
    
    log_debug "Installing dependencies..."
    pip install --upgrade pip
    pip install flask flask-sqlalchemy cryptography python-dotenv
    
    touch "$INSTALL_FLAG"
    log_debug "Created installation flag"
    
    log_info "Dependencies installed successfully"
}

check_dependencies() {
    log_info "Checking system dependencies..."
    
    if ! command -v python3 &> /dev/null; then
        log_error "Python3 is required but not installed"
        exit 1
    fi
    
    PY_VERSION=$(python3 -V 2>&1)
    if [ "$PY_VERSION" -lt 37 ]; then
        log_error "Python 3.7 or higher is required"
        exit 1
    fi
    
    log_info "System dependencies OK"
}

main() {
    log_info "Starting Simple Notes setup..."
    
    check_installation "$1"
    
    log_info "First time setup detected..."
    
    check_dependencies
    
    setup_directories
    setup_venv
    setup_log_rotation
    
    log_info "Setup complete!"
    log_warn "Would you like to enable autostart on boot? (y/n)"
    read -p ">" choice
    case $choice in
        y|Y)
            setup_autostart
            ;;
        *)
            log_info "Starting app normally..."
            python3 run.py
            ;;
    esac
}

cleanup() {
    deactivate 2>/dev/null
    log_warn "Shutting down..."
    exit 0
}

trap cleanup SIGINT

# Run main function with any passed arguments
main "$1"