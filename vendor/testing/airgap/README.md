#

## Setup

### Clone this repo

```
git clone git@github.com:replicated-collab/terraform.git
```

### Set the Google Token

Terraform uses a Google bucket to save state. You will need a token to access to that bucket.

First, download the service account token for that bucket.

Next, set an environment variable in your shell to provide the path to that token.

```
GOOGLE_APPLICATION_CREDENTIALS="Users/todd/.terraform.json"
```

### Init

Initialize the repo with information Terraform needs to run.

```
terraform init
```

Eventually you should see the following

  **Terraform has been successfully initialized!**


