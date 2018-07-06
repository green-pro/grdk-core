#!/bin/bash
set -e

### MANAGER
if [ "${DK_SERVER_NODE_ROLE}" = "manager" ]; then
	echo " "
fi

### ALL

### GITLAB DEPLOY KEY
file_ssh_config=/etc/ssh/ssh_config
if [ -f "$file_ssh_config" ]; then
	if [ `echo $file_ssh_config | xargs grep -liE 'GRDKDEPLOYKEY' | wc -l` != "0" ]; then
		echo "O arquivo ${file_ssh_config} já estava configurado"
	else
		cat >> $file_ssh_config << EOF
#
# GRDKDEPLOYKEY
#
Host ${repo_host}
  Hostname ${repo_host}
  User git
  Port 2200
  PreferredAuthentications publickey
  IdentityFile /etc/ssh/ssh_host_rsa_key
EOF
		echo "O arquivo ${file_ssh_config} foi modificado"
	fi
fi
echo "Add GitLab Deploy Keys"
echo "--------------------------------------------------------------------------------"
cat /etc/ssh/ssh_host_rsa_key.pub
echo "--------------------------------------------------------------------------------"
