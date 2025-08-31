# Bank of Anthos API External Access Setup

This document explains how to expose the Bank of Anthos microservice APIs externally for permanent access.

## Overview

By default, all Bank of Anthos API services use `ClusterIP` service types, making them only accessible within the Kubernetes cluster. This document provides two approaches for permanent external access.

## Prerequisites

- GKE cluster with Bank of Anthos deployed
- `kubectl` configured to access your cluster

## Approach 1: LoadBalancer Services (Recommended for GKE Autopilot)

This approach gives each service its own external IP address. It's simpler and works reliably with GKE Autopilot.

### Step 1: Convert Services to LoadBalancer Type

```bash
kubectl patch service userservice -p '{"spec":{"type":"LoadBalancer"}}'
kubectl patch service contacts -p '{"spec":{"type":"LoadBalancer"}}'
kubectl patch service balancereader -p '{"spec":{"type":"LoadBalancer"}}'
kubectl patch service ledgerwriter -p '{"spec":{"type":"LoadBalancer"}}'
kubectl patch service transactionhistory -p '{"spec":{"type":"LoadBalancer"}}'
```

### Step 2: Get External IP Addresses

```bash
kubectl get services
```

Wait for all services to show external IPs (not `<pending>`). This usually takes 2-3 minutes.

### Step 3: Test API Access

Use the individual external IPs:

```bash
# Example - replace with actual external IPs
curl "http://USERSERVICE-EXTERNAL-IP:8080/login?username=testuser&password=password123"
curl -H "Authorization: Bearer <token>" "http://BALANCEREADER-EXTERNAL-IP:8080/balances/1234567890"
```

**Pros:** Simple, reliable, immediate access  
**Cons:** Multiple external IPs, higher cost (~$18/month per LoadBalancer)

---

## Approach 2: Ingress (Single External IP)

This approach uses a single external IP with path-based routing. More complex but cost-effective.

### Step 1: Install NGINX Ingress Controller

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.1/deploy/static/provider/cloud/deploy.yaml
```

Wait for the controller to be ready:

```bash
kubectl get pods -n ingress-nginx --selector=app.kubernetes.io/component=controller
```

Look for `STATUS: Running` and `READY: 1/1`

### Step 2: Get External IP

```bash
kubectl get service ingress-nginx-controller -n ingress-nginx
```

Note the `EXTERNAL-IP` - this will be your API endpoint.

### Step 3: Create API Ingress Configuration

Create `api-ingress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: bank-of-anthos-api
  labels:
    application: bank-of-anthos
    environment: development
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
    nginx.ingress.kubernetes.io/use-regex: "true"
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      # User Service - Authentication APIs
      - path: /api/users(/|$)(.*)
        pathType: ImplementationSpecific
        backend:
          service:
            name: userservice
            port:
              number: 8080
      # Contacts Service - User contacts APIs
      - path: /api/contacts(/|$)(.*)
        pathType: ImplementationSpecific
        backend:
          service:
            name: contacts
            port:
              number: 8080
      # Balance Reader Service - Account balance APIs
      - path: /api/balances(/|$)(.*)
        pathType: ImplementationSpecific
        backend:
          service:
            name: balancereader
            port:
              number: 8080
      # Ledger Writer Service - Transaction submission APIs
      - path: /api/transactions(/|$)(.*)
        pathType: ImplementationSpecific
        backend:
          service:
            name: ledgerwriter
            port:
              number: 8080
      # Transaction History Service - Transaction history APIs
      - path: /api/history(/|$)(.*)
        pathType: ImplementationSpecific
        backend:
          service:
            name: transactionhistory
            port:
              number: 8080
```

### Step 4: Deploy the Ingress

```bash
kubectl apply -f api-ingress.yaml
```

Verify the ingress:

```bash
kubectl get ingress bank-of-anthos-api
```

## API Endpoints Reference

### Approach 1: LoadBalancer Services
Each service has its own external IP. Replace `<SERVICE-EXTERNAL-IP>` with the actual IP:

**User Service (Authentication):**
- `GET http://<USERSERVICE-IP>:8080/login?username=<user>&password=<pass>` - Get JWT token
- `POST http://<USERSERVICE-IP>:8080/users` - Create new user

**Contacts Service 🔒:**
- `GET http://<CONTACTS-IP>:8080/contacts/<username>` - Get user contacts
- `POST http://<CONTACTS-IP>:8080/contacts/<username>` - Add new contact

**Balance Reader Service 🔒:**
- `GET http://<BALANCEREADER-IP>:8080/balances/<accountid>` - Get account balance

**Ledger Writer Service 🔒:**
- `POST http://<LEDGERWRITER-IP>:8080/transactions` - Submit transaction

**Transaction History Service 🔒:**
- `GET http://<TRANSACTIONHISTORY-IP>:8080/transactions/<accountid>` - Get transaction history

### Approach 2: Ingress (Single IP)
Replace `<EXTERNAL-IP>` with your ingress external IP address:

**Authentication (User Service):**
- `GET http://<EXTERNAL-IP>/api/users/login?username=<user>&password=<pass>` - Get JWT token
- `POST http://<EXTERNAL-IP>/api/users/users` - Create new user

**Contacts Service 🔒:**
- `GET http://<EXTERNAL-IP>/api/contacts/contacts/<username>` - Get user contacts
- `POST http://<EXTERNAL-IP>/api/contacts/contacts/<username>` - Add new contact

**Balance Reader Service 🔒:**
- `GET http://<EXTERNAL-IP>/api/balances/balances/<accountid>` - Get account balance

**Ledger Writer Service 🔒:**
- `POST http://<EXTERNAL-IP>/api/transactions/transactions` - Submit transaction

**Transaction History Service 🔒:**
- `GET http://<EXTERNAL-IP>/api/history/transactions/<accountid>` - Get transaction history

🔒 = Requires `Authorization: Bearer <jwt-token>` header

## Authentication Flow

1. **Get JWT Token:**
   ```bash
   curl "http://<EXTERNAL-IP>/api/users/login?username=testuser&password=password123"
   ```

2. **Use Token for Authenticated Requests:**
   ```bash
   curl -H "Authorization: Bearer <jwt-token>" \
        "http://<EXTERNAL-IP>/api/balances/balances/1234567890"
   ```

## Testing with Postman

1. **Import Environment:**
   - Create variable: `BASE_URL` = `http://<EXTERNAL-IP>`
   - Create variable: `JWT_TOKEN` = (empty initially)

2. **Login Request:**
   - Method: `GET`
   - URL: `{{BASE_URL}}/api/users/login?username=testuser&password=password123`
   - Save the token from response to `JWT_TOKEN` variable

3. **Authenticated Requests:**
   - Method: `GET/POST` (as needed)
   - URL: `{{BASE_URL}}/api/...`
   - Headers: `Authorization: Bearer {{JWT_TOKEN}}`

## Cleanup

### To remove LoadBalancer setup:
```bash
kubectl patch service userservice -p '{"spec":{"type":"ClusterIP"}}'
kubectl patch service contacts -p '{"spec":{"type":"ClusterIP"}}'
kubectl patch service balancereader -p '{"spec":{"type":"ClusterIP"}}'
kubectl patch service ledgerwriter -p '{"spec":{"type":"ClusterIP"}}'
kubectl patch service transactionhistory -p '{"spec":{"type":"ClusterIP"}}'
```

### To remove Ingress setup:
```bash
# Remove the ingress
kubectl delete -f api-ingress.yaml

# Remove the ingress controller
kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.1/deploy/static/provider/cloud/deploy.yaml
```

## Security Considerations

- This setup exposes APIs to the public internet
- JWT tokens are required for most operations
- Consider adding TLS/HTTPS for production use
- Consider implementing rate limiting
- Monitor API usage and access logs

## Troubleshooting

**Ingress shows no external IP:**
- Wait 2-3 minutes for load balancer provisioning
- Check ingress controller status: `kubectl get pods -n ingress-nginx`

**503 Service Unavailable:**
- Verify services are running: `kubectl get services`
- Check pod health: `kubectl get pods`

**Authentication errors:**
- Ensure JWT token is valid and not expired
- Check token format: `Authorization: Bearer <token>`

## Cost Considerations

- One Google Cloud Load Balancer (~$18/month)
- Data processing charges apply
- More cost-effective than multiple LoadBalancer services