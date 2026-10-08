# GCP test environment

A small, single-market Terraform setup for a personal GCP project. It uses
the same layout as a larger multi-market repo (`envs/` → `projects/` →
`modules/`), with CI that plans on PRs and applies on `main`.

```
bootstrap/                  one-time: APIs, state bucket, deployer SA, GitHub OIDC (WIF)
envs/test/                  root CI runs: backend + one module call per market
projects/test/app/us/       the US market: network + buckets + VMs
modules/
  network/                  private VPC, one subnet, IAP-only SSH, optional Cloud NAT
  gcs_bucket/               buckets; writers always get objectAdmin + legacyBucketReader
  compute/                  standalone VMs (one SA each), extra disks, daily snapshots
.github/workflows/terraform-test.yml
```

## What gets created (envs/test)

| Resource | Name |
|---|---|
| VPC / subnet | `vpc-tst-us` / `snet-tst-us-app` (10.10.0.0/24, Private Google Access) |
| Firewall | `fw-tst-us-allow-iap-ssh` (tcp:22 from IAP only) |
| VM | `g-tst-us-app-general-a-001` (e2-micro, Debian 12, no public IP) |
| VM SA | `tst-us-vm-01@<project>.iam.gserviceaccount.com` |
| Workspace disk | `g-tst-us-app-general-a-001-workspace` (10 GB → `/opt/workspace`) |
| Buckets | `<project>-tst-us-data` (versioned), `<project>-tst-us-staging` (7-day expiry) |
| Snapshots | `g-tst-us-app-daily-snap` (daily, 3-day retention) |

It's sized to fit the free tier (e2-micro in us-central1 with 30 GB of
pd-standard). Snapshots cost a few cents. Cloud NAT is **off** by default
(about $1/day); turn it on with `enable_nat = true` if the VM needs apt or pip.

## Setup

### 1. Bootstrap (once, from Cloud Shell, logged in as yourself)

```bash
git clone https://github.com/abhishek-donekal/Gcp_test && cd Gcp_test/bootstrap
cp terraform.tfvars.example terraform.tfvars   # set project_id
terraform init && terraform apply
terraform output
```

Bootstrap keeps **local** state. Keep `bootstrap/terraform.tfstate` safe.

### 2. GitHub repo variables

Settings → Secrets and variables → Actions → **Variables** tab:

| Variable | Value |
|---|---|
| `GCP_PROJECT_ID` | from `terraform output` |
| `GCP_WIF_PROVIDER` | from `terraform output` |
| `GCP_DEPLOYER_SA` | from `terraform output` |
| `TF_STATE_BUCKET` | from `terraform output` |
| `IAP_MEMBERS` | `["user:you@gmail.com"]` |

None of these are secrets. Auth uses OIDC, so no JSON keys are involved.
Until the variables exist, CI runs only `fmt` and `validate`.

### 3. Deploy

- **PR** → `validate` + `pr-plan` (plan shown in the job summary)
- **Merge to `main`** → `deploy-plan` → `deploy-apply` (applies the saved plan)
- **Actions → terraform-test → Run workflow** to plan and apply by hand

To require a manual approval before apply, add required reviewers to the
`test` environment in repo settings.

### 4. Use it

```bash
gcloud compute ssh g-tst-us-app-general-a-001 --zone us-central1-a --tunnel-through-iap
echo $DATA_BUCKET && gsutil ls $DATA_BUCKET     # works: SA has both bucket roles
```

## Local runs (optional)

```bash
cd envs/test
cp terraform.tfvars.example terraform.tfvars
terraform init -backend-config="bucket=<project-id>-tfstate"
terraform plan
```

## Common changes

- **Add a VM:** add a key to `gce_instances` in `projects/test/app/us/main.tf`
  (there's a commented `vm-02` example). Existing VMs aren't touched, the new VM
  gets its own SA and bucket access, and its disks join the snapshot policy.
- **Change a machine type:** edit `machine_type`. The VM stops and restarts in
  place (`allow_stopping_for_update`).
- **Edit startup.sh:** it's delivered via metadata, so it updates in place on
  the next boot. No rebuild.
- **Add a market:** copy `projects/test/app/us` to e.g. `.../eu`, change
  `market_code`, `region` and `subnet_cidr`, and add a `module "app-eu"` in
  `envs/test/project-call.tf`.

## Tear down

```bash
cd envs/test && terraform destroy     # buckets have force_destroy = true
cd ../../bootstrap && terraform destroy
```
