# Copyright 2021 SchedMD LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

##########
# LOCALS #
##########

local "ssh_passwords" {
  expression = var.builds.*.ssh_password
  sensitive  = true
}

###########
# GENERAL #
###########

variable "project" {
  type = string
}

variable "zone" {
  type = string
}

#########
# IMAGE #
#########

variable "source_image_project_id" {
  type    = list(string)
  default = null
}

variable "skip_create_image" {
  type    = bool
  default = false
}

###########
# NETWORK #
###########

variable "network_project_id" {
  description = "The project ID for the network and subnetwork to use for launched instance."
  type        = string
  default     = null
}

variable "subnetwork" {
  description = "The subnetwork ID or URI to use for the launched instance."
  type        = string
  default     = null
}

variable "tags" {
  description = "Assign network tags to apply firewall rules to VM instance."
  type        = list(string)
  default     = null
}

#############
# PROVISION #
#############

variable "slurm_version" {
  description = "Slurm version by git branch"
  type        = string
  default     = "slurm-20.11"
}

##########
# BUILDS #
##########

variable "builds" {
  type = list(object({
    ### image ###
    source_image        = string
    source_image_family = string
    image_licenses      = list(string)
    labels              = map(string)

    ### ssh ###
    ssh_username = string
    ssh_password = string # sensitive

    ### instance ###
    machine_type = string
    preemptible  = bool

    ### root fo trust ###
    enable_secure_boot          = bool
    enable_vtpm                 = bool
    enable_integrity_monitoring = bool

    ### storage ###
    disk_size = number
    disk_type = string
  }))
}
