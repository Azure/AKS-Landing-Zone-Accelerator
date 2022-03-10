
resource "random_string" "strc_suffix" {
  length  = 4
  upper   = false
  number  = true
  lower   = true
  special = false
}

# Use a random name for strorage account name, to prevent conflict with exisitng names 
locals{
  random_stracc_name                     = "${var.backups_stracc_name}${random_string.strc_suffix.result}"

}
