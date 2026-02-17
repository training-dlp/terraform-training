module "storage_dev" {
  # Reference a specific tag so dev doesn't break when you update the module
  source = "git::https://github.com/training-dlp/tfmodule.git?ref=v1.0.0"

  st_name  = "devsa"
  env      = "dev"
  tier     = "Standard"
}
