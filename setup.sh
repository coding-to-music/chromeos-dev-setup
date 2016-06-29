#!/bin/bash
{
  C9IO=false
  GITWEBUI=false
  POSTGRES=false
  DELUGE=false
  C9=false
  PGWEB=false
  DROPBOX=false
  
  if [ -z $C9_SHARED ]; then
    C9IO=true
  fi
    
  # General dependencies
  if [ -z `command -v add-apt-repository` ] || [ ! $C9IO = "true" ]; then 
    sudo apt-get update && sudo apt-get upgrade -y
    sudo apt-get install -y libssl-dev build-essential software-properties-common openssh-client man
    # TODO: per-package checks/installs  
  fi
  
  # Git 
  if [ -z `command -v git` ]; then
    if [ -z $EMAIL ]; then
      read -p "Enter your email for git commits: " EMAIL
    fi
    
    if [ -z $NAME ]; then
      read -p "Enter your name for git commits: " NAME
    fi
    sudo apt-get install -y git
    git config --global user.name "$NAME"
    git config --global user.email "$EMAIL"
  fi
  
  # Git-WebUI
  if [[ $@ == *"git-webui"* ]] || [ -z $@ ]; then
    cd ~/
    git clone https://github.com/alberthier/git-webui.git
    git config --global alias.webui \!$PWD/git-webui/release/libexec/git-core/git-webui
    GITWEBUI=true
  fi

  # Python
   if [[ $@ == *"python"* ]] || [ -z $@ ]; then
    sudo add-apt-repository -y ppa:fkrull/deadsnakes
    sudo apt-get install -y python2.7
  fi
  
  # Golang
   if [[ $@ == *"golang"* ]] || [ -z $@ ]; then
    sudo add-apt-repository -y ppa:ubuntu-lxc/lxd-stable
    sudo apt-get install -y golang
    mkdir -p ~/gopath
    echo "export GOPATH=~/gopath" >> ~/.bash_profile
    source ~/.bash_profile
  fi
    
  # NodeJS
   if [[ $@ == *"nodejs"* ]] || [ -z $@ ]; then
    git clone https://github.com/creationix/nvm.git ~/.nvm
    cd ~/.nvm
    git checkout `git describe --abbrev=0 --tags`
    . ~/.nvm/nvm.sh
    echo "export NVM_DIR=$HOME/.nvm" >> ~/.bash_profile
    echo "[ -s $NVM_DIR/nvm.sh ] && . $NVM_DIR/nvm.sh" >> ~/.bash_profile
    source ~/.bash_profile
    nvm install node
  fi
    
  # PostgreSQL, preinstalled on c9.io
   if [[ $@ == *"postgres"* ]] || [ -z $@ ]; then
     if [ ! $C9IO = "true" ]; then
        sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
        wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | sudo apt-key add -
        sudo apt-get install -y postgresql postgresql-contrib
    fi
    POSTGRES=true
  fi
  
  # Install Deluge (torrent), disabled on c9.io
   if [ ! $C9IO = "true" ] && [[[ $@ == *"deluge"* ]] || [ -z $@ ]]; then
    sudo add-apt-repository -y ppa:deluge-team/ppa
    sudo apt-get install -y deluge deluge-webui
    sudo adduser --disabled-password --system --home /var/lib/deluge --geeks "Deluge service" --group deluge
    sudo touch /var/log/deluged.log
    sudo touch /var/log/deluge-web.log
    sudo chown deluge:deluge /var/log/deluge*
    sudo curl -o /etc/systemd/system/deluged.service https://raw.githubusercontent.com/benlowry/chromeos-setup/master/deluged.service
    sudo curl -o /etc/systemd/system/deluge-web.service https://raw.githubusercontent.com/benlowry/chromeos-setup/master/deluge-web.service
    sudo service deluged start
    DELUGE=true
    # sudo service deluge-web start 
    # start: /usr/bin/deluge-web
  fi
  
  # Install C9 IDE, preinstalled on c9.io obviously 
   if [ ! $C9IO = "true" ] && [[[ $@ == *"c9"* ]] || [ -z $@ ]]; then
    git clone git://github.com/c9/core ~/c9
    cd ~/c9/scripts
    ./install-sdk.sh
    cd ~/
    C9=true
    # start: node server.js -w ~/projectfolder --listen 0.0.0.0 --port=81
  fi
  
  # Install PGWeb
   if [[ $@ == *"pgweb"* ]] || [ -z $@ ]; then
    go get github.com/sosedoff/pgweb
    PGWEB=true
    # start: $GOPATH/bin/pgweb —bind=0.0.0.0 —listen=82
  fi

  # Dropbox
   if [[ $@ == *"dropbox"* ]] || [ -z $@ ]; then
    cd ~ && wget -O - "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf -
    DROPBOX=true
    # start: ~/.dropbox-dist/dropboxd
  fi

  # SSH key
  if [ ! -f ~/.ssh/id_rsa ]; then
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    touch ~/.ssh/authorized_keys
    chmod 644 ~/.ssh/authorized_keys
    chown $USER:$USER ~/.ssh/authorized_keys
    chown $USER:$USER ~/.ssh
    ssh-keygen -t rsa -b 4096 -C "$EMAIL"  -f ~/.ssh/id_rsa -N ''
    chmod 600 ~/.ssh/id_rsa*
  fi
  
  SSHKEY=`cat ~/.ssh/id_rsa.pub`
  
  echo '----------------------------------------'
  echo 'Setup complete'
  echo '----------------------------------------'
  echo 'SSH KEY starts on the line below:'
  echo $SSHKEY
  
  # startup notes and setup completion notes
  if [ $C9 = "true" ]; then
    echo '----------------------------------------'
    echo 'C9 browser IDE can be started with:'
    echo '$ node server.js -w ~/yourproject --listen 0.0.0.0 --port=81'
    echo 'Open in your browser at http://127.0.0.1:81/'
  fi
  
  if [ $POSTGRES = "true" ]; then
    echo 'PostgreSQL can be started with:'
    echo '$ sudo service postgresql start'
  fi
  
  if [ $PGWEB = "true" ]; then
    echo '----------------------------------------'
    echo 'PGWeb interface for PostgreSQL can be started with:'
    echo '$ $GOPATH/bin/pgweb —bind=0.0.0.0 —listen=82'
    echo 'Open in your browser at http://127.0.0.1:82/'
  fi
  
  if [ $DELUGE = "true" ]; then
    echo '----------------------------------------'
    echo 'Deluge torrent server and web interface can be started with:'
    echo '$ sudo user/bin/deluge-web --port 83'
    echo 'Open in your browser at http://127.0.0.1:83/'
  fi
   
  if [ $GITWEBUI = "true" ]; then
    echo '----------------------------------------'
    echo 'Git WebUI can be started from your project directory with:'
    echo '$ git webui --port 84 --host 0.0.0.0 --no-browser'
    echo 'Open in your browser at http://127.0.0.1:84/'
  fi
  
  if [ $DROPBOX = "true" ]; then
    echo '----------------------------------------'
    echo 'Dropbox setup can be completed by:'
    echo '$ ~/.dropbox-dist/dropboxd'
  fi
}
