provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "rg_KCR_NTL_PCH"
  location = "East US"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-kcrntlpch"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet-kcrntlpch"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "publicip" {
  name                = "publicip-kcrntlpch"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

resource "azurerm_lb" "lb" {
  name                = "lb-kcrntlpch"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  frontend_ip_configuration {
    name                 = "publicIPAddress"
    public_ip_address_id = azurerm_public_ip.publicip.id
  }
}

resource "azurerm_lb_backend_address_pool" "backendpool" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "backendpool-kcrntlpch"
}

resource "azurerm_virtual_machine_scale_set" "vmss" {
  name                = "vmss-kcrntlpch"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  upgrade_policy_mode = "Manual"

  sku {
    tier     = "Standard"
    capacity = 1
    name     = "Standard_DS1_v2"
  }

  os_profile {
    computer_name_prefix = "vmss"
    admin_username       = "adminuser"
    admin_password       = "exempleOfPassWord10942!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  storage_profile_os_disk {
    caching      = "ReadWrite"
    create_option = "FromImage"
    managed_disk_type = "Standard_LRS"
    os_type = "Linux"
  }

  storage_profile_image_reference {
    publisher = "Canonical" 
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"  
    version   = "latest"
  }

  network_profile {
    name    = "networkprofile-kcrntlpch"
    primary = true

    ip_configuration {
      name                                   = "ipconfig-kcrntlpch"
      primary                                = true
      subnet_id                              = azurerm_subnet.subnet.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.backendpool.id]
    }
  }

  tags = {
    environment = "Production"
  }
}
