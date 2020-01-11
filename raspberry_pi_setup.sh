ansible-playbook -i hosts.yml -l hotspots --ask-become-pass setup.yml
echo "$0 completed in $SECONDS seconds"

