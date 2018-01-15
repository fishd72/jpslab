#!/bin/bash

# Author:   Stephen Bygrave - wegotoeleven
# Name:     jpslabSetup.sh
#
# Purpose:  Sets up a Tomcat, MySQL and a JSS based on the JSS webapp from Jamf
# Usage:    Vagrant Shell provisioner
#
# Version 1.0.0, 2018-01-07
#   SB - Initial Creation

# Use at your own risk. wegotoeleven will accept no responsibility for loss or
# damage caused by this script.

##### Set variables

mysqlRootPass=""
db=""
dbUser=""
dbPass=""
jpUser=""
jpPass=""
activationCode=""
institutionName=""

# Do not change the below variables
logFile="/vagrant/logs/vagrantBuild.log"
logProcess="jsslabSetup"

##### Declare functions

writelog ()
{
    /usr/bin/logger -is -t "${logProcess}" "${1}"
}

echoVariables ()
{
    if [[ -z "${mysqlRootPass}" || -z "${db}" || -z "${dbUser}" || -z "${dbPass}" || -z "${jpUser}" || -z "${jpPass}" || -z "${activationCode}" || -z "${institutionName}" ]]
    then
        writelog "One more or variables are empty. Please assign values to any missing variables and try again. Bailing..."
        exit 1
    fi
    writelog "Log Process is ${logProcess}"
    writelog "Log file is stored at ${logFile}"
    writelog "MySQL root password is ${mysqlRootPass}"
    writelog "MySQL database name is ${db}"
    writelog "MySQL database user is ${dbUser}"
    writelog "MySQL database user password is ${dbPass}"
    writelog "Jamf Pro admin user is ${jpUser}"
    writelog "Jamf Pro admin user password is ${jpPass}"
    writelog "Jamf Pro activation code is ${activationCode}"
    writelog "Institution name is ${institutionName}"
}

checkForJamfProData ()
{
    # Checks for the existence of the Jamf Pro webapp in the Vagrant folder;
    # exits if not found.
    webapp=$(ls /vagrant/webapp/ | grep .war)
    if [[ -z "${webapp}" ]];
    then
        writelog "Jamf Pro webapp not found. Please add the webapp to the vagrant folder and try again."
        exit 1
    fi
}

installRequired ()
{
    # Update Package Manager
    apt update >> "${logFile}" 2>&1

    # Install OpenJDK, Tomcat, Unzip and Avahi
    writelog "Installing Open Java JDK and Tomcat 8..."
    apt install -y openjdk-8-jdk tomcat8 unzip avahi-daemon >> "${logFile}" 2>&1

    # copy Java memory settings script to tomcat8
    cat << EOF > "/usr/share/tomcat8/bin/setenv.sh"
#!/bin/bash
export CATALINA_OPTS="-Xms512M -Xmx512M -Djava.awt.headless=true -server"

EOF
    chmod a+x "/usr/share/tomcat8/bin/setenv.sh"

    # Install MySQL 5.7
    writelog "Installing MySQL Server..."
    export DEBIAN_FRONTEND="noninteractive"
    debconf-set-selections <<< "mysql-server mysql-server/root_password password ${mysqlRootPass}"
    debconf-set-selections <<< "mysql-server mysql-server/root_password_again password ${mysqlRootPass}"
    apt install -y mysql-server >> "${logFile}" 2>&1
}

createDB ()
{
    # Create MySQL database and setup users and grants
    writelog "Creating Database..."
    mysql -uroot -p"${mysqlRootPass}" -e "CREATE DATABASE ${db};" >> "${logFile}" 2>&1
    mysql -uroot -p"${mysqlRootPass}" -e "CREATE USER ${dbUser}@localhost IDENTIFIED BY '${dbPass}';" >> "${logFile}" 2>&1
    mysql -uroot -p"${mysqlRootPass}" -e "GRANT ALL PRIVILEGES ON ${db}.* TO '${dbUser}'@'localhost';" >> "${logFile}" 2>&1
    mysql -uroot -p"${mysqlRootPass}" -e "FLUSH PRIVILEGES;" >> "${logFile}" 2>&1
}

installJamfProWebApp ()
{
    # Install Jamf Pro webapp
    service tomcat8 stop
    writelog "Installing Jamf Pro webapp..."
    rm -f "/var/lib/tomcat8/webapps/ROOT.war"
    rm -rf "/var/lib/tomcat8/webapps/ROOT"
    # Unzip the war file and edit the location of the logs
    unzip "/vagrant/webapp/${webapp}" -d "/var/lib/tomcat8/webapps/ROOT" >> "${logFile}" 2>&1
    chown -R tomcat8:tomcat8 "/var/lib/tomcat8/webapps/ROOT"
    sed -i "s/\/Library\/JSS\/Logs/\/vagrant\/logs/g" "/var/lib/tomcat8/webapps/ROOT/WEB-INF/classes/log4j.properties"

    # Configure Database connection in the DataBase.xml file
    writelog "Configuring Database connection..."
    sed -i "s/<DataBaseName>.*<\/DataBaseName>/<DataBaseName>${db}<\/DataBaseName>/g" "/var/lib/tomcat8/webapps/ROOT/WEB-INF/xml/DataBase.xml"
    sed -i "s/<DataBaseUser>.*<\/DataBaseUser>/<DataBaseUser>${dbUser}<\/DataBaseUser>/g" "/var/lib/tomcat8/webapps/ROOT/WEB-INF/xml/DataBase.xml"
    sed -i "s/<DataBasePassword>.*<\/DataBasePassword>/<DataBasePassword>${dbPass}<\/DataBasePassword>/g" "/var/lib/tomcat8/webapps/ROOT/WEB-INF/xml/DataBase.xml"

    # Start Tomcat
    service tomcat8 start
}

configureJamfProServer ()
{
    # Configure Jamf Pro settings via UAPI; this will use the existing hostname
    # of the server that Jamf Pro is being installed onto
    writelog "Configuring Jamf Pro Server via UAPI..."
    curl -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{
        "activationCode": "'${activationCode}'",
        "institutionName": "'${institutionName}'",
        "isEulaAccepted": true,
        "username": "'${jpUser}'",
        "password": "'${jpPass}'",
        "email": "",
        "jssUrl": "http://'$(hostname)'.local:8080"
    }' "http://localhost:8080/uapi/system/initialize" >> "${logFile}" 2>&1
}

##### Run script

if [[ ! -d "/vagrant/logs" ]];
then
    mkdir "/vagrant/logs"
fi
chmod 777 "/vagrant/logs"

echoVariables
checkForJamfProData
installRequired
createDB
installJamfProWebApp
configureJamfProServer

writelog "Script completed."
