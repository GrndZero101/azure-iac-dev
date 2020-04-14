provider "azurerm" {
#    subscription_id     = ""
#    client_id           = ""
#    client_secret       = ""
#    tenant_id           = ""

    features {}
}

resource "azurerm_resource_group" "myTerraformResourceGroup" {
    name                = "myTerraformResourceGroup"
    location            = "southeastasia"

    tags                = {
        env = "lab"
    }
}

resource "azurerm_virtual_network" "myTerraformNetwork" {
    name                = "myTerraformNetwork"
    address_space       = ["10.3.0.0/16"]
    location            = "southeastasia"
    resource_group_name = azurerm_resource_group.myTerraformResourceGroup.name

    tags                = {
        env = "lab"
    }
}

resource "azurerm_subnet" "myTerraformSubnet" {
    name                = "myTerraformSubnet"
    resource_group_name = azurerm_resource_group.myTerraformResourceGroup.name
    virtual_network_name = azurerm_virtual_network.myTerraformNetwork.name
    address_prefix      = "10.3.0.0/24"
}

# Create public IP address - Linux Host

resource "azurerm_public_ip" "myTerraformPublicIP_linux" {
    name                = "PublicIP_linux"
    location            = "southeastasia"
    resource_group_name = azurerm_resource_group.myTerraformResourceGroup.name
    allocation_method   = "Dynamic"

    tags                = {
        env = "lab"
    }
}

# Create public IP address - Windows Host

resource "azurerm_public_ip" "myTerraformPublicIP_windows" {
    name                = "PublicIP_windows"
    location            = "southeastasia"
    resource_group_name = azurerm_resource_group.myTerraformResourceGroup.name
    allocation_method   = "Dynamic"

    tags                = {
        env = "lab"
    }
}

resource "azurerm_network_security_group" "myTerraformNSG" {
    name                = "myTerraformNSG"
    location            = "southeastasia"
    resource_group_name = azurerm_resource_group.myTerraformResourceGroup.name
    
    security_rule {
        name                                = "ICMP-Protocol"
        priority                            = 1001
        direction                           = "Inbound"
        access                              = "Allow"
        protocol                            = "ICMP"
        source_port_range                   = "*"
        destination_port_range              = "*"
        source_address_prefix               = "*"
        destination_address_prefix          = "*"
    }

    security_rule {
        name                                = "SSH-Protocol"
        priority                            = 1002
        direction                           = "Inbound"
        access                              = "Allow"
        protocol                            = "Tcp"
        source_port_range                   = "*"
        destination_port_range              = "22"
        source_address_prefix               = "*"
        destination_address_prefix          = "*"
    }

        security_rule {
        name                                = "RDP-Protocol"
        priority                            = 1003
        direction                           = "Inbound"
        access                              = "Allow"
        protocol                            = "Tcp"
        source_port_range                   = "*"
        destination_port_range              = "3389"
        source_address_prefix               = "*"
        destination_address_prefix          = "*"
    }



    tags = {
        env = "lab"
    }
}

resource "azurerm_network_interface" "myTerraformNIC_linux" {
    name                = "NIC_linux"
    location            = "southeastasia"
    resource_group_name = azurerm_resource_group.myTerraformResourceGroup.name

    ip_configuration {
        name                                = "myNICConfiguration"
        subnet_id                           = azurerm_subnet.myTerraformSubnet.id
        private_ip_address_allocation       = "Dynamic"
        public_ip_address_id                = azurerm_public_ip.myTerraformPublicIP_linux.id
    }

    tags = {
        env = "lab"
    }
}

resource "azurerm_network_interface" "myTerraformNIC_windows" {
    name                = "NIC_windows"
    location            = "southeastasia"
    resource_group_name = azurerm_resource_group.myTerraformResourceGroup.name

    ip_configuration {
        name                                = "myNICConfiguration"
        subnet_id                           = azurerm_subnet.myTerraformSubnet.id
        private_ip_address_allocation       = "Dynamic"
        public_ip_address_id                = azurerm_public_ip.myTerraformPublicIP_windows.id
    }

    tags = {
        env = "lab"
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "network_attach_linux" {
    network_interface_id                   = azurerm_network_interface.myTerraformNIC_linux.id
    network_security_group_id              = azurerm_network_security_group.myTerraformNSG.id
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "network_attach_windows" {
    network_interface_id                   = azurerm_network_interface.myTerraformNIC_windows.id
    network_security_group_id              = azurerm_network_security_group.myTerraformNSG.id
}


resource "random_id" "randomID" {
    keepers = {
        resource_group = azurerm_resource_group.myTerraformResourceGroup.name
    }

    byte_length = 8
}

resource "azurerm_storage_account" "myStorageAccount" {
    name                                = "diag${random_id.randomID.hex}"
    resource_group_name                 = azurerm_resource_group.myTerraformResourceGroup.name
    location                            = "southeastasia"
    account_replication_type            = "LRS"
    account_tier                        = "Standard"
}

resource "azurerm_linux_virtual_machine" "VM-linux" {
    name                                = "VM-linux"
    location                            = "southeastasia"
    resource_group_name                 = azurerm_resource_group.myTerraformResourceGroup.name
    network_interface_ids               = [azurerm_network_interface.myTerraformNIC_linux.id]
    size                                = "Standard_DS1_v2"

    os_disk {
        name                            = "myOSDisk"
        caching                         = "ReadWrite"
        storage_account_type            = "Premium_LRS"
    }

    source_image_reference {
        publisher                       = "Canonical"
        offer                           = "UbuntuServer"
        sku                             = "16.04.0-LTS"
        version                         = "latest"
    }

    computer_name                       = "myvmlinux"
    admin_username                      = "ubuntu"
    disable_password_authentication     = true

    admin_ssh_key {
        username                        = "ubuntu"
        public_key                      = file("c:/temp/authorized_keys")
    }

    boot_diagnostics {
        storage_account_uri             = azurerm_storage_account.myStorageAccount.primary_blob_endpoint
    }


    tags = {
        env = "lab"
    }
}

resource "azurerm_windows_virtual_machine" "VM-windows" {
    name                                = "VM-windows"
    location                            = "southeastasia"
    resource_group_name                 = azurerm_resource_group.myTerraformResourceGroup.name
    network_interface_ids               = [azurerm_network_interface.myTerraformNIC_windows.id]
    size                                = "Standard_DS1_v2"

    os_disk {
        name                            = "myOSDisk_windows"
        caching                         = "ReadWrite"
        storage_account_type            = "Premium_LRS"
    }

    source_image_reference {
        publisher                       = "MicrosoftWindowsServer"
        offer                           = "WindowsServer"
        sku                             = "2019-Datacenter"
        version                         = "latest"
    }

    computer_name                       = "myvmwindows"
    admin_username                      = var.win_username
    admin_password                      = var.win_password

    #disable_password_authentication     = true

    #admin_ssh_key {
    #    username                        = "ubuntu"
    #    public_key                      = file("authorized_keys")
    #}

    boot_diagnostics {
        storage_account_uri             = azurerm_storage_account.myStorageAccount.primary_blob_endpoint
    }


    tags = {
        env = "lab"
    }
}