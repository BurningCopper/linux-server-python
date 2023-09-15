#!/bin/bash

# Set the username variable; reject if no input or if non-alphanumerics are present
read -rp "Enter the new username: " username

[[ -z "$username" ]] && echo "No input detected" && exit 1

[[ "$username" =~ [^a-zA-Z0-9:blank:] ]] && echo "Non-alphanumeric character or space detected" && exit 1

# Create homedir from the SKELETON directory
cp -r /Volumes/Users/SKELETON /Volumes/Users/"$username"

# Set permissions
chown -R "$username:researcher_heri" /Volumes/Users/"$username"
chmod 750 /Volumes/Users/"$username"

# Fix bash_profile perms (should be owned/writable by root but readable by all)
chown root:root /Volumes/Users/"$username"/.bash_profile
chmod 644 /Volumes/Users/"$username"/.bash_profile

# Print contents for visual verification of path and permissions
echo "Created homedirectory for $username at /Volumes/Users/$username:"
echo "================================="
ls -la /Volumes/Users/"$username"
echo "================================="

# Fin
exit 0
