# About 

This is a small setup to use Vault server, Vault Agent runing on Docker (docker compose) using static and dynamic secrets (KV2, Postgres, MySql).

# How To Run

```
docker-compose up
```

After it's started, execute these commands: 



```
export VAULT_ADDR=http://localhost:8200
export VAULT_TOKEN=root
```

```
vault auth enable approle
vault write auth/approle/role/agent token_policies="nginx-agent-policy"
vault read --field=role_id auth/approle/role/agent/role-id > ./agent/role-id
vault write --field=secret_id -f auth/approle/role/agent/secret-id > ./agent/secret-id
```

#### Generate KV2 Secrets


```
 vault kv put secret/nginx/front-page foo=bar app=nginx username=user password=pass
```

### Create Policy

```
vault policy write nginx-agent-policy ./vault/policy.hcl
```

# PostgreSQL

```
vault secrets enable -path=postgres database
```

```
vault write postgres/config/products \
    plugin_name=postgresql-database-plugin \
    allowed_roles="*" \
    connection_url="postgresql://{{username}}:{{password}}@postgres:5432/products?sslmode=disable" \
    username="postgres" \
    password="pass"
```


## Create a Role for Nginx

```
vault write postgres/roles/nginx \
  db_name=products \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
  GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\"" \
  default_ttl="30s" \
  max_ttl="24h"
```

# MySql

```
vault secrets enable -path=mysql database
```

```
vault write mysql/config/items \
    plugin_name=mysql-database-plugin \
    connection_url="{{username}}:{{password}}@tcp(mysql:3306)/" \
    allowed_roles="nginx" \
    username="root" \
    password="pass"
```

```
vault write mysql/roles/nginx \
    db_name=items \
    creation_statements="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT ON *.* TO '{{name}}'@'%';" \
    default_ttl="1h" \
    max_ttl="24h"
```