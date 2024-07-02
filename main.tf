resource "azurerm_resource_group" "rg" {
    for_each = var.devops
  
  name     = each.value.rgname
  location = each.value.location
}

resource "azurerm_virtual_network" "vnet" {
    depends_on = [ azurerm_resource_group.rg ]
    for_each = var.devops
  name                = each.value.vnetname
  address_space       = ["10.0.0.0/16"]
  location            = each.value.location
  resource_group_name = each.value.rgname
}

resource "azurerm_subnet" "internal" {
    depends_on = [ azurerm_virtual_network.vnet ]
   for_each = var.devops
     name                 = each.value.subname
  resource_group_name  = each.value.rgname
  virtual_network_name = each.value.vnetname
  address_prefixes     = each.value.ipaddress
}

resource "azurerm_public_ip" "pip" {
    depends_on = [ azurerm_subnet.internal ]
    for_each = var.devops
  name                = each.value.pipname
  resource_group_name = each.value.rgname
  location            = each.value.location
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
}

resource "azurerm_network_interface" "nic" {
    depends_on = [ azurerm_public_ip.pip]
    for_each = var.devops
  name                = each.value.nicname
  location            = each.value.location
  resource_group_name = each.value.rgname

  ip_configuration {
    
    name                          = each.value.ipconfig
    subnet_id                     = azurerm_subnet.internal[each.key].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id =azurerm_public_ip.pip[each.key].id
  }
}


resource "azurerm_linux_virtual_machine" "vm" {
    depends_on = [ azurerm_network_interface.nic ]
    for_each = var.devops
    
  name                =each.value.vmname
  resource_group_name = each.value.rgname
  location            = each.value.location
  size                = "Standard_F2"
  admin_username      = "vishnu"
  admin_password = "vivek@123"
  disable_password_authentication = false
 
 
  network_interface_ids =[azurerm_network_interface.nic[each.key].id]
  
 
 
 
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
 
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}


