#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

usage() {
    echo "Usage: $0 [apply|destroy|plan|preflight] [-var 'key=value' ...]"
    echo ""
    echo "Commands:"
    echo "  preflight  - Run preflight checks before deployment"
    echo "  apply      - Deploy infrastructure (includes preflight)"
    echo "  destroy    - Destroy infrastructure"
    echo "  plan       - Show plan (includes preflight)"
    echo ""
    echo "Examples:"
    echo "  $0 preflight -var 'ssh_public_keys=[\\"\$(cat key.pub)\\""]' -var 'network_type=bridge'"
    echo "  $0 apply -var 'ssh_public_keys=[\\"\$(cat key.pub)\\""]' -var 'network_type=bridge'"
    echo "  $0 destroy -var 'ssh_public_keys=[\\"\$(cat key.pub)\\""]'"
    exit 1
}

ACTION="${1:-}"
shift || true

if [[ ! "$ACTION" =~ ^(apply|destroy|plan|preflight)$ ]]; then
    usage
fi

VARS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -var)
            VARS+=("$1" "$2")
            shift 2
            ;;
        *)
            VARS+=("$1")
            shift
            ;;
    esac
done

get_var() {
    local var_name="$1"
    for ((i=0; i<${#VARS[@]}; i++)); do
        if [[ "${VARS[$i]}" == "-var" ]]; then
            local key="${VARS[$i+1]%%=*}"
            local value="${VARS[$i+1]#*=}"
            if [[ "$key" == "$var_name" ]]; then
                echo "$value"
                return
            fi
            ((i++))
        fi
    done
}

check_network_exists() {
    local network_name="$1"
    lxc network list 2>/dev/null | grep -q "^| $network_name "
}

check_profile_exists() {
    local profile_name="$1"
    lxc profile list 2>/dev/null | grep -q "^| $profile_name "
}

check_instance_exists() {
    local instance_name="$1"
    lxc list 2>/dev/null | grep -q "^| $instance_name "
}

run_preflight() {
    local exit_code=0
    
    log_info "Running preflight checks..."
    echo ""
    
    WORKSPACE=$(terraform workspace show 2>/dev/null || echo "default")
    NETWORK_TYPE=$(get_var "network_type" || echo "bridge")
    SSH_KEY=$(get_var "ssh_public_keys")
    
    log_info "Workspace: $WORKSPACE"
    log_info "Network Type: $NETWORK_TYPE"
    
    if [[ -z "$SSH_KEY" ]]; then
        log_warn "ssh_public_keys not provided - some checks may fail"
    else
        log_info "SSH key: provided"
    fi
    
    echo ""
    log_info "Checking prerequisites..."
    
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform not installed"
        exit 1
    fi
    log_info "Terraform: $(terraform version 2>/dev/null | head -1)"
    
    if ! command -v lxc &> /dev/null; then
        log_error "LXC not installed"
        exit 1
    fi
    log_info "LXC: available"
    
    if ! lxc project list &>/dev/null; then
        log_error "Cannot connect to LXD daemon"
        exit 1
    fi
    log_info "LXD daemon: connected"
    
    NETWORK_NAME="k3s-${WORKSPACE}-net"
    PROFILE_NAME="k3s-${WORKSPACE}-cluster-01-profile"
    INSTANCE_NAME="k3s-${WORKSPACE}-cluster-01"
    
    echo ""
    log_info "Checking existing resources for workspace '$WORKSPACE'..."
    
    local conflicts=0
    
    if check_network_exists "$NETWORK_NAME"; then
        log_warn "Network already exists: $NETWORK_NAME"
        ((conflicts++))
    else
        log_info "Network available: $NETWORK_NAME"
    fi
    
    if check_profile_exists "$PROFILE_NAME"; then
        log_warn "Profile already exists: $PROFILE_NAME"
        ((conflicts++))
    else
        log_info "Profile available: $PROFILE_NAME"
    fi
    
    if check_instance_exists "$INSTANCE_NAME"; then
        log_warn "Instance already exists: $INSTANCE_NAME"
        ((conflicts++))
    else
        log_info "Instance available: $INSTANCE_NAME"
    fi
    
    echo ""
    
    if [[ $conflicts -gt 0 ]]; then
        log_warn "Found $conflicts existing resource(s) - will be imported/managed"
        echo ""
        echo "Import commands (if needed):"
        echo "  terraform import 'module.k3s_cluster_node.lxd_network.bridge_network[0]' $NETWORK_NAME"
        echo "  terraform import 'module.k3s_cluster_node.lxd_network.network[0]' $NETWORK_NAME"
        echo "  terraform import 'module.k3s_cluster_node.lxd_profile.instance_profile' $PROFILE_NAME"
        echo "  terraform import 'module.k3s_cluster_node.lxd_instance.app_instance' $INSTANCE_NAME"
    else
        log_info "No conflicts - clean deployment"
    fi
    
    echo ""
    log_info "Checking storage pool..."
    if lxc storage list 2>/dev/null | grep -q "my-dir-pool"; then
        log_info "Storage pool 'my-dir-pool': available"
    else
        log_warn "Storage pool 'my-dir-pool' not found - may need to create"
    fi
    
    echo ""
    log_info "Checking network interface..."
    if lxc network list 2>/dev/null | grep -q "enp4s0"; then
        log_info "Network interface 'enp4s0': available"
    else
        log_warn "Network interface 'enp4s0' not found - may need adjustment"
    fi
    
    echo ""
    log_info "Preflight check complete!"
    echo ""
    
    return $exit_code
}

import_existing_resources() {
    WORKSPACE=$(terraform workspace show 2>/dev/null || echo "default")
    NETWORK_NAME="k3s-${WORKSPACE}-net"
    PROFILE_NAME="k3s-${WORKSPACE}-cluster-01-profile"
    INSTANCE_NAME="k3s-${WORKSPACE}-cluster-01"
    NETWORK_TYPE=$(get_var "network_type" || echo "bridge")
    
    local imported=0
    
    if check_network_exists "$NETWORK_NAME"; then
        log_info "Found existing network: $NETWORK_NAME"
        
        if [[ "$NETWORK_TYPE" == "bridge" ]]; then
            RESOURCE="lxd_network.bridge_network[0]"
        else
            RESOURCE="lxd_network.network[0]"
        fi
        
        if ! terraform state show "module.k3s_cluster_node.$RESOURCE" >/dev/null 2>&1; then
            log_info "Importing network into state..."
            if terraform import "module.k3s_cluster_node.$RESOURCE" "$NETWORK_NAME" "${VARS[@]}" 2>/dev/null; then
                ((imported++))
            fi
        fi
    fi
    
    if check_profile_exists "$PROFILE_NAME"; then
        log_info "Found existing profile: $PROFILE_NAME"
        if ! terraform state show "module.k3s_cluster_node.lxd_profile.instance_profile" >/dev/null 2>&1; then
            log_info "Importing profile into state..."
            if terraform import "module.k3s_cluster_node.lxd_profile.instance_profile" "$PROFILE_NAME" "${VARS[@]}" 2>/dev/null; then
                ((imported++))
            fi
        fi
    fi
    
    if check_instance_exists "$INSTANCE_NAME"; then
        log_info "Found existing instance: $INSTANCE_NAME"
        if ! terraform state show "module.k3s_cluster_node.lxd_instance.app_instance" >/dev/null 2>&1; then
            log_info "Importing instance into state..."
            if terraform import "module.k3s_cluster_node.lxd_instance.app_instance" "$INSTANCE_NAME" "${VARS[@]}" 2>/dev/null; then
                ((imported++))
            fi
        fi
    fi
    
    return 0
}

echo "==> Running terraform $ACTION..."

if [[ "$ACTION" == "preflight" ]]; then
    run_preflight
    exit $?
fi

if [[ "$ACTION" == "apply" || "$ACTION" == "plan" ]]; then
    run_preflight
    echo ""
fi

if [[ "$ACTION" == "apply" ]]; then
    echo "==> Checking for existing resources..."
    import_existing_resources
    echo "==> Running terraform apply..."
    terraform apply -auto-approve "${VARS[@]}"
    
elif [[ "$ACTION" == "destroy" ]]; then
    echo "==> Running terraform destroy..."
    terraform destroy -auto-approve "${VARS[@]}"
    
else
    echo "==> Running terraform $ACTION..."
    terraform "$ACTION" "${VARS[@]}"
fi

echo "==> Done!"
