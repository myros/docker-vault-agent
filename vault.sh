#!/bin/bash

echo "===> Setting ENV variables"

export VAULT_ADDR=http://localhost:8200
export VAULT_TOKEN=root


echo "===> Setting AppRole auth method...."

vault auth enable approle
vault write auth/approle/role/agent token_policies="nginx-agent-policy"

echo "===> Creating role-id and secret-id files...."
vault read --field=role_id auth/approle/role/agent/role-id > ./agent/role-id
vault write --field=secret_id -f auth/approle/role/agent/secret-id > ./agent/secret-id

echo "===> Setting up some secrets..."
vault kv put secret/nginx/front-page foo=bar app=nginx username=user password=pass

echo "===> Importing nginx-agent policy..."
vault policy write nginx-agent-policy ./vault/policy.hcl

echo "===> PostgreSQL database secret engine..."
vault secrets enable -path=postgres database
vault write postgres/config/products \
    plugin_name=postgresql-database-plugin \
    allowed_roles="*" \
    connection_url="postgresql://{{username}}:{{password}}@postgres:5432/products?sslmode=disable" \
    username="postgres" \
    password="pass"


vault write postgres/roles/nginx \
  db_name=products \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
  GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\"" \
  default_ttl="30s" \
  max_ttl="24h"

echo "===> MySql database secret engine..."
vault secrets enable -path=mysql database
vault write mysql/config/items \
    plugin_name=mysql-database-plugin \
    connection_url="{{username}}:{{password}}@tcp(mysql:3306)/" \
    allowed_roles="nginx" \
    username="root" \
    password="pass"
vault write mysql/roles/nginx \
    db_name=items \
    creation_statements="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT ON *.* TO '{{name}}'@'%';" \
    default_ttl="1h" \
    max_ttl="24h"