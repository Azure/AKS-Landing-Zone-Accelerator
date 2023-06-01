# It's based on the CAF Terraform Provider https://github.com/aztfmod/terraform-provider-azurecaf
# The naming convention is following the CAF recommendations: https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming

terraform {
  required_version = ">= 1.2.0"
}

data "http" "cafDefinition" {
  url = "https://raw.githubusercontent.com/aztfmod/terraform-provider-azurecaf/main/resourceDefinition.json"
}

locals {
  customResources = jsondecode(file("${abspath(path.module)}/customResources.json"))
  replaceSlugs    = jsondecode(file("${abspath(path.module)}/replaceSlugs.json"))
  jsoncontent     = jsondecode(data.http.cafDefinition.response_body)

  jsonresources = {
    for resourcetype, resource in concat(local.jsoncontent, local.customResources) : resource.name => {
      slug      = resource.slug
      separator = resource.dashes == true ? "-" : ""
      lowercase = resource.lowercase

      regex            = replace(substr(resource.regex, 1, length(resource.regex) - 2), "\\\\", "\\")
      max_length       = resource.max_length
      min_length       = resource.min_length
      validation_regex = resource.validation_regex
      scope            = resource.scope
      dashes           = resource.dashes
    }
  }

  resources_with_customizations = {
    for resourcetype, resource in local.jsonresources : resourcetype => merge(
      resource,
      try(local.replaceSlugs[resourcetype], null)
    ) if try(local.replaceSlugs[resourcetype].exclude, false) != true
  }

  resources_with_basename = {
    for resourcetype, resource in local.resources_with_customizations : resourcetype => merge(
      resource,
      {
        name = resource.max_length <= 9 ? join(resource.separator, compact([resource.slug, var.instance])) : (resource.max_length > 9 && resource.max_length <= 16 ? join(resource.separator, compact([resource.slug, var.environment, var.instance])) : join(
          resource.separator,
          compact([
            resource.slug,
            var.workload,
            var.environment,
            var.region,
            var.instance
          ])
        ))
      }
    )
  }

  resources_with_tolower = {
    for resourcetype, resource in local.resources_with_basename : resourcetype => merge(
      resource,
      {
        name = resource.lowercase ? lower(resource.name) : resource.name
      }
    )
  }

  resources_with_regex = {
    for resourcetype, resource in local.resources_with_tolower : resourcetype => merge(
      resource,
      {
        name    = try(replace(resource.name, regex(resource.regex, resource.name), ""), resource.name)
        toolong = length(try(replace(resource.name, regex(resource.regex, resource.name), ""), resource.name)) <= resource.max_length ? false : true
      }
    )
  }

  resources = local.resources_with_regex

}
