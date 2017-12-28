# vault-spring-app-demo
A simple playbook to deploy a dummy app/config-file to demonstrate provisioning with Hashicorp Vault secrets and Ansible using Token-based authentication.  The playbook will pull a secret from Vault at runtime using a policy-controlled Vault Token.

## Setup

* First, we must provision our local Vault cluster using the playbook found [here](https://github.com/contino/vault-cluster-playbook.git):
```
$ git clone https://github.com/contino/vault-cluster-playbook.git
$ cd vault-cluster-playbook
$ ansible-galaxy install -p ./roles -r requirements.yml
$ kitchen converge
```

* Next, we must login to one of our Vault nodes and unseal our newly provisioned Vault cluster.  Be sure to copy the Root-Token for later!
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

* Create our simple policy-file locally on the Vault node:
```
echo -e "path \"secret/*\" {\n  capabilities = [\"create\", \"read\", \"update\", \"delete\", \"list\"]\n}" > my-app-policy.hcl
```

* Next, we need to write our new policy to our Vault cluster:
```
vault write sys/policy/my-app-policy rules=@my-app-policy.hcl
```

* Now we can create our new Token:
```
vault token-create -policy="my-app-policy"
```

* We have successfully added our policy and now we'll add some data using our new Token:
```
vault write secret/my-app/password value=itsasecret
```

* Now that we have created a policy-controlled token and added some data to our Vault cluster, we can run our playbook!
