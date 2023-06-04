#!/bin/bash

: <<'COMMENT'
This script creates 500 users and generates SSH keys for them. It also limits them to only use SSH tunneling and nothing else. The aim is to let users access free internet using SSH tunnel.

Prerequisites:
- debootstrap (apt install debootstrap)

Note:
- use the script using root user (sudo su)


The script does the following steps:
- It creates a group called ssh_only for the users.
- It creates a directory called /home/jails and sets it up as a chroot jail for the users.
- It creates a file called ssh_users.txt to store the users, passwords and private keys.
- It loops from 1000 to 50000 with a step of 100 and generates a username, password and private key for each user.
- It creates the user and adds it to the ssh_only group.
- It sets the user's password using a formula based on the username.
- It copies the public key to the user's authorized_keys file and adds some options to restrict SSH access.
- It sets the ownership and permissions of the user's home directory and .ssh directory.
- It moves the user's home directory to the chroot jail and creates a symbolic link.
- It appends the user's information to the ssh_users.txt file.
- It removes the temporary files.
- It unmounts the chroot jail directories.


Clients:
- Android:
    - https://play.google.com/store/apps/details?id=com.evozi.injector
    - Termux + toolbox + v2rayNG
        - toolbox: https://github.com/mmgghh/toolbox (use pyssh ssh-tunnel)
        - v2rayNG: https://play.google.com/store/apps/details?id=com.v2ray.ang (config for socks://user@localhost:port)
- Ubuntu
    - toolbox + v2rayA
    - toolbox: https://github.com/mmgghh/toolbox (use pyssh ssh-tunnel)
    - v2rayA: https://v2raya.org/ (config for socks5://localhost:port)

COMMENT


# Create the ssh_only group
groupadd ssh_only

# Create the /home/jails directory
mkdir /home/jails

# Configure the chroot jail for the users
# This part may vary depending on the system and the requirements
# For simplicity, we assume that we only need to copy some basic files and directories
# such as /bin, /lib, /lib64, /etc, /dev, /usr and /opt
# We also assume that we have the debootstrap command available to install a minimal system
debootstrap --arch=amd64 --variant=minbase focal /home/jails http://archive.ubuntu.com/ubuntu/
mkdir /home/jails/dev; mount -o bind /dev /home/jails/dev
mkdir /home/jails/dev/pts; mount -o bind /dev/pts /home/jails/dev/pts
mkdir /home/jails/proc; mount -t proc proc /home/jails/proc
mkdir /home/jails/sys; mount -t sysfs sysfs /home/jails/sys

# Create a file to store the users, passwords and private keys
touch ssh_users.txt

# Loop from 1000 to 50000 with step 100
for i in $(seq 1000 100 50000); do
  # Generate the username, password and private key
  username="u$i"
  password="bert4-$((i * 3 + 51 - i % 1000 * 2))-resu"
  ssh-keygen -q -t rsa -b 2048 -N "" -C "$username" -f "/tmp/$username"
  private_key=$(cat "/tmp/$username")

  # Create the user and add it to the ssh_only group
  useradd -m -d "/home/$username" -s "/bin/false" -G ssh_only "$username"

  # Set the user's password
  echo "$username:$password" | chpasswd

  # Copy the public key to the user's authorized_keys file and set some options to restrict SSH access
  mkdir "/home/$username/.ssh"
  cat "/tmp/$username.pub" | sed 's/^/no-pty,no-agent-forwarding,no-X11-forwarding,no-user-rc,no-shell /' > "/home/$username/.ssh/authorized_keys"

  # Set the ownership and permissions of the user's home directory and .ssh directory
  chown -R "$username:$username" "/home/$username"
  chmod 700 "/home/$username/.ssh"

  # Move the user's home directory to the chroot jail and create a symbolic link
  mv "/home/$username" "/home/jails/home/"
  ln -s "/home/jails/home/$username" "/home/$username"

  # Append the user's information to the ssh_users.txt file
  echo "$username:$password" >> ssh_users.txt
  echo "$private_key" >> ssh_users.txt
  echo "-----------------" >> ssh_users.txt

  # Remove the temporary files
  rm "/tmp/$username" "/tmp/$username.pub"
done

# Unmount the chroot jail directories
umount /home/jails/dev/pts
umount /home/jails/dev
umount /home/jails/proc
umount /home/jails/sys

# Done!
echo "Script finished!"
