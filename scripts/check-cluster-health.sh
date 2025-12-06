#!/bin/bash
# =============================================================================
# Cluster Health Check Script
# =============================================================================
# Verifies the Kubernetes cluster is healthy before deployment
# Returns exit code 0 if healthy, 1 if issues found
# =============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ISSUES=0
WARNINGS=0

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
    ((WARNINGS++))
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
    ((ISSUES++))
}

echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}   Kubernetes Cluster Health Check          ${NC}"
echo -e "${BLUE}=============================================${NC}"
echo ""

# Check node health
echo -e "${BLUE}Checking node health...${NC}"
TOTAL_NODES=$(kubectl get nodes --no-headers | wc -l)
READY_NODES=$(kubectl get nodes --no-headers | grep -c " Ready " || true)

if [ "$READY_NODES" -eq "$TOTAL_NODES" ]; then
    print_status "All nodes ready ($READY_NODES/$TOTAL_NODES)"
else
    print_error "Not all nodes ready ($READY_NODES/$TOTAL_NODES)"
    kubectl get nodes --no-headers | grep -v " Ready "
fi

# Check for node resource pressure
echo ""
echo -e "${BLUE}Checking node conditions...${NC}"
PRESSURE_NODES=$(kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{" "}{range .status.conditions[?(@.status=="True")]}{.type}{" "}{end}{"\n"}{end}' | grep -E "(MemoryPressure|DiskPressure|PIDPressure)" || true)
if [ -n "$PRESSURE_NODES" ]; then
    print_warning "Nodes with resource pressure detected"
    echo "$PRESSURE_NODES"
else
    print_status "No resource pressure on nodes"
fi

# Check critical namespaces
echo ""
echo -e "${BLUE}Checking critical pods...${NC}"

# kube-system pods
KUBE_SYSTEM_NOT_RUNNING=$(kubectl get pods -n kube-system --no-headers | grep -v -E "Running|Completed" | wc -l || true)
if [ "$KUBE_SYSTEM_NOT_RUNNING" -gt 0 ]; then
    print_warning "Some kube-system pods not running"
    kubectl get pods -n kube-system | grep -v -E "Running|Completed|NAME"
else
    print_status "All kube-system pods healthy"
fi

# Check ALB controller
echo ""
echo -e "${BLUE}Checking AWS Load Balancer Controller...${NC}"
ALB_RUNNING=$(kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller --no-headers 2>/dev/null | grep -c "Running" || true)
if [ "$ALB_RUNNING" -eq 0 ]; then
    print_error "AWS Load Balancer Controller not running"
else
    print_status "AWS Load Balancer Controller running ($ALB_RUNNING replicas)"
fi

# Check Cluster Autoscaler
echo ""
echo -e "${BLUE}Checking Cluster Autoscaler...${NC}"
CA_RUNNING=$(kubectl get pods -n kube-system -l app.kubernetes.io/name=cluster-autoscaler --no-headers 2>/dev/null | grep -c "Running" || true)
if [ "$CA_RUNNING" -eq 0 ]; then
    print_warning "Cluster Autoscaler not running"
else
    print_status "Cluster Autoscaler running"
fi

# Check monitoring stack
echo ""
echo -e "${BLUE}Checking monitoring stack...${NC}"
if kubectl get namespace monitoring &> /dev/null; then
    PROMETHEUS_RUNNING=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus --no-headers 2>/dev/null | grep -c "Running" || true)
    GRAFANA_RUNNING=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana --no-headers 2>/dev/null | grep -c "Running" || true)
    
    if [ "$PROMETHEUS_RUNNING" -gt 0 ]; then
        print_status "Prometheus running"
    else
        print_warning "Prometheus not running"
    fi
    
    if [ "$GRAFANA_RUNNING" -gt 0 ]; then
        print_status "Grafana running"
    else
        print_warning "Grafana not running"
    fi
else
    print_warning "Monitoring namespace not found"
fi

# Check available resources
echo ""
echo -e "${BLUE}Checking cluster resources...${NC}"
CPU_ALLOCATABLE=$(kubectl get nodes -o jsonpath='{.items[*].status.allocatable.cpu}' | tr ' ' '+' | bc 2>/dev/null || echo "N/A")
MEMORY_ALLOCATABLE=$(kubectl get nodes -o jsonpath='{.items[*].status.allocatable.memory}' | sed 's/Ki//g' | tr ' ' '+' | bc 2>/dev/null || echo "N/A")

echo "  Allocatable CPU: $CPU_ALLOCATABLE cores"
echo "  Allocatable Memory: $(echo "scale=2; $MEMORY_ALLOCATABLE / 1024 / 1024" | bc 2>/dev/null || echo "N/A") GB"

# Check pending pods
echo ""
echo -e "${BLUE}Checking for pending pods...${NC}"
PENDING_PODS=$(kubectl get pods --all-namespaces --field-selector=status.phase=Pending --no-headers 2>/dev/null | wc -l || true)
if [ "$PENDING_PODS" -gt 0 ]; then
    print_warning "$PENDING_PODS pods in Pending state"
    kubectl get pods --all-namespaces --field-selector=status.phase=Pending
else
    print_status "No pending pods"
fi

# Check for crash looping pods
echo ""
echo -e "${BLUE}Checking for crash looping pods...${NC}"
CRASH_LOOP=$(kubectl get pods --all-namespaces --no-headers 2>/dev/null | grep "CrashLoopBackOff" | wc -l || true)
if [ "$CRASH_LOOP" -gt 0 ]; then
    print_warning "$CRASH_LOOP pods in CrashLoopBackOff"
    kubectl get pods --all-namespaces | grep "CrashLoopBackOff"
else
    print_status "No crash looping pods"
fi

# Summary
echo ""
echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}   Health Check Summary                     ${NC}"
echo -e "${BLUE}=============================================${NC}"
echo ""

if [ "$ISSUES" -gt 0 ]; then
    echo -e "${RED}Issues found: $ISSUES${NC}"
    echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
    exit 1
elif [ "$WARNINGS" -gt 0 ]; then
    echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
    echo -e "${GREEN}No critical issues found${NC}"
    exit 0
else
    echo -e "${GREEN}Cluster is healthy!${NC}"
    exit 0
fi

