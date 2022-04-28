terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "<=3.2.0" #azurerm version
    }
  } #terraform version
}
provider "azurerm" {
  alias           = "prodsubscription"
  subscription_id = "b2d3029d-a6ac-4690-b005-312bba3a7639"
  client_id       = "129b5913-a8e3-4fd5-8f41-f3e2a2547f63"
  client_secret   = "ej3MhK1xUFK9C-YCo370w1HeTCuibFQECV"
  tenant_id       = "cea297cb-9bde-428d-9a6e-48fa9c582ed6"
  features {}
}
#dynamic block
resource "azurerm_resource_group" "example" {
  provider = azurerm.prodsubscription
  name     = "rg-vm"
  location = "westus"
}
resource "azurerm_virtual_network" "example" {
  provider            = azurerm.prodsubscription
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  name                = "vm-network"
  address_space       = ["10.0.0.0/16"]
}
resource "azurerm_subnet" "example" {
  provider             = azurerm.prodsubscription
  name                 = "vm-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}
resource "azurerm_public_ip" "example" {
  provider            = azurerm.prodsubscription
  name                = "vm-publicip"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  allocation_method   = "Static"
}
resource "azurerm_network_interface" "example" {
  provider            = azurerm.prodsubscription
  name                = "vm-nic"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  ip_configuration {
    name                          = "nic-1"
    subnet_id                     = azurerm_subnet.example.id
    public_ip_address_id          = azurerm_public_ip.example.id
    private_ip_address_allocation = "Dynamic"
  }
}
resource "azurerm_linux_virtual_machine" "example" {
  provider = azurerm.prodsubscription
  name                            = "vm-linux"
  resource_group_name             = azurerm_resource_group.example.name
  location                        = azurerm_resource_group.example.location
  size                            = "Standard_DS1_v2"
  admin_username                  = "adminuser"
  admin_password                  = "ubuntu@123!"
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.example.id]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  provisioner "remote-exec" {
    on_failure = continue
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install nginx -y",
      "sudo systemctl start nginx"
    ]
  }
  connection {
    type     = "ssh"
    user     = azurerm_linux_virtual_machine.example.admin_username
    password = azurerm_linux_virtual_machine.example.admin_password
    host     = azurerm_public_ip.example.ip_address
  }
}
#multiple VMs
#dynamic block for subnet
#create network security rules using loop