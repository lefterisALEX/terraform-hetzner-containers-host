
#cloud-config
# This example assumes a default Ubuntu cloud image, which should contain
# the required software to be managed remotely by Ansible.

package_update: true
package_update: false
package_upgrade: true

#Do not accept SSH password authention
ssh_pwauth: false

timezone: ${timezone}
packages:
  - jq
  - nfs-common

write_files:
  - path: /etc/systemd/system/repo-sync.service
    content: |
      [Unit]
      Description=Repository Synchronization Service
      After=network.target

      [Service]
      Type=oneshot
      User=root
      ExecStart=/usr/local/bin/cloudstack-repo-sync.sh
      Restart=on-failure

      [Install]
      WantedBy=multi-user.target
    permissions: '0644'
    owner: root:root

  - path: /etc/systemd/system/repo-sync.timer
    content: |
      [Unit]
      Description=Repository Synchronization Timer Service
      After=network.target

      [Timer]
      OnActiveSec=3min
      OnUnitActiveSec=3min
      Persistent=true
      
      [Install]
      WantedBy=timers.target
    permissions: '0644'
    owner: root:root

  - path: /usr/local/bin/cloudstack-repo-sync.sh
    content: |
      #!/bin/bash

      # Define the local directory
      LOCAL_DIR="/root/cloudstack"  

      # Navigate to the repository directory
      cd "$LOCAL_DIR" || exit

      # Fetch the latest changes
      git fetch

      # Check for new commits and pull if there are any
      if [ $(git rev-list HEAD...origin/main --count) -gt 0 ]; then
        echo "New commits found. Pulling changes..."
        git pull origin main
        docker-compose -f /root/cloudstack/${apps_directory}/docker-compose.yaml up -d
      else
        echo "No new commits found."
      fi
    permissions: '0755'
    owner: root:root

  - path: /etc/systemd/system/infisical-sync.service
    content: |
      [Unit]
      Description=Infisical Secrets Sync Service
      After=network.target
      
      [Service]
      Type=oneshot
      ExecStart=/usr/local/bin/sync-infisical-secrets.sh
      
      [Install]
      WantedBy=multi-user.target
    permissions: '0644'
    owner: root:root
  
  - path: /etc/systemd/system/infisical-sync.timer
    content: |
      [Unit]
      Description=Run Infisical Secrets Sync periodically
      
      [Timer]
      OnBootSec=3min
      OnUnitActiveSec=3m
      
      [Install]
      WantedBy=timers.target
    permissions: '0644'
    owner: root:root

  - path: /usr/local/bin/sync-infisical-secrets.sh
    content: |
      #!/bin/bash

      # Load environment variables
      CLIENT_ID="${INFISICAL_CLIENT_ID}"
      CLIENT_SECRET="${INFISICAL_CLIENT_SECRET}"
      PROJECT_ID="${INFISICAL_PROJECT_ID}"
      DOMAIN="${INFISICAL_API_URL}"  # TODO: check if can export this directly.

      # If DOMAIN is not set, default to https://eu.infisical.com
      if [ -z "$DOMAIN" ]; then
        DOMAIN="https://app.infisical.com/api"
      fi

      # Base directory
      BASE_DIR="/root/cloudstack/examples/basic/apps"

      # Iterate through each subdirectory in /root/cloudstack/examples/basic/apps
      cd "$BASE_DIR"
      for dir in */; do
          # Check if it's a directory
          if [ -d "$dir" ]; then
              echo "Processing directory: $dir"

              # Log in to Infisical
              echo "Logging in to Infisical..."
              export INFISICAL_TOKEN=$(infisical login --method=universal-auth --client-id="$CLIENT_ID" --client-secret="$CLIENT_SECRET" --silent --plain --domain "$DOMAIN")

              # Check if login was successful
              if [ $? -eq 0 ]; then
                  echo "Login successful for directory: $dir"

                  # Export environment variables
                  echo "Exporting environment variables for project ID: $PROJECT_ID in directory: $dir"
                  infisical export --env=prod --path="/$dir" --projectId="$PROJECT_ID" --domain "$DOMAIN" > "$dir/.secrets"

                  if [ $? -eq 0 ]; then
                      echo "Export successful for directory: $dir"
                  else
                      echo "Error: Export failed for directory: $dir"
                  fi
              else
                  echo "Error: Login failed for directory: $dir"
              fi
          else
              echo "Skipping non-directory: $dir"
          fi
      done

      echo "Script execution completed."
    permissions: '0755'
    owner: root:root

runcmd:
  - systemctl daemon-reload
  - systemctl enable repo-sync.timer
  - systemctl start repo-sync.timer
  - systemctl enable infisical-sync.timer
  - systemctl start infisical-sync.timer

  - mkdir  /mnt/data
  - mount -o discard,defaults ${linux_device} /mnt/data
  - echo "${linux_device} /mnt/data ext4 discard,nofail,defaults 0 0" >> /etc/fstab
  
  
  # install tailscale
  - curl -fsSL https://tailscale.com/install.sh | sh
  - tailscale up --advertise-routes="${tailscale_routes}" --accept-routes --auth-key="${tailscale_auth_key}"
  
  # Infisical
  - curl -1sLf 'https://dl.cloudsmith.io/public/infisical/infisical-cli/setup.deb.sh' |  bash
  - apt-get update
  - apt-get install -y infisical
  
  # install extra-tools
  - curl https://rclone.org/install.sh | bash
  - apt-get install -y cifs-utils
  
  # setup ufw
  - ufw allow OpenSSH
  - ufw --force enable
  
  # Docker install
  - curl -fsSL https://get.docker.com -o get-docker.sh
  - sh get-docker.sh
  - systemctl daemon-reload
  - systemctl restart docker
  - systemctl enable docker
  - printf '\nDocker installed successfully\n\n'
  - printf 'Waiting for Docker to start...\n\n'
  - sleep 5
  
  # Docker Compose
  - COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
  - curl -L https://github.com/docker/compose/releases/download/$COMPOSE_VERSION/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
  - chmod +x /usr/local/bin/docker-compose
  - curl -L https://raw.githubusercontent.com/docker/compose/$COMPOSE_VERSION/contrib/completion/bash/docker-compose > /etc/bash_completion.d/docker-compose
  - printf '\nDocker Compose installed successfully\n\n'
  - docker-compose -v
  
  # Clone apps repo 
  - git clone ${apps_repository_url} /root/cloudstack
  # Get all secret
  - sh /usr/local/bin/sync-infisical-secrets.sh
  # start containers
  - docker-compose -f /root/cloudstack/${apps_directory}/docker-compose.yaml up -d

