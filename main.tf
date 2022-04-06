terraform {
    required_version = " >= 0.13"

    required_providers {
       azurerm = {
        source = "hashicorp/azurerm"
        version = ">= 2.26" 
       }
    }
}

provider "azurerm" {
    
    features {
     }
    }
    resource "azurerm_resource_group" "InfraCloudAula" {
    name     = "InfraCloudAula"
    location = "australiaeast"

}

resource "azurerm_virtual_network" "vnet-InfraCloudAula" {
  name                = "vnet-aula"
  location            = azurerm_resource_group.InfraCloudAula.location
  resource_group_name = azurerm_resource_group.InfraCloudAula.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "Production"
  }
}
resource "azurerm_subnet" "subAulaInfra" {
  name                 = "sub-aula"
  resource_group_name  = azurerm_resource_group.InfraCloudAula.name
  virtual_network_name = azurerm_virtual_network.vnet-InfraCloudAula.name
  address_prefixes     = ["10.0.1.0/24"]

}
resource "azurerm_public_ip" "ip-aulaInfra" {
  name                = "ipAulaInfra"
  resource_group_name = azurerm_resource_group.InfraCloudAula.name
  location            = azurerm_resource_group.InfraCloudAula.location
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
}
resource "azurerm_network_security_group" "nsgAulaInfra" {
  name                = "nsg-aula"
  location            = azurerm_resource_group.InfraCloudAula.location
  resource_group_name = azurerm_resource_group.InfraCloudAula.name

  security_rule {
    name                       = "test123"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "test123"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

   

  tags = {
    environment = "Production"
  }
}
resource "azurerm_network_interface" "nic-aulainfra" {
  name                = "nic-AulaInfra"
  location            = azurerm_resource_group.InfraCloudAula.location
  resource_group_name = azurerm_resource_group.InfraCloudAula.name

  ip_configuration {
    name                          = "ip-aulaInfra"
    subnet_id                     = azurerm_subnet.subAulaInfra.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.ip-aulaInfra.id
   
  }
}

resource "azurerm_network_interface_security_group_association" "nic-nsg-AulaInfra" {
  network_interface_id      = azurerm_network_interface.nic-aulainfra.id
  network_security_group_id = azurerm_network_security_group.nsgAulaInfra.id
}

resource "azurerm_virtual_machine" "vm-AulaInfra" {
  name                  = "vm-Aula"
  location              = azurerm_resource_group.InfraCloudAula.location
  resource_group_name   = azurerm_resource_group.InfraCloudAula.name
  network_interface_ids = [azurerm_network_interface.nic-aulainfra.id]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}

