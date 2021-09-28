
#################
# For importing existing groups
##################

data "azuread_group" "appdevs" {
 display_name = var.aks_user_group  
}

data "azuread_group" "aksops" {
 display_name = var.aks_admin_group 
}

output "appdev_object_id" {
   value = data.azuread_group.appdevs.object_id
}

output "aksops_object_id" {
   value = data.azuread_group.aksops.object_id
}

