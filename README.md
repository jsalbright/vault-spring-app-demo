# vault-spring-app-demo
A simple playbook to deploy a dummy app to demonstrate provisioning with Hashicorp Vault secrets and Ansible using Token-based authentication.

## Setup

* First, we must provision our Vault cluster using the playbook found [here](https://github.com/contino/vault-cluster-playbook.git):
```
$ git clone https://github.com/contino/vault-cluster-playbook.git
$ cd vault-cluster-playbook
$ ansible-galaxy install -p ./roles -r requirements.yml
$ kitchen converge
```

* Next, we must login to one of our Vault nodes and unseal our newly provisioned Vault cluster.
```
$ kitchen login cluster-01
$ vault init
$ vault unseal (Key 1)
$ vault unseal (Key 2)
$ vault unseal (Key 3)
```

* Now we must export our Root token so that we can create a new Token for our ansible playbook to use during playbook runs:
```
export VAULT_TOKEN=(Root token)
```

* Next, we need to enable the [AppRole Authentication Backend](https://www.vaultproject.io/docs/auth/approle.html) and create a new role, so that we can assign new client Tokens to a specific role:
```
$ vault auth-enable approle
$ vault write auth/approle/role/ansible-controller secret_id_ttl=24h token_num_uses=512 token_ttl=12h token_max_ttl=24h secret_id_num_uses=512
```
 * __NOTE__:  The various TTLs in the above command are NOT SAFE for real-world usage and must be modified according to your organization's security policies!


* Now we need to obtain our role_id for the new role that we created:

```
$ vault read auth/approle/role/ansible-controller/role-id
Key     Value
---     -----
role_id bd956d5b-4c5a-4047-39c9-0489a10cc4da
```

* Next, we need to issue a SecretID against our new AppRole:

```
$ vault write -f auth/approle/role/ansible-controller/secret-id
Key                     Value
---                     -----
secret_id               01eda028-88b7-b483-9eec-b6ce7a65548b
secret_id_accessor      e748acec-5a83-85ad-6360-e4f3b4920d6a
```

* Now, we just need to authenticate our new role via writing our SecretID and RoleID to the Vault login path for AppRole:

```
vault write auth/approle/login role_id=bd956d5b-4c5a-4047-39c9-0489a10cc4da secret_id=01eda028-88b7-b483-9eec-b6ce7a65548b
Key                     Value
---                     -----
token                   7f89ec0e-5e78-153e-6026-7e963f0b670b
token_accessor          9c42e38f-a9b2-05b9-de3b-86c25ddf56dd
token_duration          12h0m0s
token_renewable         true
token_policies          [default]
token_meta_role_name    "ansible-controller"
```

* Next, we need to create a new Token for our playbook to use for authentication so that it can retrieve the secrets that we need during our provisioning tasks:
```
vault token-create -id="00000000-0000-0000-0000-000000000000" -policy="root"
```
