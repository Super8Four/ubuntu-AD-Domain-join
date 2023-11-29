#!/bin/bash

# Script to dynamically join Ubuntu to an Active Directory domain

# Function to install necessary packages
install_packages() {
    echo "Installing necessary packages..."
    sudo apt update
    sudo apt install -y realmd krb5-user sssd sssd-tools libnss-sss libpam-sss adcli samba-common-bin oddjob oddjob-mkhomedir packagekit
}

# Discover the domain
discover_domain() {
    echo "Discovering the $domain_name domain..."
    sudo realm discover $domain_name
}

# Join the domain
join_domain() {
    if [ -z "$computer_ou" ]; then
        echo "Joining the $domain_name domain..."
        echo $admin_password | sudo realm join --user=$admin_username $domain_name
    else
        echo "Joining the $domain_name domain in OU=$computer_ou..."
        echo $admin_password | sudo realm join --user=$admin_username --computer-ou="$computer_ou" $domain_name
    fi
}

# Configure sudo rights for domain admins
configure_sudo_rights() {
    echo "Configuring sudo rights for domain admins..."
    sudo bash -c "echo '%$domain_name\\domain^admins ALL=(ALL:ALL) ALL' >> /etc/sudoers"
}

# Configure access control
configure_access_control() {
    echo "Configuring access control..."
    sudo sed -i "/\[domain\/$domain_name\]/a access_provider = simple\nsimple_allow_groups = domain^admins" /etc/sssd/sssd.conf
}

# Configure home directory creation
configure_home_directory() {
    echo "Configuring home directory creation..."
    sudo bash -c "echo 'session required pam_mkhomedir.so skel=/etc/skel/ umask=0022' >> /etc/pam.d/common-session"
}

# Restart SSSD service
restart_services() {
    echo "Restarting SSSD service..."
    sudo systemctl restart sssd
}

# Main script starts here
echo "Active Directory Integration Script"

# Prompt for the domain name, admin username, password, and OU
read -p "Enter the Active Directory domain name: " domain_name
read -p "Enter your domain admin username: " admin_username
read -s -p "Enter your domain admin password: " admin_password
echo
read -p "Enter the OU for the computer account in AD (optional): " computer_ou

# Run functions
install_packages
discover_domain
join_domain
configure_sudo_rights
configure_access_control
configure_home_directory
restart_services

echo "The server has been successfully joined to the $domain_name domain."
