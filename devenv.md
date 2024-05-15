```shell
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker $USER
sudo systemctl enable docker

# Install Code Server
curl -fsSL https://code-server.dev/install.sh | sh
sudo systemctl enable --now code-server@$USER
sudo setcap 'cap_net_bind_service=+ep' /usr/lib/code-server/lib/node
# Edit ~/.config/code-server/config.yaml --> 0.0.0.0:80 and auth: none

# install Cascadia Code
wget https://github.com/microsoft/cascadia-code/releases/download/v2404.23/CascadiaCode-2404.23.zip -O cascadiacode.zip
unzip -d cascadia-code cascadiacode.zip
sudo mkdir -p /usr/share/fonts
sudo cp -r cascadia-code/ttf /usr/share/fonts/cascadia-code
rm -rf cascadia-code cascadiacode.zip
```