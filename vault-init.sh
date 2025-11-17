#!/bin/sh
# Vault initialization and unsealing script

set -e

echo "Waiting for Vault to be ready..."
sleep 5

# Check if Vault is already initialized
if vault status 2>/dev/null | grep -q "Initialized.*true"; then
    echo "Vault is already initialized"
    
    # Try to unseal if sealed
    if vault status 2>/dev/null | grep -q "Sealed.*true"; then
        echo "Vault is sealed, attempting auto-unseal..."
        # In production, use auto-unseal with cloud KMS
        # For now, operator must unseal manually
        echo "⚠️  Manual unseal required: vault operator unseal"
    else
        echo "✅ Vault is unsealed and ready"
    fi
else
    echo "Initializing Vault..."
    vault operator init -key-shares=5 -key-threshold=3 > /vault/data/init-keys.txt
    
    echo "✅ Vault initialized. Keys saved to /vault/data/init-keys.txt"
    echo "⚠️  BACKUP THESE KEYS IMMEDIATELY!"
    echo ""
    echo "To unseal Vault, run:"
    echo "  vault operator unseal <key1>"
    echo "  vault operator unseal <key2>"
    echo "  vault operator unseal <key3>"
fi

# Enable transit engine for encryption
if ! vault status 2>/dev/null | grep -q "Sealed.*false"; then
    echo "Cannot configure Vault while sealed"
    exit 0
fi

echo "Configuring transit encryption engine..."
vault secrets enable -path=transit transit 2>/dev/null || echo "Transit engine already enabled"

# Create encryption key for secrets
vault write -f transit/keys/smarteros-secrets 2>/dev/null || echo "Encryption key already exists"

echo "✅ Vault configuration complete"
