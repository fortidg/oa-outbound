##############################################################################################################
#
# DRGv2 Hub and Spoke traffic inspection
# FortiGate Active/Active Load Balanced pair of standalone FortiGate VMs for resilience and scale
# Terraform deployment template for Oracle Cloud
#
##############################################################################################################

//  Default Username and Password
output "Default_Username" {
  value = "admin"
}
output "Default_Password_FGT_A" {
  value = oci_core_instance.vm_fgt_a.id
}
output "Default_Password_FGT_B" {
  value = oci_core_instance.vm_fgt_b.id
}

output "Default_Password_FGT_C" {
  value = oci_core_instance.vm_fgt_c.id
}
output "Default_Password_FGT_D" {
  value = oci_core_instance.vm_fgt_d.id
}

// FortiGate A
output "FGTAMGMTPublicIP" {
  value = oci_core_instance.vm_fgt_a.*.public_ip
}

// FortiGate B
output "FGTBMGMTPublicIP" {
  value = oci_core_instance.vm_fgt_b.*.public_ip
}

// FortiGate C
output "FGTCMGMTPublicIP" {
  value = oci_core_instance.vm_fgt_c.*.public_ip
}

// FortiGate D
output "FGTDMGMTPublicIP" {
  value = oci_core_instance.vm_fgt_d.*.public_ip
}