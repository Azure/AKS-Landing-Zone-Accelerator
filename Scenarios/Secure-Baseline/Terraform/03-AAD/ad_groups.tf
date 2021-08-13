###############
# For creation of new groups
###############

# resource "azuread_group" "appdevs" {
#   display_name = "AKS App Dev Team"
# }


# resource "azuread_group" "aksops" {
#   display_name = "AKS Operations Team"
# }

# output "appdev_object_id" {
#     value = azuread_group.appdevs.object_id
# }

# output "aksops_object_id" {
#     value = azuread_group.aksops.object_id
# }

#################
# For importing existing groups
##################

data "azuread_group" "appdevs" {
  display_name = "AKS App Dev Team"
}


data "azuread_group" "aksops" {
  display_name = "AKS Operations Team"
}

output "appdev_object_id" {
    value = data.azuread_group.appdevs.object_id
}

output "aksops_object_id" {
    value = data.azuread_group.aksops.object_id
}

