##############################################################################################################
#
# DRGv2 Hub and Spoke traffic inspection
# FortiGate Active/Active Load Balanced pair of standalone FortiGate VMs for resilience and scale
# Terraform deployment template for Oracle Cloud
#
##############################################################################################################

# Prefix for all resources created for this deployment in Microsoft Azure
variable "PREFIX" {
  description = "Added name to each deployed resource"
}

variable "region" {
  description = "Oracle Cloud region"
  default = ""
}

##############################################################################################################
# Oracle Cloud configuration
##############################################################################################################

variable "tenancy_ocid" {}
variable "compartment_ocid" {}
variable "user_ocid" {
  default = ""
}
variable "private_key_path" {
  default = ""
}
variable "fingerprint" {
  default = ""
}

##############################################################################################################
# UBU stuff
##############################################################################################################

variable "ssh_public_key_file" {
  default = "/home/ubuntu/.ssh/ssh-key-2022-12-15.key.pub"
}

variable "ubu-image" {
  default = "ocid1.image.oc1.iad.aaaaaaaa65w7hi5ph6gnddni5i6xijrpwinihowqerkasdsaslxo376ris2q"
}

variable "ubu_shape" {
  type    = string
  default = "VM.Standard1.2"
}


##############################################################################################################
# FortiGate instance type
##############################################################################################################
variable "instance_shape" {
  type    = string
  default = "VM.Standard.E4.Flex"
}

variable "mp_listing_id" {
  default = "ocid1.appcataloglisting.oc1..aaaaaaaam7ewzrjbltqiarxukuk72v2lqkdtpqtwxqpszqqvrm7likfnpt5q" //byol
}

variable "mp_listing_resource_id" {
  default = "ocid1.image.oc1..aaaaaaaa5m67jbvb33hoxpefr7fhfhf7gaeie4xjg7p4heixg25osr5warcq"
}

// Version
variable "mp_listing_resource_version" {
  default = "7.2.4_(_X64_)"
}
// Cert use for SDN Connector setting
variable "cert" {
  type    = string
  default = "Fortinet_Factory"
}

##############################################################################################################
# FortiGate license type
##############################################################################################################

// license file location for fgt a
variable "fgt_byol_license_a" {
  // Change to your own path
  type    = string
  default = ""
}

// license file location for fgt b
variable "fgt_byol_license_b" {
  // Change to your own path
  type    = string
  default = ""
}

// license file location for fgt a
variable "fgt_byol_license_c" {
  // Change to your own path
  type    = string
  default = ""
}

// license file location for fgt b
variable "fgt_byol_license_d" {
  // Change to your own path
  type    = string
  default = ""
}

// Flex-VM license token for fgt a
variable "fgt_byol_flexvm_license_a" {
  // Change to your own path
  type    = string
  default = ""
}

// Flex-VM license token for fgt b
variable "fgt_byol_flexvm_license_b" {
  // Change to your own path
  type    = string
  default = ""
}

// Flex-VM license token for fgt c
variable "fgt_byol_flexvm_license_c" {
  // Change to your own path
  type    = string
  default = ""
}

// Flex-VM license token for fgt d
variable "fgt_byol_flexvm_license_d" {
  // Change to your own path
  type    = string
  default = ""
}
##############################################################################################################
# VCN and SUBNET ADDRESSESS
##############################################################################################################

variable "vcn" {
  default = "172.16.140.0/22"
}

variable "subnet" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.142.0/24" # INLB
    "2" = "172.16.140.0/24" # Untrusted
    "3" = "172.16.141.0/24" # Trusted
  }
}

variable "subnetmask" {
  type        = map(string)
  description = ""

  default = {
    "2" = "24" # Untrusted
    "3" = "24" # Trusted
  }
}

variable "gateway" {
  type        = map(string)
  description = ""

  default = {
    "2" = "172.16.140.1" # Untrusted
    "3" = "172.16.141.1" # Trusted
  }
}

variable "fgt_ipaddress_a" {
  type        = map(string)
  description = ""

  default = {
    "2" = "172.16.140.45" # Untrusted
    "3" = "172.16.141.45" # Trusted
  }
}

variable "fgt_ipaddress_b" {
  type        = map(string)
  description = ""

  default = {
    "2" = "172.16.140.46" # Untrusted
    "3" = "172.16.141.46" # Trusted
  }
}

variable "fgt_ipaddress_c" {
  type        = map(string)
  description = ""

  default = {
    "2" = "172.16.140.47" # Untrusted
    "3" = "172.16.141.47" # Trusted
  }
}

variable "fgt_ipaddress_d" {
  type        = map(string)
  description = ""

  default = {
    "2" = "172.16.140.48" # Untrusted
    "3" = "172.16.141.48" # Trusted
  }
}

variable "trusted_nlb_ipaddress" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.141.69" # Trusted
  }
}

variable "vcn_cidr_spoke1" {
  type    = string
  default = "172.16.144.0/22"
}

variable "spoke1-subnet" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.144.0/24"  #sub1
    "2" = "172.16.145.0/24" #sub2
    "3" = "172.16.146.0/24" #sub3
  }
}
variable "vcn_cidr_spoke2" {
  type    = string
  default = "172.16.148.0/22"
}

variable "spoke2-subnet" {
  type        = map(string)
  description = ""

  default = {
    "1" = "172.16.148.0/24"  #sub1
    "2" = "172.16.149.0/24" #sub2
    "3" = "172.16.150.0/24" #sub3
  }
}

# Choose an Availability Domain (1,2,3)
variable "availability_domain" {
  type    = string
  default = "1"
}

/* variable "availability_domain2" {
  type    = string
  default = "2"
} */

variable "volume_size" {
  type    = string
  default = "50" //GB; you can modify this, can't less than 50
}

variable "drg_attachment_network_details_vcn_route_type" {
  type = string
  default = "VCN_CIDRS"
}
