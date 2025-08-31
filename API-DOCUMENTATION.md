# Bank of Anthos Frontend API Documentation

This document provides complete API documentation for all backend services used by the Bank of Anthos frontend application.

## Overview

The frontend is a Flask-based Python web application that communicates with 5 microservices to provide banking functionality. All API calls use HTTP/REST protocols with JWT-based authentication.

## Backend Services

| Service | Internal URL | Port | Language | Purpose |
|---------|-------------|------|----------|---------|
| userservice | `http://userservice:8080` | 8080 | Python | User authentication & management |
| contacts | `http://contacts:8080` | 8080 | Python | User contact management |
| balancereader | `http://balancereader:8080` | 8080 | Java | Account balance queries |
| ledgerwriter | `http://ledgerwriter:8080` | 8080 | Java | Transaction processing |
| transactionhistory | `http://transactionhistory:8080` | 8080 | Java | Transaction history queries |

## Authentication

### JWT Token System
- **Token Storage**: HTTP-only cookies
- **Token Name**: `token`
- **Algorithm**: RS256 (RSA with SHA-256)
- **Claims**: `user`, `acct` (account ID), `name`, `exp`, `iat`

### Authentication Header
```
Authorization: Bearer <jwt-token>
```

## API Endpoints

### 1. User Service APIs

#### Login
- **Endpoint**: `GET /login?username<USERNAME>&password<PASSWORD>`
- **Authentication**: None required
- **Parameters**: Query parameters
  - `username` (string): User login name
  - `password` (string): User password
- **Success Response**: 
  ```json
  {
    "token": "eyJhbGciOiJSUzI1NiIs..."
  }
  ```
- **Usage**: User authentication, returns JWT token for subsequent requests
- **Frontend Usage**: Login form submission

#### Create User
- **Endpoint**: `POST /users`
- **Authentication**: None required
- **Content-Type**: `application/x-www-form-urlencoded`
- **Form Data**:
  - `username` (string): Unique username
  - `password` (string): User password
  - `firstname` (string): First name
  - `lastname` (string): Last name
  - `birthday` (string): Date of birth (YYYY-MM-DD)
  - `timezone` (string): User timezone
  - `address` (string): Street address
  - `state` (string): State/Province
  - `zip` (string): ZIP/Postal code
  - `ssn` (string): Social Security Number
- **Success Response**: HTTP 201 Created
- **Usage**: User registration
- **Frontend Usage**: Signup form submission

### 2. Contacts Service APIs

#### Get User Contacts
- **Endpoint**: `GET /contacts/{username}`
- **Authentication**: 🔒 Required
- **Path Parameters**:
  - `username` (string): Username of the contact owner
- **Success Response**:
  ```json
  [
    {
      "label": "Friend Name",
      "account_num": "1234567890",
      "routing_num": "123456789",
      "is_external": false
    }
  ]
  ```
- **Usage**: Load saved contacts for dropdown menus
- **Frontend Usage**: Home page load, payment/deposit forms

#### Add Contact
- **Endpoint**: `POST /contacts/{username}`
- **Authentication**: 🔒 Required
- **Content-Type**: `application/json`
- **Path Parameters**:
  - `username` (string): Username of the contact owner
- **Request Body**:
  ```json
  {
    "label": "Friend Name",
    "account_num": "1234567890",
    "routing_num": "123456789",
    "is_external": false
  }
  ```
- **Success Response**: HTTP 201 Created
- **Usage**: Save new contact when making payments/deposits
- **Frontend Usage**: Payment/deposit forms when adding new recipients

### 3. Balance Reader Service APIs

#### Get Account Balance
- **Endpoint**: `GET /balances/{account_id}`
- **Authentication**: 🔒 Required
- **Path Parameters**:
  - `account_id` (string): Account identifier from JWT token
- **Success Response**:
  ```json
  {
    "balance": 50000,  // Balance in cents
    "account_id": "1234567890"
  }
  ```
- **Usage**: Display current account balance
- **Frontend Usage**: Home page load (concurrent with other APIs)

### 4. Ledger Writer Service APIs

#### Submit Transaction
- **Endpoint**: `POST /transactions`
- **Authentication**: 🔒 Required
- **Content-Type**: `application/json`
- **Request Body**:
  ```json
  {
    "fromAccountNum": "1234567890",
    "fromRoutingNum": "123456789",
    "toAccountNum": "9876543210", 
    "toRoutingNum": "123456789",
    "amount": 5000,  // Amount in cents
    "uuid": "unique-transaction-id"
  }
  ```
- **Success Response**: HTTP 201 Created
- **Usage**: Process both payments and deposits
- **Frontend Usage**: 
  - Payment form submission (internal transfers)
  - Deposit form submission (external deposits)

### 5. Transaction History Service APIs

#### Get Transaction History
- **Endpoint**: `GET /transactions/{account_id}`
- **Authentication**: 🔒 Required
- **Path Parameters**:
  - `account_id` (string): Account identifier from JWT token
- **Success Response**:
  ```json
  [
    {
      "fromAccountNum": "1234567890",
      "toAccountNum": "9876543210",
      "amount": 5000,
      "timestamp": "2024-01-15T10:30:00.000Z",
      "uuid": "transaction-uuid"
    }
  ]
  ```
- **Usage**: Display transaction history on home page
- **Frontend Usage**: Home page load (concurrent with other APIs)

## Frontend API Usage Patterns

### 1. Home Page Load (Parallel Execution)
When a user visits the home page, the frontend makes 3 concurrent API calls:

```python
# Executed in parallel using ThreadPoolExecutor
api_calls = [
    GET /balances/{account_id}        # Get current balance
    GET /transactions/{account_id}    # Get transaction history  
    GET /contacts/{username}          # Get saved contacts
]
```

### 2. Payment Flow
1. **User submits payment form**
2. **If new contact**: `POST /contacts/{username}` (add contact)
3. **Submit transaction**: `POST /transactions` (process payment)
4. **Redirect to home** (triggers parallel load)

### 3. Deposit Flow
1. **User submits deposit form**
2. **If new external contact**: `POST /contacts/{username}` (add external contact)
3. **Submit transaction**: `POST /transactions` (process deposit)
4. **Redirect to home** (triggers parallel load)

### 4. Login Flow
1. **User submits login form**
2. **Authenticate**: `GET /login?username=x&password=y`
3. **Store JWT token** in HTTP-only cookie
4. **Redirect to home** (triggers authenticated parallel load)

### 5. Registration Flow
1. **User submits signup form**
2. **Create user**: `POST /users` (with form data)
3. **Auto-login**: `GET /login` (same credentials)
4. **Redirect to home** (triggers parallel load)

## Error Handling

### HTTP Status Codes
- **200 OK**: Successful GET requests
- **201 Created**: Successful POST requests
- **401 Unauthorized**: Invalid/missing JWT token
- **4XX Client Error**: Invalid request data
- **5XX Server Error**: Backend service issues

### Frontend Error Responses
- **Authentication Errors**: Redirect to login page
- **Validation Errors**: Display user-friendly error messages
- **Network Errors**: Show "operation failed" messages
- **Timeout**: 4-second default timeout per request

## Performance Optimizations

### Concurrent API Calls
- **Home page**: 3 APIs called in parallel using `ThreadPoolExecutor`
- **Max workers**: 3 concurrent threads
- **Timeout**: Individual timeouts per API call

### Transaction Processing Delays
```python
# 250ms delay after transaction submission
# Allows time for data propagation to balance/history services
sleep(0.25)
```

### Contact Label Population
- Transaction history enhanced with contact labels client-side
- Reduces additional API calls to contacts service

## Security Considerations

### JWT Token Validation
- **Signature verification**: Uses RSA public key
- **Expiration checking**: Automatic logout on expired tokens
- **Secure storage**: HTTP-only cookies prevent XSS

### Request Validation
- **Input sanitization**: Form data validated before API calls
- **Amount validation**: Decimal amounts converted to integer cents
- **Routing number validation**: External routing numbers verified

### Error Information Disclosure
- **Generic error messages**: Detailed errors logged server-side only
- **Token extraction**: JWT claims extracted safely with error handling

## Configuration

### Environment Variables
```bash
# Backend service addresses (internal cluster DNS)
TRANSACTIONS_API_ADDR=ledgerwriter:8080
USERSERVICE_API_ADDR=userservice:8080  
BALANCES_API_ADDR=balancereader:8080
HISTORY_API_ADDR=transactionhistory:8080
CONTACTS_API_ADDR=contacts:8080

# Authentication
PUB_KEY_PATH=/tmp/.ssh/publickey
LOCAL_ROUTING_NUM=123456789

# Performance  
BACKEND_TIMEOUT=4  # seconds
```

### Default Values
- **Backend timeout**: 4 seconds (8 seconds for login)
- **Token cookie name**: `token`
- **Consent cookie name**: `consented`
- **JWT algorithm**: RS256

## Testing with External APIs

When using the external API setup (`./external-api-setup.sh`), replace internal service names with external IPs:

```bash
# Example with external IPs
USERSERVICE_IP=34.123.456.789
curl "http://${USERSERVICE_IP}:8080/login?username=testuser&password=password123"

TOKEN=$(curl -s "http://${USERSERVICE_IP}:8080/login?username=testuser&password=password123" | jq -r '.token')

curl -H "Authorization: Bearer $TOKEN" \
     "http://${BALANCEREADER_IP}:8080/balances/1234567890"
```

## API Response Times

### Typical Response Times
- **Login**: 100-300ms
- **Balance lookup**: 50-150ms  
- **Transaction history**: 100-400ms (depends on history size)
- **Contact list**: 50-100ms
- **Transaction submission**: 200-500ms (includes validation)

### Timeout Configuration
- **Standard requests**: 4 seconds
- **Login requests**: 8 seconds (double timeout)
- **Transaction propagation delay**: 250ms

🔒 = Requires JWT authentication in `Authorization: Bearer <token>` header