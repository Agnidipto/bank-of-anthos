# Create .env File for External Application

This document provides instructions for creating a `.env` file for your external application that integrates with the Bank of Anthos cluster APIs.

## Instructions

Follow these steps to create the `.env` file for your external application:

### Step 1: Get Current Service External IPs

Run the following command to get the current external IP addresses of all services:

```bash
kubectl get services | grep LoadBalancer
```

Look for these services and note their EXTERNAL-IP values:
- `balancereader`
- `contacts` 
- `frontend`
- `ledgerwriter`
- `transactionhistory`
- `userservice`

### Step 2: Get Current Public Key

Retrieve the current JWT public key from the cluster:

```bash
kubectl get secret jwt-key -o jsonpath='{.data.jwtRS256\.key\.pub}' | base64 -d
```

### Step 3: Create .env File

Create a new `.agent_env` file in your root directory with the following content:

```bash
# Google API Configuration
GOOGLE_GENAI_USE_VERTEXAI=<Copy from ./.env>
GOOGLE_API_KEY=<Copy from ./.env>

# Application Configuration
PORT=8080

# Bank of Anthos Service External IPs
# Update these with current external IPs from Step 1
BALANCE_READER=<BALANCEREADER_EXTERNAL_IP>
CONTACTS=<CONTACTS_EXTERNAL_IP>
FRONTEND=<FRONTEND_EXTERNAL_IP>
LEDGER_WRITER=<LEDGERWRITER_EXTERNAL_IP>
TRANSACTION_WRITER=<TRANSACTIONHISTORY_EXTERNAL_IP>
USER_SERVICE=<USERSERVICE_EXTERNAL_IP>

# JWT Public Key for Token Validation
# Replace the key content between the quotes with output from Step 2
# Use \n for line breaks in the single-line format
CLUSTER_PUBLIC_KEY="-----BEGIN PUBLIC KEY-----\n<KEY_CONTENT_HERE>\n-----END PUBLIC KEY-----"
```

### Step 4: Replace Placeholder Values

1. **Service IPs**: Replace all `<SERVICE_EXTERNAL_IP>` placeholders with the actual external IP addresses from Step 1
2. **Public Key**: Replace `<KEY_CONTENT_HERE>` with the base64-encoded key content from Step 2, ensuring line breaks are represented as `\n`
3. **Google Gemini API Keys**: Replace the `<Copy from ./.env>` in the .agent_env file with the values from .env.
