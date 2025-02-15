/**
 * Copyright (C) SchedMD LLC.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

###########
# GENERAL #
###########

variable "project_id" {
  type        = string
  description = "The ID of the project where this VPC will be created."
}

variable "network_name" {
  type        = string
  description = "The name of the network being created."
}

variable "routing_mode" {
  type        = string
  default     = "GLOBAL"
  description = "The network routing mode (default 'GLOBAL')"
}

variable "shared_vpc_host" {
  type        = bool
  description = "Makes this project a Shared VPC host if 'true' (default 'false')"
  default     = false
}

variable "subnets" {
  type        = list(map(string))
  description = "The list of subnets being created."
  default     = []
}

variable "secondary_ranges" {
  type = map(list(object({
    range_name    = string,
    ip_cidr_range = string
  })))
  description = "Secondary ranges that will be used in some of the subnets"
  default     = {}
}

variable "routes" {
  type        = list(map(string))
  description = "List of routes being created in this VPC."
  default     = []
}

variable "firewall_rules" {
  type        = list(map(string))
  description = "List of additional firewall rules."
  default     = []
}

variable "delete_default_internet_gateway_routes" {
  type        = bool
  description = <<EOD
If set, ensure that all routes within the network specified whose names begin
with 'default-route' and with a next hop of 'default-internet-gateway' are
deleted.
EOD
  default     = false
}


variable "description" {
  type        = string
  description = "An optional description of this resource. The resource must be recreated to modify this field."
  default     = ""
}

variable "auto_create_subnetworks" {
  type        = bool
  description = <<EOD
When set to true, the network is created in 'auto subnet mode' and it will
create a subnet for each region automatically across the 10.128.0.0/9
address range. When set to false, the network is created in 'custom subnet mode'
so the user can explicitly connect subnetwork resources.
EOD
  default     = false
}

variable "mtu" {
  type        = number
  description = <<EOD
The network MTU. Must be a value between 1460 and 1500 inclusive. If set to 0
(meaning MTU is unset), the network will default to 1460 automatically.
EOD
  default     = 0
}

variable "slurm_depends_on" {
  description = <<EOD
Custom terraform dependencies without replacement on delta. This is useful to
ensure order of resource creation.

NOTE: Also see terraform meta-argument 'depends_on'.
EOD
  type        = list(string)
  default     = []
}
