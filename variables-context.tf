variable "context" {
  description = "Provides standardized naming policy and attribute information for data source reference to define cloud resources for a Project."
  type        = object({
    region      = string
    project     = string
    name_prefix = string
    pri_domain  = string
    tags        = map(string)
  })
}
