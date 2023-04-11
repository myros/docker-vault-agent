# This policy allows the nginx app to access Key/Value and Database Secrets engine

# List, create, update, and delete key/value secrets
path "secret/data/nginx/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Read dynamic database secrets (postgres)
path "postgres/creds/nginx"
{
  capabilities = ["read"]
}

# Read dynamic database secrets (mysql)
path "mysql/creds/nginx"
{
  capabilities = ["read"]
}