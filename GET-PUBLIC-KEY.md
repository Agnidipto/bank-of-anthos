# Retrieving JWT Public Key from Bank of Anthos Cluster

This guide shows how to retrieve the JWT public key from the Bank of Anthos Kubernetes cluster using CLI commands.

## Prerequisites

- `kubectl` installed and configured
- Access to the Kubernetes cluster
- Permissions to read secrets in the cluster

## Quick Command

```bash
kubectl get secret jwt-key -o jsonpath='{.data.jwtRS256\.key\.pub}' | base64 -d
```

## Step-by-Step Process

### 1. Verify Secret Exists
```bash
kubectl get secrets | grep jwt
```

### 2. View Secret Details
```bash
kubectl describe secret jwt-key
```

### 3. Extract Public Key
```bash
kubectl get secret jwt-key -o jsonpath='{.data.jwtRS256\.key\.pub}' | base64 -d
```

## Alternative Methods

### Save to File
```bash
kubectl get secret jwt-key -o jsonpath='{.data.jwtRS256\.key\.pub}' | base64 -d > public_key.pem
cat public_key.pem
```

### Using jq (if available)
```bash
kubectl get secret jwt-key -o json | jq -r '.data."jwtRS256.key.pub"' | base64 -d
```

## Expected Output

```
-----BEGIN PUBLIC KEY-----
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA4GvZNSkj5iiWb2DZM2fC
x5bGGYgwaK4SMsyI8K8oFQepL13YROXKw5S+lELH9AetTdcTAdkbCzyapSdk3Pqw
xhCaf4knvKeRi76csG6mc0krx1GItY65X+Nq0qaRvLdOObFQGmIHx75zkZ654+ft
vnvCY5OPjV44Lktu1wlrBmr225QSFbIa8A96BSpJzKm0ahK+6r8VvvOq1BHGZIIK
KGQ7/zLuxPOn+c3wCF0VQY20Y4Xoo+DVt/+0MI8OZvdAuab2UXub+TiwAgG768yn
JPh7eklLtdtA1BGglXmoER4xvhhXQsORtTi60FZPX7C3V1rlUe+rU9BY6ClrWleJ
tgBf1XR/tBmLdfB4YVnKtzB7vLClOKultaduSVnfv8C0uz1zPBZIwXnsVO7XySVP
AJBT8PVGR3kbg9nEDk/rVlKYMInDSO8SHNyKO+k6pThmamoqMBJBCpcC+G1UPUqY
euK8w66ZSpKWfPctmYebPskiJbKeOrHVU2Dj7zzdimL2behqSwSi3zAklWf4FSAz
h/4zpD4Wq3ICwcXlPqa59OB0qqACx5AmEFlvQuUI0q6wZ6vrlAYK+Mdm4DvFAUlX
s5mfl6OFvtbFSdqurE6ItNVyRVQAlzXWmhC8GrWBIht1OJLWDKO5lvZmJQ/lk7bs
Ur4+2+NNnssMpnMB6C+Iz6sCAwEAAQ==
-----END PUBLIC KEY-----
```

## Notes

- The public key is used to verify JWT tokens issued by the userservice
- This key remains the same unless the cluster is recreated or the secret is manually regenerated
- Keep this key secure when using it in external applications

## Use Cases

- **External Applications**: Use this key to verify JWT tokens from Bank of Anthos APIs
- **Development**: Integrate with Bank of Anthos authentication system
- **Testing**: Validate JWT tokens in your test suite

## Troubleshooting

**"secret not found"**: Ensure you're connected to the correct cluster and namespace
**"permission denied"**: Check your RBAC permissions for reading secrets  
**"command not found"**: Install and configure kubectl

## Related Documentation

- [External API Access Guide](EXTERNAL-API-ACCESS.md) - How to expose APIs externally
- [Frontend API Documentation](FRONTEND-API-DOCUMENTATION.md) - Complete API reference