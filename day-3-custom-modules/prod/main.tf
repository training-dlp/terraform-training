module "storage_prod" {
  source = "git::https://github.com/training-dlp/tfmodule.git?ref=v1.0.0"

  st_name  = "prodsa"
  env      = "prod"
  tier     = "Premium" # Higher tier for production
}
