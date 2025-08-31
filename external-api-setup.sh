#!/bin/bash

# Bank of Anthos External API Setup Script
# This script converts API services to LoadBalancer type for external access

echo "=€ Setting up external API access for Bank of Anthos..."
echo "This will expose all backend APIs with external IP addresses."
echo

echo "Converting services to LoadBalancer type..."

echo "  =ñ User Service..."
kubectl patch service userservice -p '{"spec":{"type":"LoadBalancer"}}'

echo "  =e Contacts Service..."
kubectl patch service contacts -p '{"spec":{"type":"LoadBalancer"}}'

echo "  =° Balance Reader Service..."
kubectl patch service balancereader -p '{"spec":{"type":"LoadBalancer"}}'

echo "  =Ý Ledger Writer Service..."
kubectl patch service ledgerwriter -p '{"spec":{"type":"LoadBalancer"}}'

echo "  =Ê Transaction History Service..."
kubectl patch service transactionhistory -p '{"spec":{"type":"LoadBalancer"}}'

echo
echo " All services converted to LoadBalancer type!"
echo "ó External IPs will be assigned in 2-3 minutes."
echo
echo "Check status with:"
echo "  kubectl get services"
echo
echo "Once external IPs are assigned, you can access APIs at:"
echo "  User Service:         http://USER-SERVICE-IP:8080"
echo "  Contacts:             http://CONTACTS-IP:8080"
echo "  Balance Reader:       http://BALANCE-READER-IP:8080"
echo "  Ledger Writer:        http://LEDGER-WRITER-IP:8080"
echo "  Transaction History:  http://TRANSACTION-HISTORY-IP:8080"
echo
echo "=¡ Frontend will continue to use internal service names - no impact!"