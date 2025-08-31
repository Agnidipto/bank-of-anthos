#!/bin/bash

# Bank of Anthos External API Cleanup Script
# This script converts API services back to ClusterIP type (internal only)

echo "🔒 Cleaning up external API access for Bank of Anthos..."
echo "This will make APIs internal-only again."
echo

echo "Converting services back to ClusterIP type..."

echo "  📱 User Service..."
kubectl patch service userservice -p '{"spec":{"type":"ClusterIP"}}'

echo "  👥 Contacts Service..."
kubectl patch service contacts -p '{"spec":{"type":"ClusterIP"}}'

echo "  💰 Balance Reader Service..."
kubectl patch service balancereader -p '{"spec":{"type":"ClusterIP"}}'

echo "  📝 Ledger Writer Service..."
kubectl patch service ledgerwriter -p '{"spec":{"type":"ClusterIP"}}'

echo "  📊 Transaction History Service..."
kubectl patch service transactionhistory -p '{"spec":{"type":"ClusterIP"}}'

echo
echo "✅ All services converted back to ClusterIP type!"
echo "🔒 APIs are now internal-only (accessible from within cluster only)"
echo "💰 External load balancers have been removed (cost savings)"
echo
echo "Check status with:"
echo "  kubectl get services"