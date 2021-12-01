#!/bin/bash

#This script is meant to do the following in order to kickstart the process of
#Automating the installation and configuration of: 
# 1) Docker / Docker Compose
# 2) Mailu/PostFix docker container
# 3) vsftpd secure server setup with SSL for file transfers
# 4) WordPress, including MariaDB + (othersstuff) 

#Shell Script to deploy docker, docker compose, mailu, and WordPress, Nginx, MariaDB, etc (use wordops for jumping off point but dont use them)
#OPTIONAL - DELETE FOR VULR DEPLOY SCRIPT -- adding a ftp server to enable uploading the script
#optionally install ftp server for easier file transfer, may do a how to where the script is ran from shell after ftping it in instead
#man yes | sudo apt install vsftpd

#########################################################################
#Define Variables for the server/user configuratins
newservername='mail.yourserver.com'					#The server will be renamed to whatever this is set to - the domain should match your web domain
domain='thecovidresponse.com'									#I chose the name HomeBase because it is going to be running Mail, Web, etc -- its the Home Base of Operations
publicip=$(dig @resolver4.opendns.com myip.opendns.com +short)  #The public IP is captured, which will help automate updating the hosts file later
newadminuser='adam'  											#This user will be able to launch docker without sudo, and have elevated priveledge
newadminpw='EnterPWHERE!!!!'								#It should be customized to your liking by default it will be added to the docker group + have sudo priveledge								
	
#MailU Setup: define the URL's for your mailu configuration -- these URL's can be generated by running the MailU setup here: https://setup.mailu.io/1.8/ 
#Mailu Setup: Additional resources can be found here: https://inguide.in/mailu-docker-compose-setup-build-self-hosted-mail-server/ and here:  https://www.youtube.com/watch?v=LwNOb7Qz-VQ
#
#Steps to select for Mailu Setup from InGuide link: Compose > Enter $domain for "main main domain and server display name" > check Enabled the Admin UI
#  Select RoundCube for "Enable Web email client", check enable for AntiVirus, Webdav, and fetchmail > IPv4 listen address should be set to the $publicIP > Check "Enable Unbound Resolver" >
#  Enter 

dockerymlfileurl='https://setup.mailu.io/1.8/file/082ffde3-e01f-4ceb-a7f7-1a2b90b03238/docker-compose.yml'
mailuenvfileurl='https://setup.mailu.io/1.8/file/082ffde3-e01f-4ceb-a7f7-1a2b90b03238/mailu.env'

#########################################################################

#Reminder that A + MX records must be added to the DNS settings on the registrar for $domain before running this script for everything to run as smooth as possible!
echo "INFO: REMINDER - you will want to add the following entries under DNS Setup on the registrar's panel for $domain." >> /nextsteps.txt
echo "			Type		Host		Value				" >> /nextsteps.txt
echo "			A		mail		$publicip			" >> /nextsteps.txt
echo "			MX		@		$newservername		" >> /nextsteps.txt
echo " This should have been done prior to running the script, but if it was not done the info has  been exported to /nextsteps.txt in the root drive."
echo " Any steps that may need done outside of the script will be captured in that document!"

tput setaf 0 && tput setb 6 
echo "IMPORTANT INFO: A text file detailing what steps are to be performed after this script is ran can be found in the root drive /nextsteps.txt !"
echo "				 The DNS entries listed above will be saved in that file, and this is used several other times in the script as well."
tput sgr0

#Download & install curl if not present, so curl can be used to download docker install files from the docker managed repo, the vultr hostname info, etc
#    tput is being used to set the info text to green bg/ black foreground, and is used for most of the INFO: displays throughout  
apt install curl
tput setaf 0 && tput setb 2 			#tput setaf 0 && tput setb 2 is being used to set the console colors for the information screen when using an interactive console.
echo "INFO: CURL has been installed."
tput sgr0 								#tput sgr0 is being used to set the console colors back to default (this is used throughout the script and I'm guessing a cleaner way to do it exists, maybe ver2

#Display basic information on initial server state
#Gather the servername using Vultr's isntance Metadata API heredocumented: https://www.vultr.com/metadata/#v1_interfaces_0_ipv4_address
defaultservername=$(curl "http://169.254.169.254/v1/hostname")
echo $defaultservername is the current host name assigned by Vultr

#Rename the server to whatever the variable newservername was set to above, prior to making any changes or installs since many of the apps rely on it.
tput setaf 0 && tput setb 2 
echo "INO: Changing server hostname to $newservername"
tput sgr0
hostnamectl set-hostname $newservername
tput setaf 0 && tput setb 2 
echo "INO: Displaying newly configured server hostname information"
tput sgr0
hostnamectl

#First Update the OS + add debian repos + install/configure Docker (see: https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-20-04)
man yes | apt-get install sudo
sudo -i
tput setaf 0 && tput setb 2 
echo "INFO: Sudo has been installed (if it was not already present). Beginning Debian Distribution upgrade."
tput sgr0
apt dist-upgrade -y
apt update -y
man yes | apt autoremove
tput setaf 0 && tput setb 2 docker
echo "INFO: OS has been upgraded." 
tput sgr0 

#Install nano text editor (builtin to ubuntu 20.04, but including to ensure compatibility)
sudo apt install nano -y
tput setaf 0 && tput setb 2 
echo "INFO: nano text editor has been installed."
tput sgr0

#NOTE: THIS SECTION HAS BEEN MOVED TO THE VULTR BOOT SCRIPT AND IS NOW REDUNDANT
#Add the newadminuser to the server - see https://askubuntu.com/questions/94060/run-adduser-non-interactively
#tput setaf 0 && tput setb 6 
#echo "IMPORTANT INFO: Adding user '$newadminuser' to the server, and configuring a forced PW change for next logon"
#tput sgr0
#apt-get install adduser
#adduser --gecos "" --disabled-password $newadminuser
#tput setaf 0 && tput setb 6
#echo "IMPORTANT INFO: setting '$newadminpw' for user '$newadminuser' -- YOU MUST CHANGE THIS BY LOGGING ON AS SOON AS THIS SCRIPT COMPLETES TO MAINTAIN SERVER SECURITY"
#tput sgr0
#chpasswd <<<"$newadminuser:$newadminpw"
#passwd --expire $newadminuser
#tput setaf 0 && tput setb 6
#echo "INFO: Adding '$newadminuser' to the sudoers list"
#tput sgr0
#usermod -aG sudo $newadminuser

#tput setaf 0 && tput setb 6
#echo "IMPORTANT INFO: the account $newadminuser has been created with a temp password set to $newadminpw -- THIS MUST BE CHANGED NEXT LOGON."
#echo "				: Simply sign in as $newadminuser, and set a new secure password after this install has completed. 						" >> /nextsteps.txt
#echo "		There will be several other small steps you will need to complete at that time as well, to wrap up the various installs in progress."
#echo " 												Incstructins will be provided!																"
#tput sgr0
#echo ""

apt install apt-transport-https ca-certificates curl software-properties-common
#man yes | curl -fsSL https://download.docker.com/linux/ubuntu/gpg #WARNING - ran into issues here with a yes to continue, may require some re-working
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

tput setaf 0 && tput setb 2 
echo "INFO: The GPG key for the official Docker repository has been added to the system."
tput sgr0
man yes | add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
tput setaf 0 && tput setb 2 
echo "INFO: The Docker repository for Debian has been added to the repository list."
tput sgr0

#Runnint apt-cache cmd to verify we are going to install from the docker repo not ubuntu's (download.docker.com)
tput setaf 0 && tput setb 2 
echo "INFO: Displaying the repo we are about to pull docker from -- it should show download.docker.com.  
            If it does not, then you will want to reinstall manually after the depoloyment script has ran.
" 
#longterm it would be better to have this actually check the output and act based on it rather than rely on user review, but this is just the first rough version and if you ran with servers that already had bits installed it would be #fine the wording just will be a little off in the INFO: messages
tput sgr0
apt-cache policy docker-ce


#Install docker
tput setaf 0 && tput setb 2 
echo "INFO: Installing Docker-ce package"
tput sgr0
man yes | sudo apt install docker-ce
tput setaf 0 && tput setb 2 
echo "INFO: Docker install complete."
echo "INFO: Displaying docker status -- you should see Active: active (running) in green if it is working properly" #Long term there should  be an actual logic check here
tput sgr0
sudo systemctl status docker
tput setaf 0 && tput setb 2
echo "INFO: Running docker hello-world, which will verify each component of docker is working properly"
tput sgr0
docker run hello-world 

#Configure the new admin user to be able to use docker without having to use Sudo
sudo usermod -aG docker $newadminuser
tput setaf 0 && tput setb 2
echo "INFO: User $(newadminuser) has been added to the docker group -- after the install has completed, login as Adam and type 'groups' and enter your PW." >> /nextsteps.txt
echo "		Once you type the 'Groups' command you should see 'adam sudo docker' all listed, and be able to run the cmd 'docker images' without suod." >> /nextsteps.txt
echo "		You should see an imag for hello-world and mailu/postfix when that command is ran." >> /nextsteps.txt
tput sgr0

#Search docker + download mailu/postfix match, then display downloaded docker images (should include hello world + mailu/postfix)
tput setaf 0 && tput setb 2
echo "INFO: Searching for MailU docker image."
sudo Docker search mailu
echo "INFO: Downloading for MailU docker image."
sudo docker pull mailu/postfix
echo "INFO: Displaying downloaded docker images -- you should see hello-world + Mailu/PostFix."
tput sgr0
sudo docker images

#mailu/postfix should be listed, then install curl + use curl to download docker compose (See: https://phoenixnap.com/kb/install-docker-compose-on-ubuntu-20-04 )
tput setaf 0 && tput setb 2
echo "INFO: Running apt update/upgrade prior to installing docker compose."
tput sgr0
Apt update
Apt upgrade
tput setaf 0 && tput setb 2
echo "INFO: Updates complete."
echo "INFO: Downloading docker compose fromg GitHub"
tput sgr0
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
tput setaf 0 && tput setb 2
echo "INFO: Making the downloaded files executable"
tput sgr0
sudo chmod +x /usr/local/bin/docker-compose
tput setaf 0 && tput setb 2
echo "INFO: Displaying Docker Compose version info."
tput sgr0
sleep 45s
sudo docker-compose --version
tput setaf 0 && tput setb 2
echo "INFO: Docker Compose installation is complete."
tput sgr0

#Enable SSH , HTTP/S, + the UFW (Universal FireWall)
tput setaf 0 && tput setb 2
echo "INFO: Deploying/Enabling the Uncomplicated FireWall, and configuring it to work with MailU + WordPress"
echo "INFO: Enabling SSH (required for MailU + WordPress"
tput sgr0
ufw allow ssh
tput setaf 0 && tput setb 2
echo "INFO: Enabling HTTP/HTTPS (required for WordPress" #https://spinupwp.com/hosting-wordpress-setup-secure-virtual-server/
tput sgr0
ufw allow http
ufw allow https
tput setaf 0 && tput setb 2
echo "INFO: Allowing ports 25,80,443,110,143,465,587,993,995/tcp in UFM for MailU/WordPress"
tput sgr0
sudo ufw allow 25,80,443,110,143,465,587,993,995/tcp
#Enabling ports in firewall for WordPress, see: https://spinupwp.com/hosting-wordpress-setup-secure-virtual-server/
tput setaf 0 && tput setb 2
echo "INFO: Allowing port 22 for WordPress"     #Redundant but tidying up next revision
tput sgr0
sudo ufw allow 22/tcp

#Enabling firewall settings for vsftpd - see https://devanswers.co/install-ftp-server-vsftpd-ubuntu-20-04/

#Configuringthe firewall for vsftpd
tput setaf 0 && tput setb 2
ECHO "INFO: Updating FireWall rules + Enabling UFW"
sudo ufw allow OpenSSH comment "VFTPD: https://devanswers.co/install-ftp-server-vsftpd-ubuntu-20-04/"
tput sgr0
tput setaf 0 && tput setb 2
sudo ufw allow 20/tcp comment "VFTPD:"
tput sgr0
sudo ufw allow 40000:50000/tcp comment "VFTPD: for passive FTP"
tput sgr0
sudo ufw allow 990/tcp comment "VFTPD: port 990 for TLS"
tput sgr0
sudo ufw allow OpenSSH comment "VFTPD:"


#Creating HOSTS file entry to assist with MailU configuration
#Define the string to be added to the hosts file
newhostsstring="$publicip $newservername mail"
tput setaf 0 && tput setb 2
echo "INFO: Adding $newhostsstring to /etc/hosts file to assist with MailU configuration"
echo "	  : See  https://inguide.in/mailu-docker-compose-setup-build-self-hosted-mail-server/ Initial Server Setup for Mailu section for exact steps this is completing"
#Echoing a commented out description to the hosts file, followed by the hosts entry itself
echo "#Entry to assist with MailU configuration - See https://inguide.in/mailu-docker-compose-setup-build-self-hosted-mail-server/ 'Initial Server Setup' for detailed steps" >> /etc/hosts
echo $newhostsstring >> /etc/hosts
tput sgr0

#Install the MailU dependancies - NOTE: there are some redundant ones here due to following several tutorials to create this single script. I plan to cleanup later, right now it just skips reinstalling if the app is already present so it's just a bit of clutter.
tput setaf 0 && tput setb 2
echo "INFO: Installing MailU dependancies"
tput sgr0
sudo apt-get update
sudo apt-get install \
   apt-transport-https \
   ca-certificates \
   curl \
   gnupg \
   lsb-release
#Install the official docker pgp key
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
tput setaf 0 && tput setb 2
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
tput sgr0
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io
tput setaf 0 && tput setb 2
echo "INFO: testing docker functionality by launching hello world:"
tput sgr0
sudo docker run hello-world
echo "INFO: Creating /mailu directoy and downloading configuration files linked after running through the setup questionaire + stored as dockerymlfileurl / mailuenvfileurl"
mkdir /mailu
cd /mailu
#These files/URLS are generated by the online MailU Configuration utility: https://setup.mailu.io/1.8/ , and should have been entered in the variables above before running the script
wget $dockerymlfileurl
wget $mailuenvfileurl

#Change the docker-compose yml file so that port 25 on the docker container goest through port 587 instead, which will allow it work on Vultr (and probably many more cloud platforms)
tput setaf 0 && tput setb 2
echo "INFO: Updating /mailu/docker-compose.yml file to redirect the containers port 25 to port 587 on the host, to make it possible to run mailu on vultrs cloud (which blocks port 25)"
echo "		See https://docs.docker.com/config/containers/container-networking/ for more information to get a better understading of what changes are happening here."
sed -i 's/:25:25/:587:25/' /mailu/docker-compose.yml
tput sgr0

#Compose the project with the following commands
tput setaf 0 && tput setb 2
echo "INFO: Composing the docker project"
tput sgr0
export MAILU_VERSION=1.8
docker-compose -p mailu up -d

#Create an admin account for mailu
echo "INFO: Creating the mailu login admin@$domain with the same password used for $newadminuser admin account during initial setup (stored as newadminpw)"
docker-compose -p mailu exec admin flask mailu admin admin thecovidresponse.com $newadminpw

echo "INFO: MailU install is complete! To login navigate to https://$domain/admin"
echo "		Login with username admin@domain and password $newadminpw"

echo "INFO: Follow along with the 'MailU First Run' steps at: https://inguide.in/mailu-docker-compose-setup-build-self-hosted-mail-server/ to complete the install from the GUI." >> /nextsteps.txt

#Finally, enabling the firewall after all of the config changes
tput setaf 0 && tput setb 2
echo "INFO: Enabling UFW (Uncomplicated FireWall)"
tput sgr0
ufw enable

