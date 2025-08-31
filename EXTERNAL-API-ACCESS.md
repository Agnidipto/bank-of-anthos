# Bank of Anthos External API Access

This document explains how to enable/disable external access to the Bank of Anthos backend APIs using the provided scripts.

## Overview

By default, Bank of Anthos API services use `ClusterIP` service types, making them accessible only within the Kubernetes cluster. This setup allows you to easily toggle external access for development and testing purposes.

## Quick Start

### Enable External API Access
```bash
./external-api-setup.sh
```

### Disable External API Access  
```bash
./cleanup-external-apis.sh
```

### Check Service Status
```bash
kubectl get services
```

## How It Works

The scripts modify the Kubernetes service types:

- **ClusterIP** (default): Internal cluster access only
- **LoadBalancer**: External IP address assigned by cloud provider

**Important:** The frontend application continues to use internal service names regardless of the LoadBalancer setup, so there's no impact on the web application.

## API Services Included

The scripts manage external access for these services:

| Service | Port | Description |
|---------|------|-------------|
| userservice | 8080 | User authentication and management |
| contacts | 8080 | User contacts management |
| balancereader | 8080 | Account balance queries |
| ledgerwriter | 8080 | Transaction submissions |
| transactionhistory | 8080 | Transaction history queries |

## External API Endpoints

Once `external-api-setup.sh` is run, check for external IPs:

```bash
kubectl get services
```

Access APIs using the external IP addresses:

### Authentication (User Service)
```bash
# Get JWT token
curl "http://<USERSERVICE-EXTERNAL-IP>:8080/login?username=testuser&password=password123"

# Create new user
curl -X POST "http://<USERSERVICE-EXTERNAL-IP>:8080/users" \
  -d "username=newuser&password=newpass&firstname=Test&lastname=User&birthday=2000-01-01&timezone=PST&address=123 Main St&state=CA&zip=12345&ssn=123-45-6789"
```

### Contacts Service 🔒
```bash
# Get user contacts
curl -H "Authorization: Bearer <jwt-token>" \
  "http://<CONTACTS-EXTERNAL-IP>:8080/contacts/<username>"

# Add new contact
curl -X POST -H "Authorization: Bearer <jwt-token>" \
  -H "Content-Type: application/json" \
  "http://<CONTACTS-EXTERNAL-IP>:8080/contacts/<username>" \
  -d '{"label":"Friend","account_num":"1234567890","routing_num":"123456789","is_external":false}'
```

### Balance Reader Service 🔒
```bash
# Get account balance
curl -H "Authorization: Bearer <jwt-token>" \
  "http://<BALANCEREADER-EXTERNAL-IP>:8080/balances/<accountid>"
```

### Ledger Writer Service 🔒
```bash
# Submit transaction
curl -X POST -H "Authorization: Bearer <jwt-token>" \
  -H "Content-Type: application/json" \
  "http://<LEDGERWRITER-EXTERNAL-IP>:8080/transactions" \
  -d '{"fromAccountNum":"1234567890","fromRoutingNum":"123456789","toAccountNum":"9876543210","toRoutingNum":"123456789","amount":5000,"uuid":"unique-transaction-id"}'
```

### Transaction History Service 🔒
```bash
# Get transaction history
curl -H "Authorization: Bearer <jwt-token>" \
  "http://<TRANSACTIONHISTORY-EXTERNAL-IP>:8080/transactions/<accountid>"
```

🔒 = Requires `Authorization: Bearer <jwt-token>` header

## Authentication Flow Example

1. **Get JWT Token:**
   ```bash
   TOKEN=$(curl -s "http://<USERSERVICE-EXTERNAL-IP>:8080/login?username=testuser&password=password123" | jq -r '.token')
   ```

2. **Use Token for Authenticated Requests:**
   ```bash
   curl -H "Authorization: Bearer $TOKEN" \
     "http://<BALANCEREADER-EXTERNAL-IP>:8080/balances/1234567890"
   ```

## Testing with Postman

### Setup Environment
1. Create new environment in Postman
2. Add variables:
   - `USERSERVICE_IP`: External IP of userservice
   - `CONTACTS_IP`: External IP of contacts service
   - `BALANCEREADER_IP`: External IP of balancereader service
   - `LEDGERWRITER_IP`: External IP of ledgerwriter service
   - `TRANSACTIONHISTORY_IP`: External IP of transactionhistory service
   - `JWT_TOKEN`: (leave empty initially)

### Login Request
- **Method**: `GET`
- **URL**: `http://{{USERSERVICE_IP}}:8080/login?username=testuser&password=password123`
- **Script (Tests tab)**: Save token to environment variable:
  ```javascript
  pm.test("Save JWT Token", function () {
      var jsonData = pm.response.json();
      pm.environment.set("JWT_TOKEN", jsonData.token);
  });
  ```

### Authenticated Requests
- **Headers**: `Authorization: Bearer {{JWT_TOKEN}}`
- **URLs**: Use respective service IPs with port 8080

## Script Details

### `external-api-setup.sh`
- Patches all API services to `LoadBalancer` type
- External IPs assigned automatically (2-3 minutes)
- Provides user-friendly output with instructions

### `cleanup-external-apis.sh`  
- Reverts all API services to `ClusterIP` type
- Removes external access and load balancers
- Saves cloud provider costs

## Cost Considerations

**When External Access is Enabled:**
- 5 Google Cloud Load Balancers (~$18/month each = ~$90/month)
- Data processing charges apply
- Ingress/Egress costs for API calls

**When External Access is Disabled:**
- No load balancer costs
- Internal cluster traffic only

## Security Considerations

- External APIs are exposed to the public internet
- JWT authentication required for most endpoints
- Consider IP allowlisting for production use
- Monitor API access logs
- Use HTTPS in production (requires additional setup)

## Troubleshooting

**External IP shows `<pending>`:**
- Wait 2-3 minutes for cloud provider to assign IP
- Check GKE node pool has sufficient resources

**Service not accessible:**
- Verify external IP is assigned: `kubectl get services`
- Check pod status: `kubectl get pods`
- Verify JWT token is valid and not expired

**Frontend not working:**
- Frontend uses internal service names and is unaffected
- Check frontend pod logs if issues occur

## Default Demo Users

Bank of Anthos comes with demo users you can use for testing:

| Username | Password | Account ID |
|----------|----------|------------|
| testuser | password | 1234567890 |
| alice    | password | 1011226111 |
| bob      | password | 1033623433 |
| eve      | password | 1055757655 |

Use these for initial API testing without creating new users.