# JPSlab (Jamf Pro Server Lab)

JPSlab is an automated Jamf Pro Server deployment, leveraging Vagrant to quickly spin up a customised JPS.

## Features

- Installs MySQL 5.7 and Tomcat 8
- Avahi, for .local visibility
- Easy webapp unpacking of any version of Jamf Pro / Casper
- Automated Database Creation
- Logging to the host machine
- UAPI uploads to automatically insert a Jamf Pro license key and admin user creation
- Works with vagrant-dplab

## Getting Started

### Prerequsites

- Access to a Jamf Pro ROOT.war file and valid license key (including NFR keys)
- Virtualbox or VMware Fusion
- Vagrant

### Instructions

1. Clone this repository to your local Mac
2. Amend the Vagrant base box location from the Vagrantfile to your preferred Vagrant Ubuntu box
3. Edit the `jpslabSetup.sh` script, adding in the required variables as necessary
4. Copy a Jamf Pro webapp file `ROOT.war` into the `webapp` directory within this repo
3. Run `vagrant up` from within the working Vagrant folder
4. By default, the JPS will be available on port 8080

## More to come...!
