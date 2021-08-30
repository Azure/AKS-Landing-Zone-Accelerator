###############
# For creation of new groups
###############

 resource "azuread_group" "appdevs" {
   display_name = var.aks_admin_group
   security_enabled=true
 }


 resource "azuread_group" "aksops" {
   display_name = var.aks_user_group
   security_enabled=true
 }

 output "appdev_object_id" {
     value = azuread_group.appdevs.object_id
 }

 output "aksops_object_id" {
     value = azuread_group.aksops.object_id
 }


#################
# For importing existing groups
##################

#data "azuread_group" "appdevs" {
#  display_name = var.aks_user_group  
#}

#data "azuread_group" "aksops" {
#  display_name = var.aks_admin_group 
#}

#output "appdev_object_id" {
#    value = data.azuread_group.appdevs.object_id
#}

#output "aksops_object_id" {
#    value = data.azuread_group.aksops.object_id
#}

