#############
# VARIABLES #
#############

variable "state_sa_name" {}

variable "container_name" {}

variable "access_key" {}

variable "arecords_apps_map" {
    type = map(object({
        aks_active_prefix = string
        record_name = string
    }))
    description = "The map of the A records associated to the apps deployed on AKS that are publically availaible via application gatewy public IP. The two main attributes are: aks_active_prefix that is used to map the record with the proper cluster, the second one is record_name that is the hostname to map, that need to match with the one configured on the app gtaeway and ingress controller"
}
