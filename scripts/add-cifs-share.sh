#!/bin/bash
set -euo pipefail
share=$1
mount=$2
user=$3
credfile=/root/.smbcredentials
fstab_line="$share $mount cifs vers=3.0,credentials=$credfile,sec=ntlmv2 0 0"
read -r -s -p "Windows password for $3: " password

cat << EOF > $credfile
username=$user
password=$password
EOF
chmod 600 $credfile

if grep -q "$share" /etc/fstab; then
    sed -i "s#$share.*#$fstab_line#" /etc/fstab
else
    echo "$fstab_line" >> /etc/fstab
fi
umount "$mount" || true
mount -a
