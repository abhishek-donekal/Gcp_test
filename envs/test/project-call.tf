# One module call per market/workload. This test env has a single market.
# CI plans on any change under envs/, projects/ or modules/ — no need to bump
# a comment here to trigger a run.

module "app-us" {
  source = "../../projects/test/app/us"

  project_id  = var.project_id
  region      = var.region
  iap_members = var.iap_members
  enable_nat  = var.enable_nat
}
