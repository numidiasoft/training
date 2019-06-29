
###########################
# VIRTUAL MACHINE SCALE SET
###########################

data "azurerm_image" "green" {
  name                = "blue-green-1561795972"
  resource_group_name = "${azurerm_resource_group.rg.name}"
}

resource "azurerm_virtual_machine_scale_set" "green" {
  count               = var.enable_green ? 1 : 0
  name                = "green"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  # Manual upgrade
  upgrade_policy_mode = "Manual"

  # required when using rolling upgrade policy
  // health_probe_id = "${azurerm_lb_probe.test.id}"
  zones = [1, 2, 3]

  sku {
    name     = "Standard_B1s"
    tier     = "Standard"
    capacity = "${local.instance_count}"
  }

  storage_profile_image_reference {
    id = "${data.azurerm_image.green.id}"
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_profile_data_disk {
    lun           = 0
    caching       = "ReadWrite"
    create_option = "Empty"
    disk_size_gb  = 10
  }

  os_profile {
    computer_name_prefix = "green"
    admin_username       = "myadmin"

    custom_data = <<EOF
#! /bin/bash
node /home/packer/app/server.js
EOF
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path = "/home/myadmin/.ssh/authorized_keys"
      key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDRI29ik1fJRXm1AVJprmZ2jsCTU+BHb/BAjBTFTgkNbGirItWjxy8VdwuskAa7WKsR7mYM6qmEnudwWgutAr43dndffcoR51/uNguu2gS9Wzh6kgJk2vHDwzaLyTI1U9+frvo509s9blVEhOoBzaur6fYhybfEswV7rkzmYEigfEhI3ZPxSr4AML1TluFOYfhC1FAoFZhOAv9f0FETgcbC8dIfKppdDfAHbjBDW3M9pPZCiPiNJYvE64gLpaDpFrqUkN94jvYfEXxqLDBA7j/amIxsMXIYynw3SjYA/gkQrM8nz9HH4BbDjPMVeokpfB2Wqt7R3Q2H81BM68k+Df1r2qrxJ0j5FSqE3iGT2Dq6vTqNzzMyyFcP5cETMFlV7IOhHDUwfvHG71belvjrDURJMeauiXRxPRHiUc3wPhwvPy9DxJOmj1Y0105NI68MGDuef8NG+bUrpIURoIrcjgHFEgPTVJ7nYhNUN0T/WAZ9GAkq9HpEJYLPQfEc0cPjTF49uvhExCDoYrB6L67Xgu5Nxl8LZ5DQYSaN7ocKKp2+YpoPw/BI6RhsWVVX2VGSit6Oj8d3hwCYSme3CKzfzvtXjZb6lMFw0ZyvV1xATlO9KSxudt/TglDaQ7Y4j6EiOgBig96PAZ+6mFJnFjvDOX0d06rtC8Br8oghnWHejhnAuQ== tarik@bearer.sh"
    }
  }

  network_profile {
    name = "green"
    primary = true

    ip_configuration {
      name = "BlueIPConfiguration"
      primary = true
      subnet_id = "${azurerm_subnet.subnet1.id}"
      load_balancer_backend_address_pool_ids = ["${azurerm_lb_backend_address_pool.green.0.id}"]

      public_ip_address_configuration {
        name = "green-green"
        domain_name_label = "green-green"
        idle_timeout = 30
      }
    }
  }

  tags = {
    environment = "Blue Green"
  }
}

resource "azurerm_monitor_autoscale_setting" "green" {
  count = var.enable_green ? 1 : 0
  name = "autoscale-cpu-green"
  target_resource_id = "${azurerm_virtual_machine_scale_set.green.0.id}"
  location = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  profile {
    name = "autoscale-cpu"

    capacity {
      default = "${local.instance_count}"
      minimum = 1
      maximum = 3
    }

    rule {
      metric_trigger {
        metric_name = "Percentage CPU"
        metric_resource_id = "${azurerm_virtual_machine_scale_set.green.0.id}"
        time_grain = "PT1M"
        statistic = "Average"
        time_window = "PT5M"
        time_aggregation = "Average"
        operator = "GreaterThan"
        threshold = 75
      }

      scale_action {
        direction = "Increase"
        type = "ChangeCount"
        value = "1"
        cooldown = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name = "Percentage CPU"
        metric_resource_id = "${azurerm_virtual_machine_scale_set.green.0.id}"
        time_grain = "PT1M"
        statistic = "Average"
        time_window = "PT5M"
        time_aggregation = "Average"
        operator = "LessThan"
        threshold = 15
      }

      scale_action {
        direction = "Decrease"
        type = "ChangeCount"
        value = "1"
        cooldown = "PT1M"
      }
    }
  }
}

##########################
# LOAD BALANCER
##########################

resource "azurerm_public_ip" "green" {
  count = var.enable_green ? 1 : 0
  name = "green"
  location = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  allocation_method = "Static"
  sku = "Standard"

  tags = {
    environment = "Blue Green"
  }
}

resource "azurerm_lb" "green" {
  count = var.enable_green ? 1 : 0
  name = "green"
  location = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  sku = "Standard"

  frontend_ip_configuration {
    name = "PublicIPAddress"
    public_ip_address_id = "${azurerm_public_ip.green.0.id}"
  }
}

resource "azurerm_lb_rule" "green" {
  count = var.enable_green ? 1 : 0
  resource_group_name = "${azurerm_resource_group.rg.name}"
  loadbalancer_id = "${azurerm_lb.green.0.id}"
  name = "LBRule"
  protocol = "Tcp"
  frontend_port = 80
  backend_port = 9000
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.green.0.id}"
  probe_id = "${azurerm_lb_probe.green.0.id}"
}

resource "azurerm_lb_probe" "green" {
  count = var.enable_green ? 1 : 0
  resource_group_name = "${azurerm_resource_group.rg.name}"
  loadbalancer_id = "${azurerm_lb.green.0.id}"
  name = "http-probe"
  protocol = "Http"
  request_path = "/"
  port = 9000
}

resource "azurerm_lb_backend_address_pool" "green" {
  count = var.enable_green ? 1 : 0
  resource_group_name = "${azurerm_resource_group.rg.name}"
  loadbalancer_id = "${azurerm_lb.green.0.id}"
  name = "BackEndAddressPool"
}
