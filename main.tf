##############################################################################################################
#
# DRGv2 Hub and Spoke traffic inspection
# FortiGate Active/Active Load Balanced pair of standalone FortiGate VMs for resilience and scale
# Terraform deployment template for Oracle Cloud
#
##############################################################################################################

##############################################################################################################
## VCN
##############################################################################################################

resource "oci_core_virtual_network" "vcn" {
  cidr_block     = var.vcn
  compartment_id = var.compartment_ocid
  display_name   = "${var.PREFIX}-vcn"
  dns_label      = "fgthub"
}

resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.PREFIX}-igw"
  vcn_id         = oci_core_virtual_network.vcn.id
}


##############################################################################################################
## UNTRUSTED NETWORK
##############################################################################################################

resource "oci_core_subnet" "untrusted_subnet" {
  cidr_block        = var.subnet["2"]
  display_name      = "${var.PREFIX}-untrusted"
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_virtual_network.vcn.id
  route_table_id    = oci_core_route_table.untrusted_routetable.id
  security_list_ids = ["${oci_core_virtual_network.vcn.default_security_list_id}", "${oci_core_security_list.untrusted_security_list.id}"]
  dhcp_options_id   = oci_core_virtual_network.vcn.default_dhcp_options_id
  dns_label         = "fgtuntrusted"
}

resource "oci_core_route_table" "untrusted_routetable" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "${var.PREFIX}-untrusted-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.igw.id
  }
}

resource "oci_core_security_list" "untrusted_security_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "${var.PREFIX}-untrusted-security-list"

  // allow outbound tcp traffic on all ports
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }


  // allow inbound http (port 443) traffic
  ingress_security_rules {
    protocol = "6" // tcp
    source   = "0.0.0.0/0"

    tcp_options {
      min = 443
      max = 443
    }
  }

  // allow inbound http (port 8443) traffic
  ingress_security_rules {
    protocol = "6" // tcp
    source   = "0.0.0.0/0"

    tcp_options {
      min = 8443
      max = 8443
    }
  }

  // allow inbound ssh traffic
  ingress_security_rules {
    protocol  = "6" // tcp
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    protocol  = "6" // tcp
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      min = 10443
      max = 10443
    }
  }
}

##############################################################################################################
## TRUSTED NETWORK
##############################################################################################################

resource "oci_core_subnet" "trusted_subnet" {
  cidr_block     = var.subnet["3"]
  display_name   = "${var.PREFIX}-trusted"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  security_list_ids          = ["${oci_core_virtual_network.vcn.default_security_list_id}", "${oci_core_security_list.trusted_security_list.id}"]
  dhcp_options_id            = oci_core_virtual_network.vcn.default_dhcp_options_id
  dns_label                  = "fgttrusted"
  prohibit_public_ip_on_vnic = true
}

// route table attachment
resource "oci_core_route_table_attachment" "trust_route_table_attachment" {
  subnet_id      = oci_core_subnet.trusted_subnet.id
  route_table_id = oci_core_route_table.trusted_routetable.id
}

resource "oci_core_security_list" "trusted_security_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "fgt-internal-security-list"

  // allow outbound tcp traffic on all ports
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  // allow inbound all 
  ingress_security_rules {
    protocol = "all" // tcp
    source   = "0.0.0.0/0"
  }
}

##############################################################################################################
## INLB NETWORK
##############################################################################################################
/* resource "oci_core_subnet" "inlb_subnet" {
  cidr_block     = var.subnet["1"]
  display_name   = "${var.PREFIX}-inlb"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  security_list_ids          = ["${oci_core_virtual_network.vcn.default_security_list_id}", "${oci_core_security_list.trusted_security_list.id}"]
  dhcp_options_id            = oci_core_virtual_network.vcn.default_dhcp_options_id
  dns_label                  = "fgtinlb"
  prohibit_public_ip_on_vnic = true
}

// route table attachment
resource "oci_core_route_table_attachment" "inlb_route_table_attachment" {
  subnet_id      = oci_core_subnet.inlb_subnet.id
  route_table_id = oci_core_route_table.inlb_routetable.id
} */


##############################################################################################################
## SPOKE NETWORK
##############################################################################################################

resource "oci_core_virtual_network" "vcn_spoke1" {
  cidr_block     = var.vcn_cidr_spoke1
  compartment_id = var.compartment_ocid
  display_name   = "${var.PREFIX}-vcn-spoke1"
  dns_label      = "fgtspoke1"
}


resource "oci_core_subnet" "spoke1-sub1" {
  cidr_block     = var.spoke1-subnet["1"]
  display_name   = "${var.PREFIX}-spoke1-sub1"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn_spoke1.id
  dns_label                  = "spoke1sub1"
  prohibit_public_ip_on_vnic = true
}

// route table attachment
resource "oci_core_route_table_attachment" "spoke1_sub1_route_table_attachment" {
  subnet_id      = oci_core_subnet.spoke1-sub1.id
  route_table_id = oci_core_route_table.spoke1_routetable.id
}

resource "oci_core_subnet" "spoke1-sub2" {
  cidr_block     = var.spoke1-subnet["2"]
  display_name   = "${var.PREFIX}-spoke1-sub2"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn_spoke1.id
  dns_label                  = "spoke1sub2"
  prohibit_public_ip_on_vnic = true
}

// route table attachment
resource "oci_core_route_table_attachment" "spoke1_sub2_route_table_attachment" {
  subnet_id      = oci_core_subnet.spoke1-sub2.id
  route_table_id = oci_core_route_table.spoke1_routetable.id
}

resource "oci_core_subnet" "spoke1-sub3" {
  cidr_block     = var.spoke1-subnet["3"]
  display_name   = "${var.PREFIX}-spoke1-sub3"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn_spoke1.id
  dns_label                  = "spoke1sub3"
  prohibit_public_ip_on_vnic = true
}

// route table attachment
resource "oci_core_route_table_attachment" "spoke1_sub3_route_table_attachment" {
  subnet_id      = oci_core_subnet.spoke1-sub3.id
  route_table_id = oci_core_route_table.spoke1_routetable.id
}

resource "oci_core_virtual_network" "vcn_spoke2" {
  cidr_block     = var.vcn_cidr_spoke2
  compartment_id = var.compartment_ocid
  display_name   = "${var.PREFIX}-vcn-spoke2"
  dns_label      = "fgtspoke2"
}

resource "oci_core_subnet" "spoke2-sub1" {
  cidr_block     = var.spoke2-subnet["1"]
  display_name   = "${var.PREFIX}-spoke2-sub1"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn_spoke2.id
}

// route table attachment
resource "oci_core_route_table_attachment" "spoke2_sub1_route_table_attachment" {
  subnet_id      = oci_core_subnet.spoke2-sub1.id
  route_table_id = oci_core_route_table.spoke2_routetable.id
}


resource "oci_core_subnet" "spoke2-sub2" {
  cidr_block     = var.spoke2-subnet["2"]
  display_name   = "${var.PREFIX}-spoke2-sub2"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn_spoke2.id
}

// route table attachment
resource "oci_core_route_table_attachment" "spoke2_sub2_route_table_attachment" {
  subnet_id      = oci_core_subnet.spoke2-sub2.id
  route_table_id = oci_core_route_table.spoke2_routetable.id
}

resource "oci_core_subnet" "spoke2-sub3" {
  cidr_block     = var.spoke2-subnet["3"]
  display_name   = "${var.PREFIX}-spoke2-sub3"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn_spoke2.id
}

// route table attachment
resource "oci_core_route_table_attachment" "spoke2_sub3_route_table_attachment" {
  subnet_id      = oci_core_subnet.spoke2-sub3.id
  route_table_id = oci_core_route_table.spoke2_routetable.id
}

resource "oci_core_drg_attachment" "drg_spoke1_attachment" {
  drg_id = oci_core_drg.drg.id
  network_details {
    id = oci_core_virtual_network.vcn_spoke1.id
    type = "VCN"

  }
  display_name = "${var.PREFIX}-drg-spoke1-attachment"
  drg_route_table_id = oci_core_drg_route_table.drg_spoke_route_table.id
}

resource "oci_core_drg_attachment" "drg_spoke2_attachment" {
  drg_id = oci_core_drg.drg.id
  network_details {
    id = oci_core_virtual_network.vcn_spoke2.id
    type = "VCN"

  }
  display_name = "${var.PREFIX}-drg-spoke2-attachment"
  drg_route_table_id = oci_core_drg_route_table.drg_spoke_route_table.id
}

resource "oci_core_drg_route_table" "drg_spoke_route_table" {
  drg_id = oci_core_drg.drg.id
  display_name = "${var.PREFIX}-drg-spoke-route-table"
  /* import_drg_route_distribution_id = oci_core_drg_route_distribution.drg_spoke_route_distribution.id */
}

// Add DRG route distribution for OCI VCN
resource "oci_core_drg_route_distribution" "drg_spoke_route_distribution" {
  // Required
  drg_id = oci_core_drg.drg.id
  distribution_type = "IMPORT"
  // optional
  display_name = "${var.PREFIX}-drg-spoke-route-distribution"
}
resource "oci_core_drg_route_distribution_statement" "drg_spoke_route_distribution_statements" {
  // Required
  drg_route_distribution_id = oci_core_drg_route_distribution.drg_spoke_route_distribution.id
  action = "ACCEPT"
  match_criteria {
    drg_attachment_id = oci_core_drg_attachment.drg_hub_attachment.id
  }
  priority = 1
}


resource "oci_core_drg_route_table_route_rule" "drg_spoke_route_table_route_rule" {
    #Required
    drg_route_table_id = oci_core_drg_route_table.drg_spoke_route_table.id
    destination = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    next_hop_drg_attachment_id = oci_core_drg_attachment.drg_hub_attachment.id

}


##############################################################################################################
## DRG
##############################################################################################################

resource "oci_core_drg" "drg" {
  compartment_id = var.compartment_ocid
  display_name = "${var.PREFIX}-drg"
}

resource "oci_core_drg_route_table" "drg_hub_route_table" {
  drg_id = oci_core_drg.drg.id
  display_name = "${var.PREFIX}-drg-hub-route-table"
  import_drg_route_distribution_id = oci_core_drg_route_distribution.drg_hub_route_distribution.id
}

//Create DRG attachment for OCI VCN
resource "oci_core_drg_attachment" "drg_hub_attachment" {
  drg_id = oci_core_drg.drg.id
  network_details {
    id = oci_core_virtual_network.vcn.id
    type = "VCN"
    route_table_id = oci_core_route_table.hub_vcn_attach_routetable.id
    vcn_route_type = var.drg_attachment_network_details_vcn_route_type
  }
  display_name = "${var.PREFIX}-drg-hub-attachment"
  drg_route_table_id = oci_core_drg_route_table.drg_hub_route_table.id
}

// Add DRG route distribution for OCI VCN
resource "oci_core_drg_route_distribution" "drg_hub_route_distribution" {
  // Required
  drg_id = oci_core_drg.drg.id
  distribution_type = "IMPORT"
  // optional
  display_name = "${var.PREFIX}-drg-hub-route-distribution"
}
resource "oci_core_drg_route_distribution_statement" "drg_hub_route_distribution_statements" {
  // Required
  drg_route_distribution_id = oci_core_drg_route_distribution.drg_hub_route_distribution.id
  action = "ACCEPT"
  match_criteria {}
  priority = 1
}

##############################################################################################################
// route table
resource "oci_core_route_table" "trusted_routetable" {
  depends_on     = [oci_core_vnic_attachment.vnic_attach_trusted_fgt_a]
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "fgt-trusted-routetable"
  //Route to fortigate
  /* route_rules {
    description       = "Default Route to FGT int"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = data.oci_core_private_ips.nlb_trusted_private_ip.private_ips[0].id
  } */
  
  route_rules {
    description       = "Default Route to FGT int"
    destination       = var.vcn_cidr_spoke1
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_drg.drg.id
  }
  route_rules {
    description       = "Default Route to FGT int"
    destination       = var.vcn_cidr_spoke2
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_drg.drg.id
  }
}

/* // route table
resource "oci_core_route_table" "inlb_routetable" {
  depends_on     = [oci_core_vnic_attachment.vnic_attach_trusted_fgt_a]
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "fgt-inlb-routetable"


  //Route to fortigate
  route_rules {
    description       = "Default Route to FGT int"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = data.oci_core_private_ips.nlb_trusted_private_ip.private_ips[0].id
  }
} */

resource "oci_core_route_table" "hub_vcn_attach_routetable" {
  depends_on     = [oci_core_vnic_attachment.vnic_attach_trusted_fgt_a]
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "fgt-drg-routetable"


  //Route to internal NLB
  route_rules {
    description       = "Default Route to internal NLB int"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = data.oci_core_private_ips.nlb_trusted_private_ip.private_ips[0].id
  }
}

resource "oci_core_route_table" "spoke1_routetable" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn_spoke1.id
  display_name   = "spoke1-routetable"


  //Route to DRG
  route_rules {
    description       = "Default Route to FGT int"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_drg.drg.id
  }
}

resource "oci_core_route_table" "spoke2_routetable" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn_spoke2.id
  display_name   = "spoke2-routetable"


  //Route to DRG
  route_rules {
    description       = "Default Route to FGT int"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_drg.drg.id
  }
}

##############################################################################################################
## FortiGate A
##############################################################################################################
// trust nic attachment
resource "oci_core_vnic_attachment" "vnic_attach_trusted_fgt_a" {
  instance_id  = oci_core_instance.vm_fgt_a.id
  display_name = "${var.PREFIX}-fgta-vnic-trusted"

  create_vnic_details {
    subnet_id              = oci_core_subnet.trusted_subnet.id
    display_name           = "${var.PREFIX}-fgta-vnic-trusted"
    assign_public_ip       = false
    skip_source_dest_check = true
    private_ip             = var.fgt_ipaddress_a["3"]
  }
}

// create oci instance for active
resource "oci_core_instance" "vm_fgt_a" {
  depends_on = [oci_core_internet_gateway.igw]

  availability_domain = lookup(data.oci_identity_availability_domains.ads.availability_domains[var.availability_domain - 1], "name")
  compartment_id      = var.compartment_ocid
  display_name        = "${var.PREFIX}-fgta"
  shape               = var.instance_shape
  shape_config {
    memory_in_gbs = "96"
    ocpus         = "8"
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.untrusted_subnet.id
    display_name     = "${var.PREFIX}-fgta-vnic-untrusted"
    assign_public_ip = true
    hostname_label   = "${var.PREFIX}-fgta-vnic-untrusted"
    private_ip       = var.fgt_ipaddress_a["2"]
  }

  launch_options {
    //    network_type = "PARAVIRTUALIZED"
    network_type = "VFIO"
  }

  source_details {
    source_type = "image"
    source_id   = local.mp_listing_resource_id // marketplace listing
    boot_volume_size_in_gbs = "50"
  }

  // Required for bootstrap
  // Commnet out the following if you use the feature.
  metadata = {
    user_data           = base64encode(data.template_file.custom_data_fgt_a.rendered)
  }

  timeouts {
    create = "60m"
  }
}

resource "oci_core_volume" "volume_fgt_a" {
  availability_domain = lookup(data.oci_identity_availability_domains.ads.availability_domains[var.availability_domain - 1], "name")
  compartment_id      = var.compartment_ocid
  display_name        = "${var.PREFIX}-fgta-volume"
  size_in_gbs         = var.volume_size
}

// Use paravirtualized attachment for now.
resource "oci_core_volume_attachment" "volume_attach_fgt_a" {
  attachment_type = "paravirtualized"
  //attachment_type = "iscsi"   //  user needs to manually add the iscsi disk on fos after
  instance_id = oci_core_instance.vm_fgt_a.id
  volume_id   = oci_core_volume.volume_fgt_a.id
}

// Use for bootstrapping cloud-init
data "template_file" "custom_data_fgt_a" {
  template = file("${path.module}/customdata.tpl")

  vars = {
    fgt_vm_name          = "${var.PREFIX}-fgta"
    fgt_license_file     = "${var.fgt_byol_license_a == "" ? var.fgt_byol_license_a : (fileexists(var.fgt_byol_license_a) ? file(var.fgt_byol_license_a) : var.fgt_byol_license_a)}"
    fgt_license_flexvm   = var.fgt_byol_flexvm_license_a
    port1_ip             = var.fgt_ipaddress_a["2"]
    port1_mask           = var.subnetmask["2"]
    port2_ip             = var.fgt_ipaddress_a["3"]
    port2_mask           = var.subnetmask["3"]
    untrusted_gateway_ip = oci_core_subnet.untrusted_subnet.virtual_router_ip
    trusted_gateway_ip   = oci_core_subnet.trusted_subnet.virtual_router_ip
    vcn_cidr             = var.vcn
    spoke1_cidr          = var.vcn_cidr_spoke1
    spoke2_cidr          = var.vcn_cidr_spoke2
  }
}

##############################################################################################################
## FortiGate B
##############################################################################################################
resource "oci_core_instance" "vm_fgt_b" {
  depends_on = [oci_core_internet_gateway.igw]

  availability_domain = lookup(data.oci_identity_availability_domains.ads.availability_domains[var.availability_domain - 1], "name")
  compartment_id      = var.compartment_ocid
  display_name        = "${var.PREFIX}-fgtb"
  shape               = var.instance_shape
  shape_config {
    memory_in_gbs = "96"
    ocpus         = "8"
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.untrusted_subnet.id
    display_name     = "${var.PREFIX}-fgtb-vnic-untrusted"
    assign_public_ip = true
    hostname_label   = "${var.PREFIX}-fgtb-vnic-untrusted"
    private_ip       = var.fgt_ipaddress_b["2"]
  }

  launch_options {
    network_type = "VFIO"
  }

  source_details {
    source_type = "image"
    source_id   = local.mp_listing_resource_id // marketplace listing
      boot_volume_size_in_gbs = "50"
  }

  // Required for bootstrap
  // Commnet out the following if you use the feature.
  metadata = {
    user_data           = "${base64encode(data.template_file.custom_data_fgt_b.rendered)}"
  }

  timeouts {
    create = "60m"
  }
}

// trusted nic attachment
resource "oci_core_vnic_attachment" "vnic_attach_trusted_fgt_b" {
  instance_id  = oci_core_instance.vm_fgt_b.id
  display_name = "${var.PREFIX}-fgtb-vnic-trusted"

  create_vnic_details {
    subnet_id              = oci_core_subnet.trusted_subnet.id
    display_name           = "${var.PREFIX}-fgtb-vnic-trusted"
    assign_public_ip       = false
    skip_source_dest_check = true
    private_ip             = var.fgt_ipaddress_b["3"]
  }
}

resource "oci_core_volume" "volume_fgt_b" {
  availability_domain = lookup(data.oci_identity_availability_domains.ads.availability_domains[var.availability_domain - 1], "name")
  compartment_id      = var.compartment_ocid
  display_name        = "${var.PREFIX}-fgtb-volume"
  size_in_gbs         = var.volume_size
}

resource "oci_core_volume_attachment" "volume_attach_fgt_b" {
  attachment_type = "paravirtualized"
  //attachment_type = "iscsi"   //  user needs to manually add the iscsi disk on fos after
  instance_id = oci_core_instance.vm_fgt_b.id
  volume_id   = oci_core_volume.volume_fgt_b.id
}

// Use for bootstrapping cloud-init
data "template_file" "custom_data_fgt_b" {
  template = file("${path.module}/customdata.tpl")

  vars = {
    fgt_vm_name          = "${var.PREFIX}-fgtb"
    fgt_license_file     = "${var.fgt_byol_license_b == "" ? var.fgt_byol_license_b : (fileexists(var.fgt_byol_license_b) ? file(var.fgt_byol_license_b) : var.fgt_byol_license_b)}"
    fgt_license_flexvm   = var.fgt_byol_flexvm_license_b
    port1_ip             = var.fgt_ipaddress_b["2"]
    port1_mask           = var.subnetmask["2"]
    port2_ip             = var.fgt_ipaddress_b["3"]
    port2_mask           = var.subnetmask["3"]
    untrusted_gateway_ip = oci_core_subnet.untrusted_subnet.virtual_router_ip
    trusted_gateway_ip   = oci_core_subnet.trusted_subnet.virtual_router_ip
    vcn_cidr             = var.vcn
    spoke1_cidr          = var.vcn_cidr_spoke1
    spoke2_cidr          = var.vcn_cidr_spoke2
  }
}

##############################################################################################################
## FortiGate C
##############################################################################################################

// trust nic attachment
resource "oci_core_vnic_attachment" "vnic_attach_trusted_fgt_c" {
  instance_id  = oci_core_instance.vm_fgt_c.id
  display_name = "${var.PREFIX}-fgtc-vnic-trusted"

  create_vnic_details {
    subnet_id              = oci_core_subnet.trusted_subnet.id
    display_name           = "${var.PREFIX}-fgtc-vnic-trusted"
    assign_public_ip       = false
    skip_source_dest_check = true
    private_ip             = var.fgt_ipaddress_c["3"]
  }
}

resource "oci_core_instance" "vm_fgt_c" {
  depends_on = [oci_core_internet_gateway.igw]

  availability_domain = lookup(data.oci_identity_availability_domains.ads.availability_domains[var.availability_domain - 1], "name")
  compartment_id      = var.compartment_ocid
  display_name        = "${var.PREFIX}-fgtc"
  shape               = var.instance_shape
  shape_config {
    memory_in_gbs = "96"
    ocpus         = "8"
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.untrusted_subnet.id
    display_name     = "${var.PREFIX}-fgtc-vnic-untrusted"
    assign_public_ip = true
    hostname_label   = "${var.PREFIX}-fgtc-vnic-untrusted"
    private_ip       = var.fgt_ipaddress_c["2"]
  }

  launch_options {
    //    network_type = "PARAVIRTUALIZED"
    network_type = "VFIO"
  }

  source_details {
    source_type = "image"
    source_id   = local.mp_listing_resource_id // marketplace listing
    boot_volume_size_in_gbs = "50"
  }

  // Required for bootstrap
  // Commnet out the following if you use the feature.
  metadata = {
    user_data           = base64encode(data.template_file.custom_data_fgt_c.rendered)
  }

  timeouts {
    create = "60m"
  }
}

resource "oci_core_volume" "volume_fgt_c" {
  availability_domain = lookup(data.oci_identity_availability_domains.ads.availability_domains[var.availability_domain - 1], "name")
  compartment_id      = var.compartment_ocid
  display_name        = "${var.PREFIX}-fgtc-volume"
  size_in_gbs         = var.volume_size
}

// Use paravirtualized attachment for now.
resource "oci_core_volume_attachment" "volume_attach_fgt_c" {
  attachment_type = "paravirtualized"
  //attachment_type = "iscsi"   //  user needs to manually add the iscsi disk on fos after
  instance_id = oci_core_instance.vm_fgt_c.id
  volume_id   = oci_core_volume.volume_fgt_c.id
}

// Use for bootstrapping cloud-init
data "template_file" "custom_data_fgt_c" {
  template = file("${path.module}/customdata.tpl")

  vars = {
    fgt_vm_name          = "${var.PREFIX}-fgtc"
    fgt_license_file     = "${var.fgt_byol_license_c == "" ? var.fgt_byol_license_c : (fileexists(var.fgt_byol_license_c) ? file(var.fgt_byol_license_c) : var.fgt_byol_license_c)}"
    fgt_license_flexvm   = var.fgt_byol_flexvm_license_c
    port1_ip             = var.fgt_ipaddress_c["2"]
    port1_mask           = var.subnetmask["2"]
    port2_ip             = var.fgt_ipaddress_c["3"]
    port2_mask           = var.subnetmask["3"]
    untrusted_gateway_ip = oci_core_subnet.untrusted_subnet.virtual_router_ip
    trusted_gateway_ip   = oci_core_subnet.trusted_subnet.virtual_router_ip
    vcn_cidr             = var.vcn
    spoke1_cidr          = var.vcn_cidr_spoke1
    spoke2_cidr          = var.vcn_cidr_spoke2
  }
}


##############################################################################################################
## FortiGate D
##############################################################################################################

// trust nic attachment
resource "oci_core_vnic_attachment" "vnic_attach_trusted_fgt_d" {
  instance_id  = oci_core_instance.vm_fgt_d.id
  display_name = "${var.PREFIX}-fgtd-vnic-trusted"

  create_vnic_details {
    subnet_id              = oci_core_subnet.trusted_subnet.id
    display_name           = "${var.PREFIX}-fgtd-vnic-trusted"
    assign_public_ip       = false
    skip_source_dest_check = true
    private_ip             = var.fgt_ipaddress_d["3"]
  }
}

resource "oci_core_instance" "vm_fgt_d" {
  depends_on = [oci_core_internet_gateway.igw]

  availability_domain = lookup(data.oci_identity_availability_domains.ads.availability_domains[var.availability_domain - 1], "name")
  compartment_id      = var.compartment_ocid
  display_name        = "${var.PREFIX}-fgtd"
  shape               = var.instance_shape
  shape_config {
    memory_in_gbs = "96"
    ocpus         = "8"
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.untrusted_subnet.id
    display_name     = "${var.PREFIX}-fgtd-vnic-untrusted"
    assign_public_ip = true
    hostname_label   = "${var.PREFIX}-fgtd-vnic-untrusted"
    private_ip       = var.fgt_ipaddress_d["2"]
  }

  launch_options {
    //    network_type = "PARAVIRTUALIZED"
    network_type = "VFIO"
  }

  source_details {
    source_type = "image"
    source_id   = local.mp_listing_resource_id // marketplace listing
    boot_volume_size_in_gbs = "50"
  }

  // Required for bootstrap
  // Commnet out the following if you use the feature.
  metadata = {
    user_data           = base64encode(data.template_file.custom_data_fgt_d.rendered)
  }

  timeouts {
    create = "60m"
  }
}

resource "oci_core_volume" "volume_fgt_d" {
  availability_domain = lookup(data.oci_identity_availability_domains.ads.availability_domains[var.availability_domain - 1], "name")
  compartment_id      = var.compartment_ocid
  display_name        = "${var.PREFIX}-fgtd-volume"
  size_in_gbs         = var.volume_size
}

// Use paravirtualized attachment for now.
resource "oci_core_volume_attachment" "volume_attach_fgt_d" {
  attachment_type = "paravirtualized"
  //attachment_type = "iscsi"   //  user needs to manually add the iscsi disk on fos after
  instance_id = oci_core_instance.vm_fgt_d.id
  volume_id   = oci_core_volume.volume_fgt_d.id
}

// Use for bootstrapping cloud-init
data "template_file" "custom_data_fgt_d" {
  template = file("${path.module}/customdata.tpl")

  vars = {
    fgt_vm_name          = "${var.PREFIX}-fgtd"
    fgt_license_file     = "${var.fgt_byol_license_d == "" ? var.fgt_byol_license_d : (fileexists(var.fgt_byol_license_d) ? file(var.fgt_byol_license_d) : var.fgt_byol_license_d)}"
    fgt_license_flexvm   = var.fgt_byol_flexvm_license_d
    port1_ip             = var.fgt_ipaddress_d["2"]
    port1_mask           = var.subnetmask["2"]
    port2_ip             = var.fgt_ipaddress_d["3"]
    port2_mask           = var.subnetmask["3"]
    untrusted_gateway_ip = oci_core_subnet.untrusted_subnet.virtual_router_ip
    trusted_gateway_ip   = oci_core_subnet.trusted_subnet.virtual_router_ip
    vcn_cidr             = var.vcn
    spoke1_cidr          = var.vcn_cidr_spoke1
    spoke2_cidr          = var.vcn_cidr_spoke2
  }
}

##############################################################################################################
## External Network Load Balancer
##############################################################################################################
/* resource "oci_network_load_balancer_network_load_balancer" "nlb_untrusted" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.PREFIX}-nlb-untrusted"
  subnet_id      = oci_core_subnet.nlb_subnet.id

  is_private                     = false
  is_preserve_source_destination = false
}

resource "oci_network_load_balancer_listener" "nlb_untrusted_listener" {
  default_backend_set_name = oci_network_load_balancer_backend_set.nlb_untrusted_backend_set.name
  name                     = "${var.PREFIX}-nlb-untrusted-listener"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.nlb_untrusted.id
  port                     = 0
  protocol                 = "ANY"
}

resource "oci_network_load_balancer_backend_set" "nlb_untrusted_backend_set" {
  health_checker {
    protocol = "TCP"
    port     = 8008
  }

  name                     = "${var.PREFIX}-untrusted-backend-set"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.nlb_untrusted.id
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true
}

resource "oci_network_load_balancer_backend" "nlb_untrusted_backend_fgta" {
  backend_set_name         = oci_network_load_balancer_backend_set.nlb_untrusted_backend_set.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.nlb_untrusted.id
  port                     = 0

  target_id = oci_core_instance.vm_fgt_a.id
}

resource "oci_network_load_balancer_backend" "nlb_untrusted_backend_fgtb" {
  backend_set_name         = oci_network_load_balancer_backend_set.nlb_untrusted_backend_set.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.nlb_untrusted.id
  port                     = 0

  target_id = oci_core_instance.vm_fgt_b.id
} */

##############################################################################################################
## Internal Network Load Balancer
##############################################################################################################
resource "oci_network_load_balancer_network_load_balancer" "nlb_trusted" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.PREFIX}-nlb-trusted"
  subnet_id      = oci_core_subnet.trusted_subnet.id

  is_private                     = true
  is_preserve_source_destination = true
}

resource "oci_network_load_balancer_listener" "nlb_trusted_listener" {
  default_backend_set_name = oci_network_load_balancer_backend_set.nlb_trusted_backend_set.name
  name                     = "${var.PREFIX}-nlb-trusted-listener"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.nlb_trusted.id
  port                     = 0
  protocol                 = "TCP_AND_UDP"
}

resource "oci_network_load_balancer_backend_set" "nlb_trusted_backend_set" {
  health_checker {
    protocol = "TCP"
    port     = 8008
  }

  name                     = "${var.PREFIX}-trusted-backend-set"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.nlb_trusted.id
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true
}

resource "oci_network_load_balancer_backend" "nlb_trusted_backend_fgta" {
  backend_set_name         = oci_network_load_balancer_backend_set.nlb_trusted_backend_set.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.nlb_trusted.id
  port                     = 0
  
  target_id = oci_core_instance.vm_fgt_a.id
  ip_address = var.fgt_ipaddress_a["3"]
}

resource "oci_network_load_balancer_backend" "nlb_trusted_backend_fgtb" {
  backend_set_name         = oci_network_load_balancer_backend_set.nlb_trusted_backend_set.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.nlb_trusted.id
  port                     = 0

  target_id = oci_core_instance.vm_fgt_b.id
  ip_address = var.fgt_ipaddress_b["3"]
}

resource "oci_network_load_balancer_backend" "nlb_trusted_backend_fgtc" {
  backend_set_name         = oci_network_load_balancer_backend_set.nlb_trusted_backend_set.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.nlb_trusted.id
  port                     = 0

  target_id = oci_core_instance.vm_fgt_c.id
  ip_address = var.fgt_ipaddress_c["3"]
}

resource "oci_network_load_balancer_backend" "nlb_trusted_backend_fgtd" {
  backend_set_name         = oci_network_load_balancer_backend_set.nlb_trusted_backend_set.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.nlb_trusted.id
  port                     = 0

  target_id = oci_core_instance.vm_fgt_d.id
  ip_address = var.fgt_ipaddress_d["3"]
}
