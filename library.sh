# The script will use the latest versions from thte download section

DCV_VERSION=2023.1
#DCV_SM_BROKER_VERSION=2023.1.410-1
#DCV_SM_AGENT_VERSION=2023.1.732-1
#DCV_SM_GW_VERSION=2023.1.710-1
#DCV_SM_CLI_VERSION=1.1.0-140
#DCV_SM_BROKER_VERSION=""
#DCV_SM_AGENT_VERSION=""
#DCV_SM_GW_VERSION=""
#DCV_SM_CLI_VERSION=""

checkCentosVersion()
{
	if [ -f /etc/centos-release ]
	then
		if ! cat /etc/centos-release | egrep -iq 8
		then
			echo "At the moment this script just support CentOS 8. Aborting..."
			exit 18		
		fi
	else
		echo "At the moment we just support CentOS distro. Aborting..."
		exit 19
	fi
}

disableIpv6()
{
	cat << EOF | sudo tee --append /etc/sysctl.conf
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF
	sudo sysctl -p
	sudo sed -i '/^net.ipv6.conf.*disable_ipv6 = .*$/d' /etc/sysctl.conf
}

enableIpv6()
{
    cat << EOF | sudo tee --append /etc/sysctl.conf
net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.default.disable_ipv6 = 0
net.ipv6.conf.lo.disable_ipv6 = 0
EOF
	sudo sysctl -p
}

readTheServiceSetupAnswer()
{
	echo -e "If yes, please type \"${GREEN}yes${NC}\" without quotes. Everything else will not be understood as yes."
	read service_setup_answer
	service_setup_answer=$(echo $service_setup_answer | tr '[:upper:]' '[:lower:]')
}

askAboutServiceSetup()
{
	service_name=$1
    if echo $service_name | egrep -iq "dcv"
    then
	        echo 
		echo -e "Do you want to install ${GREEN}Nice DCV (without gpu support)${NC}?"
		readTheServiceSetupAnswer
		nice_dcv_server_install_answer=$service_setup_answer
    elif echo $service_name | egrep -iq "agent"
    then
	        echo 
		echo -e "Do you want to install and setup ${GREEN}DCV Session Manager Agent${NC}?"
		readTheServiceSetupAnswer
		nice_dcv_agent_install_answer=$service_setup_answer
    elif echo $service_name | egrep -iq "broker"
    then
	        echo 
		echo -e "Do you want to install and setup ${GREEN}DCV Session Manager Broker${NC}?"
		readTheServiceSetupAnswer
		nice_dcv_broker_install_answer=$service_setup_answer
    elif echo $service_name | egrep -iq "gateway"
    then
	        echo 
		echo -e "Do you want to install and setup ${GREEN}DCV Connection Gateway${NC}?"
		readTheServiceSetupAnswer
		nice_dcv_gateway_install_answer=$service_setup_answer
    elif echo $service_name | egrep -iq "cli"
    then
	        echo 
		echo -e "Do you want to install and setup ${GREEN}DCV SM CLI${NC}?"
		readTheServiceSetupAnswer
		nice_dcv_cli_install_answer=$service_setup_answer
    elif echo $service_name | egrep -iq "firewall"
    then
	        echo 
		echo -e "Do you want to setup ${GREEN}firewalld and firewalld rules${NC}?"
		readTheServiceSetupAnswer
		nice_dcv_firewall_install_answer=$service_setup_answer
	else
		echo "Service to setup unknown. Aborting..."
		exit 17
	fi

}

checkIfPortIsBeingUsed()
{
	port_to_check=$1
	
	if lsof -Pi :${port_to_check} -t > /dev/null
	then
		echo -e "The script checked and the port >>> ${RED}$port_to_check${NC} <<< IS BEING used."
		port_used=1
	else
		echo -e "The script checked and the port >>> ${GREEN}$port_to_check${NC} <<<< IS NOT being used."
		port_used=0
	fi
}

setThePort()
{
	service_name=$1
	port_to_set=$2

	if echo $service_name | egrep -iq "dcv"
	then
		if [[ "{$port_to_set}x" != "x" ]]
		then
			dcv_port=$port_to_set
		fi
	elif echo $service_name | egrep -iq "agent"
	then
		if [[ "{$port_to_set}x" != "x" ]]
		then
			agent_to_broker_port=$port_to_set
		fi
	elif echo $service_name | egrep -iq "broker"
	then
		if [[ "{$port_to_set}x" != "x" ]]
		then
			client_to_broker_port=$port_to_set			
		fi
	elif echo $service_name | egrep -iq "gateway"
	then
		if [[ "{$port_to_set}x" != "x" ]]
		then
			gateway_to_broker_port=$port_to_set
		fi
	elif echo $service_name | egrep -iq "resolver"
	then
		if [[ "{$port_to_set}x" != "x" ]]
		then
			gateway_resolver_port=$port_to_set
		fi
    elif echo $service_name | egrep -iq "web resources"
    then
        if [[ "{$port_to_set}x" != "x" ]]
        then
            gateway_web_resources=$port_to_set
        fi
	else
		echo -e "The service >>> ${RED} $service_name ${NC} <<< was not recognized. Aborting..."
		exit 2
	fi
}


askThePort()
{
	service_name=$1
	port_bool="true"
	port_tmp=""

	while $port_bool
	do
		echo "###########################################"
		echo -e "Do you want to customize the ${GREEN}$service_name port${NC}?"
		if echo $service_name | egrep -iq "dcv"
		then
			echo -e "The DCV default port is >>>${GREEN}${dcv_port}${NC} <<<."
			port_tmp=${dcv_port}
		elif echo $service_name | egrep -iq "agent"
		then
			echo -e "The default DCV SM Agent to Broker port is >>> ${GREEN}${agent_to_broker_port}${NC} <<<."
			echo "This port will be used by the DCV Session Manager Agent to connect to the DCV SM Broker."
			port_tmp=${agent_to_broker_port}
		elif echo $service_name | egrep -iq "broker"
		then
			echo -e "The default DCV SM Client to Broker port is >>> ${GREEN}${client_to_broker_port}${NC} <<<."
			echo "This port will be used by DCV SM Clients (e.g. CLI) to connect to the DCV SM Broker."
			port_tmp=${client_to_broker_port}
		elif echo $service_name | egrep -iq "gateway"
		then
			echo -e "The default DCV SM Gateway to Broker  port is >>> ${GREEN}${gateway_to_broker_port}${NC} <<<."
			port_tmp=${gateway_to_broker_port}
		elif echo $service_name | egrep -iq "resolver"
		then
			echo -e "The default DCV GW Resolver port is >>> ${GREEN}$gateway_resolver_port${NC} <<<."
			port_tmp=${gateway_resolver_port}
		elif echo $service_name | egrep -iq "web resources"
		then
			echo -e "The default DCV GW Web Resources port is >>> ${GREEN}$gateway_web_resources${NC} <<<."
			port_tmp=${gateway_web_resources}
		else
			echo -e "The service >>> ${RED}$service_name${NC} <<< was not recognized. Aborting..."
			exit 3
		fi
		echo -e "If ${ORANGE}yes${NC}, please enter the port number (greater than 1000 and lower than 65536.)"
		echo -e "To use the ${GREEN}default${NC}, please just press enter."
		read port_answer

		if [[ "${port_answer}x" != "x" ]]
		then
			port_tmp=$port_answer
		fi

		if [ "$port_tmp" -gt "1000" ] && [ "$port_tmp" -lt "65536" ]
		then
			checkIfPortIsBeingUsed $port_tmp
			if [[ "$port_used" == "0" ]]
			then
				echo -e "The port >>> ${GREEN}$port_tmp${NC} <<< WAS ACCEPTED as valid option. Press enter to continue."
				read p
				port_bool="false"
			else
				echo -e "The port >>> ${RED}$port_tmp${NC} <<< WAS NOT ACCEPTED as valid option, because the port is in use by your system. The script will ask again. Press enter to continue."
				read p
			fi
		else
			echo "The number is not between 1000 and 65536. The script will ask again. Press enter to continue."
			read p
		fi
	done
	
	setThePort "$service_name" $port_tmp
}

setupNiceDcvWithoutGpu()
{
	echo -e "The script will setup ${GREEN}Nice DCV (without gpu support)${NC}."
	askThePort "Nice DCV"
		
	sudo yum -y groupinstall 'Server with GUI'
	if [[ "$?" -ne "0" ]]
	then
		echo "Failed to setup the Server GUI. Aborting..."
		exit 8
	fi

	sudo systemctl get-default
	sudo systemctl set-default graphical.target
	sudo systemctl isolate graphical.target
	sudo yum -y install glx-utils xorg-x11-drv-dummy git
    if [[ "$?" -ne "0" ]]
    then
        echo "Failed to setup the basic packages for DCV without GPU. Aborting..."
        exit 9
    fi
	
	if [ -f /etc/X11/xorg.conf  ] 
	then
		sudo cp /etc/X11/xorg.conf /etc/X11/xorg.conf-BACKUP
	fi

	cat << EOF | sudo tee /etc/X11/xorg.conf
Section "Device"
    Identifier "DummyDevice"
    Driver "dummy"
    Option "ConstantDPI" "true"
    Option "IgnoreEDID" "true"
    Option "NoDDC" "true"
    VideoRam 2048000
EndSection

Section "Monitor"
    Identifier "DummyMonitor"
    HorizSync   5.0 - 1000.0
    VertRefresh 5.0 - 200.0
    Modeline "1920x1080" 23.53 1920 1952 2040 2072 1080 1106 1108 1135
    Modeline "1600x900" 33.92 1600 1632 1760 1792 900 921 924 946
    Modeline "1440x900" 30.66 1440 1472 1584 1616 900 921 924 946
    ModeLine "1366x768" 72.00 1366 1414 1446 1494  768 771 777 803
    Modeline "1280x800" 24.15 1280 1312 1400 1432 800 819 822 841
    Modeline "1024x768" 18.71 1024 1056 1120 1152 768 786 789 807
EndSection

Section "Screen"
    Identifier "DummyScreen"
    Device "DummyDevice"
    Monitor "DummyMonitor"
    DefaultDepth 24
    SubSection "Display"
        Viewport 0 0
        Depth 24
        Modes "1920x1080" "1600x900" "1440x900" "1366x768" "1280x800" "1024x768"
        virtual 1920 1080
    EndSubSection
EndSection
EOF

	sudo systemctl isolate multi-user.target
	sudo systemctl isolate graphical.target
	
	dcv_version="2023"
	dcv_server=`curl -k --silent --output - https://download.nice-dcv.com/ | grep href | egrep "$dcv_version" | grep "el8" | grep Server | sed -e 's/.*http/http/' -e 's/tgz.*/tgz/' | head -1`

	sudo rpm --import https://d1uj6qtbmh3dt5.cloudfront.net/NICE-GPG-KEY # allow the package manager to verify the signature
	wget --no-check-certificate $dcv_server
	if [[ "$?" -eq "0" ]]
	then
		cd
		tar zxvf nice-dcv-*el8*.tgz
		rm -f nice-dcv-*el8*.tgz
		cd nice-dcv-*x86_64
		sudo yum -y install nice-dcv-server-*.el8.x86_64.rpm nice-xdcv-*.el8.x86_64.rpm nice-dcv-web-viewer*.el8.x86_64.rpm nice-dcv-gltest-*.el8.x86_64.rpm nice-dcv-simple-external-authenticator-*.el8.x86_64.rpm
		if [[ "$?" -ne "0" ]]
    	then
        	echo "Failed to setup the DCV Server. Aborting..."
        	exit 10
    	fi
		sudo systemctl isolate multi-user.target
		sudo systemctl isolate graphical.target
		cat << EOF | sudo tee /etc/dcv/dcv.conf
[license]
[log]
[session-management]
[session-management/defaults]
[session-management/automatic-console-session]
[display]
[connectivity]
web-port=$dcv_port
[security]
EOF
		cd
		sudo systemctl enable --now dcvserver
	else
		echo "Failed to download the file >>> $dcv_server <<<. Aborting..."
		exit 1
	fi

	echo "Nice DCV service was installed. Please press enter to continue the installing process or ctrl+c to stop here."
	read p
}

setupRequiredPackages()
{
    echo ""
    echo "Updating the system ... sudo yum -y update"
    echo
	sudo yum -y update
	if [[ "$?" -ne "0" ]]
    then
        echo "Failed to execute yum update. Aborting..."
        exit 11
    fi

	sudo yum -y install vim rsync mtr net-tools lsof tar unzip
	if [[ "$?" -ne "0" ]]
    then
        echo "Failed to setup the basic packages. Aborting..."
        exit 13
    fi
}

setupSessionManagerBroker()
{
	askThePort "Session Manager Broker"
	askThePort "Session Manager Agent"

	echo -e "The script also needs the ${GREEN}hostname of Session Manager${NC}. You can specify the IP address or a valid hostname."
	echo "Please type the hostname or the IP address and press enter."
	echo -e "The default is to use ${GREEN}localhost${NC} so you can just type enter and the script will configure >>> ${GREEN}localhost${NC} <<< as the hostname."
	read broker_hostname_tmp

	if [[ "${broker_hostname_tmp}x" != "x" ]]
	then
		broker_hostname=$broker_hostname_tmp
	fi


	sudo rpm --import https://d1uj6qtbmh3dt5.cloudfront.net/NICE-GPG-KEY
	# wget --no-check-certificate https://d1uj6qtbmh3dt5.cloudfront.net/${DCV_VERSION}/SessionManagerBrokers/nice-dcv-session-manager-broker-${DCV_SM_BROKER_VERSION}.el8.noarch.rpm
	wget --no-check-certificate https://d1uj6qtbmh3dt5.cloudfront.net/nice-dcv-session-manager-broker-el8.noarch.rpm
	# https://d1uj6qtbmh3dt5.cloudfront.net/2023.1/SessionManagerBrokers/nice-dcv-session-manager-broker-2023.1.410-1.el8.noarch.rpm
	
    if [[ "$?" -eq "0" ]]
    then
		sudo yum install -y nice-dcv-session-manager-broker-el8.noarch.rpm
		if [[ "$?" -ne "0" ]]
    	then
        	echo "Failed to setup the Session Manager Broker. Aborting..."
        	exit 14
    	fi
		cat << EOF | sudo tee $dcv_broker_config_file
# session-manager-working-path = /tmp
enable-authorization-server = true
enable-authorization = true
enable-agent-authorization = true
enable-persistence = false
# enable-persistence = true
# persistence-db = dynamodb
# dynamodb-region = us-east-1
# dynamodb-table-rcu = 10
# dynamodb-table-wcu = 10
# dynamodb-table-name-prefix = DcvSm-
# jdbc-connection-url = jdbc:mysql://database-mysql.rds.amazonaws.com:3306/database-mysql
# jdbc-user = admin
# jdbc-password = password
# enable-api-yaml = true
connect-session-token-duration-minutes = 60
delete-session-duration-seconds = 3600
# create-sessions-number-of-retries-on-failure = 2
# autorun-file-arguments-max-size = 50
# autorun-file-arguments-max-argument-length = 150
# broker-java-home =

client-to-broker-connector-https-port = $client_to_broker_port
client-to-broker-connector-bind-host = 0.0.0.0
#clienttobrokerkeystorefile
#clienttobrokerkeypass
#enabletlsclientauthgateway
# enable-tls-client-auth-gateway = true
# client-to-broker-connector-key-store-file = test_security/KeyStore.jks
# client-to-broker-connector-key-store-pass = dcvsm1
agent-to-broker-connector-https-port = $agent_to_broker_port
agent-to-broker-connector-bind-host = 0.0.0.0
#agenttobrokerkeystorefile
#agenttobrokerkeypass
# agent-to-broker-connector-key-store-file = test_security/KeyStore.jks
# agent-to-broker-connector-key-store-pass = dcvsm1

enable-gateway = false
#gatewayhttpsport
#gatewaybindhost
#gatewaytobrokerkeystorefile
#gatewaytobrokerkeypass
# gateway-to-broker-connector-key-store-file = test_security/KeyStore.jks
# gateway-to-broker-connector-key-store-pass = dcvsm1
#gatewaytobrokertruststorefile
#gatewaytobrokertrustpass
# gateway-to-broker-connector-trust-store-file = test_security/TrustStore.jks
# gateway-to-broker-connector-trust-store-pass = dcvsm1

# Broker To Broker
broker-to-broker-port = 47100
cli-to-broker-port = 47200
broker-to-broker-bind-host = 0.0.0.0
broker-to-broker-discovery-port = 47500
broker-to-broker-discovery-addresses = 127.0.0.1:47500
# broker-to-broker-discovery-multicast-group = 127.0.0.1
# broker-to-broker-discovery-multicast-port = 47400
# broker-to-broker-discovery-aws-region = us-east-1
# broker-to-broker-discovery-aws-alb-target-group-arn = ...
broker-to-broker-distributed-memory-max-size-mb = 4096
#brokertobrokerkeystorefile
#brokertobrokerstorepass
# broker-to-broker-key-store-file = test_security/KeyStore.jks
# broker-to-broker-key-store-pass = dcvsm1
broker-to-broker-connection-login = dcvsm-user
broker-to-broker-connection-pass = dcvsm-pass

# Metrics
# metrics-fleet-name-dimension = default
enable-cloud-watch-metrics = false
# if cloud-watch-region is not provided, the region is taken from EC2 IMDS
# cloud-watch-region = us-east-1
session-manager-working-path = /var/lib/dcvsmbroker
EOF
		sudo systemctl enable --now dcv-session-manager-broker
	else
		echo "Failed to download the broker installer. Aborting..."
		exit 4
	fi
}

setupSessionManagerGateway()
{
	askThePort "Session Manager Gateway"
	askThePort "Session Resolver"
	askThePort "Web Resources"

	sudo rpm --import https://d1uj6qtbmh3dt5.cloudfront.net/NICE-GPG-KEY
	# wget --no-check-certificate https://d1uj6qtbmh3dt5.cloudfront.net/${DCV_VERSION}/Gateway/nice-dcv-connection-gateway-${DCV_SM_GW_VERSION}.el8.x86_64.rpm
	wget --no-check-certificate https://d1uj6qtbmh3dt5.cloudfront.net/nice-dcv-connection-gateway-el8.x86_64.rpm

    if [[ "$?" -eq "0" ]]
    then
		sudo yum install -y nice-dcv-connection-gateway-el8.x86_64.rpm
	    if [[ "$?" -ne "0" ]]
 	    then
 	       echo "Failed to setup the DCV Connection Gateway. Aborting..."
	        exit 15
	    fi

        cat << EOF | sudo tee $dcv_gateway_config_file
[gateway]
web-listen-endpoints = ["0.0.0.0:$gateway_to_broker_port"]
quic-listen-endpoints = ["0.0.0.0:$gateway_to_broker_port"]
cert-file = "$dcv_gateway_key"
cert-key-file = "$dcv_gateway_cert"

[resolver]
url = "https://localhost:${gateway_resolver_port}"

[web-resources]
url = "https://localhost:${gateway_web_resources}"
EOF
		sudo sed -i "s/^enable-gateway.*=.*/enable-gateway = true/" $dcv_broker_config_file
	    sudo sed -i "s/^#gatewayhttpsport.*/gateway-to-broker-connector-https-port = $gateway_to_broker_port/" $dcv_broker_config_file
	    sudo sed -i "s/^#gatewaybindhost.*/gateway-to-broker-connector-bind-host = 0.0.0.0/" $dcv_broker_config_file
		sudo cp -f /var/lib/dcvsmbroker/security/dcvsmbroker_ca.pem ${HOME}/

		sudo systemctl restart dcv-session-manager-broker
	else
		echo "Failed to download the Gateway installer. Aborting..."
		exit 7
	fi
}

setupSessionManagerAgent()
{
    # wget --no-check-certificate https://d1uj6qtbmh3dt5.cloudfront.net/${DCV_VERSION}/SessionManagerAgents/nice-dcv-session-manager-agent-${DCV_SM_AGENT_VERSION}.el8.x86_64.rpm
    wget --no-check-certificate https://d1uj6qtbmh3dt5.cloudfront.net/nice-dcv-session-manager-agent-el8.x86_64.rpm
    if [[ "$?" -eq "0" ]]
    then
	sudo yum install -y https://d1uj6qtbmh3dt5.cloudfront.net/nice-dcv-session-manager-agent-el8.x86_64.rpm
	if [[ "$?" -ne "0" ]]
    	then
            echo "Failed to setup the Session Manager Agent. Aborting..."
            exit 16
    	fi
	sudo cp dcvsmbroker_ca.pem /etc/dcv-session-manager-agent/
	
	cat << EOF | sudo tee /etc/dcv-session-manager-agent/agent.conf
version = '0.1'
[agent]

# hostname or IP of the broker. This parameter is mandatory.
# broker_host = 'localhost'

# The port of the broker. Default: 8445
broker_port = $agent_to_broker_port
broker_host = "$broker_hostname"         # it could be the case that you need to remove the previous broker_host config to active this one

# CA used to validate the certificate of the broker.
# ca_file = 'ca-cert.pem'
ca_file = '/etc/dcv-session-manager-agent/dcvsmbroker_ca.pem'

# Set to false to accept invalid certificates. True by default.
tls_strict = false

# Folder on the file system from which the tag files are read.
# Default: '/etc/dcv-session-manager-agent/tags/' on Linux and
# '<INSTALLATION_DIR>/conf/tags/' on Windows.
#tags_folder =

# Folder on the file system which contains scripts allowed to
# customize the initialization of desktop environment used by
# DCV for Linux Virtual sessions.
# Default: '/var/lib/dcv-session-manager-agent/init/'
#init_folder =

# Folder on the file system which contains scripts and apps
# allowed to be automatically executed at session startup.
# Default: '/var/lib/dcv-session-manager-agent/autorun/' on Linux and
# 'C:\ProgramData\NICE\DCVSessionManagerAgent\autorun' on Windows.
#autorun_folder =

# DCV server cli root path
# Default: '/usr/bin/dcv' on Linux and
dcv_root = '/usr/bin/dcv'

[log]

# log verbosity. Default: 'info'
#level = 'debug'

# Directory used for the logs.
# Default: '/var/log/dcv-session-manager-agent/' on Linux and
directory = '/var/log/dcv-session-manager-agent/'

# log rotation. Default: daily
#rotation = 'daily'
# tls_strict = false
EOF

		sudo cp /var/lib/dcvsmbroker/security/dcvsmbroker_ca.pem /etc/dcv-session-manager-agent/dcvsmbroker_ca.pem	
		sudo systemctl restart dcv-session-manager-broker
		sudo systemctl enable --now dcv-session-manager-agent
	else
		echo "Failed to download the client installer. Aborting..."
		exit 5
	fi
}

registerFirstApiClient()
{
    echo
    echo -e "${GREEN}#############################################"
    echo -e " Working on the DCV SM CLI configuration ... "
    echo -e "#############################################${NC}"
    echo 
    output=$(sudo dcv-session-manager-broker register-api-client --client-name EF)
    client_id=${output#*client-id: }
    client_id=${client_id%% client-password:*}
    client_pass=${output#*client-password: }
    dcv_sm_cli_conf_file=$(find $HOME -iname dcvsmcli.conf)
    client_id=${client_id//$'\n'/}
    client_pass=${client_pass//$'\n'/}
    sed -i "s/^itwillbechangedtoclientid.*/client-id = $client_id/" $dcv_sm_cli_conf_file
    sed -i "s/^itwillbechangedtoclientpass.*/client-password = $client_pass/" $dcv_sm_cli_conf_file
}

setupSessionManagerCli()
{
    cd
    # https://d1uj6qtbmh3dt5.cloudfront.net/2023.1/SessionManagerCLI/nice-dcv-session-manager-cli-1.1.0-140.zip
    # wget --no-check-certificate https://d1uj6qtbmh3dt5.cloudfront.net/${DCV_VERSION}/SessionManagerCLI/nice-dcv-session-manager-cli-${DCV_SM_CLI_VERSION}.zip
    wget --no-check-certificate https://d1uj6qtbmh3dt5.cloudfront.net/nice-dcv-session-manager-cli.zip
    if [[ "$?" -eq "0" ]]
    then
		unzip nice-dcv-session-manager-cli.zip
		cd nice-dcv-session-manager-cli-*/
		sed -ie 's~/usr/bin/env python$~/usr/bin/env python3~' dcvsm   # replace the python with the python3 binary
		dcv_sm_cli_conf_file=$(find $HOME -iname dcvsmcli.conf)
		cat << EOF | sudo tee $dcv_sm_cli_conf_file
[output]
# The formatting style for command output.
# output-format = json

# Turn on debug logging
# debug = true

[security]
# Disable SSL certificates verification.
no-verify-ssl = true

# CA certificate bundle to use when verifying SSL certificates.
# ca-bundle = ca-bundle.pem

[authentication]
# hostname of the authentication server used to request the token
auth-server-url = https://${broker_hostname}:${client_to_broker_port}/oauth2/token?grant_type=client_credentials

# The client ID
itwillbechangedtoclientid

# The client password
itwillbechangedtoclientpass

[broker]
# hostname or IP of the broker. This parameter is mandatory.
url = https://${dcv_cli_hostname}:${client_to_broker_port}
EOF
	else
		echo "Failed to download the CLI installer. Aborting..."
		exit 6
	fi
}

configureFirewallD()
{
	sudo yum -y install firewalld
	sudo iptables-save

	# nice dcv server port
	if [ -f /etc/systemd/system/multi-user.target.wants/dcvserver.service ]
	then
		sudo firewall-cmd --zone=public --add-port=${dcv_port}/tcp --permanent
	fi

	# agent to broker port
	if [ -f /etc/systemd/system/multi-user.target.wants/dcv-session-manager-agent.service ]
	then
		sudo firewall-cmd --zone=public --add-port=${agent_to_broker_port}/tcp --permanent
	fi

	# client to broker port
	if [ -f /etc/systemd/system/multi-user.target.wants/dcv-session-manager-broker.service ]
	then
		sudo firewall-cmd --zone=public --add-port=${client_to_broker_port}/tcp --permanent
	fi

	# gateway to broker
	if [ -f $dcv_gateway_config_file ]
	then
		sudo firewall-cmd --zone=public --add-port=${gateway_to_broker_port}/tcp --permanent
	fi

	sudo firewall-cmd --reload
	sudo iptables-save 
}

finishTheSetup()
{
	echo -e "${GREEN}###########################################################"
	echo -e          "  The DCV Session Manager setup was finished successful!  "
	echo -e          "###########################################################${NC}"
	echo "You can find more background at https://www.ni-sp.com/support/dcv-session-manager-installation-broker-and-agent/"
	echo "Here are some tips:"
	echo "- In case installed DCV CLI is installed: cd nice-dcv-session-manager-cli-*"
	echo "- Show the DCV CLI help: ./dcvsm -h"
	# echo "- Show the DCV SM servers: ./dcvsm describe-servers "
	echo "- Describe the servers using the DCV CLI: ./dcvsm describe-servers"
	echo "- Create a session using DCV SM CLI: ./dcvsm create-session --name sess1 --owner $USER --type Virtual"
	echo "- Describe all sessions using DCV SM CLI: ./dcvsm describe-sessions"
	echo "- Delete a session using DCV SM CLI: ./dcvsm delete-session --session-id 3715ea87-c0f0-490f-9f4c-8c24cc9a4d82 --owner $USER"
	echo "- To change the CLI config, edit the file: conf/dcvsmcli.conf"
	echo "- Show the registered DCV SM Agents: sudo dcv-session-manager-broker describe-agent-clients"
	echo "- Register a DCV SM client: dcv-session-manager-broker register-api-client --client-name EF"
	echo # "-------------------"
	echo -e "${GREEN}Thank you very much for using the DCV Session Manager!${NC}"
	echo 
	echo -e "If you like we can now reboot the server. Enter ${ORANGE}yes${NC} to reboot or ctrl+c to exit."
	read p
	if [ "$p" == "yes" ] ; then
	    sudo reboot
	fi
}

announceHowTheScriptWorks()
{
    echo -e "${GREEN}#####################################################################"
    echo -e          "  Welcome to the NICE DCV Session Manager Installation Script"
    echo -e 
    echo -e "  The script will install and setup DCV without GPU, DCV Session" 
    echo -e         "  Manager Broker, Agent, Gateway and CLI based on your selection."
    echo 
    echo -e         "  NI SP GmbH / info@ni-sp.com / www.ni-sp.com " 
    echo -e         "#####################################################################${NC}"
    echo
    echo -e "${GREEN}->${NC} In the next step we will offer an optional NICE DCV installation and configuration (without GPU support). If you decide to install NICE DCV, at the end we will ask if you want to continue with the DCV Session Manager installation (Broker, Agent, GW and CLI). We added this additional step in case you need to just install NICE DCV."
    echo
    echo -e "${GREEN}->${NC} The script will also ask other information - e.g. the port to run the Session Manager Broker, the Session Manager Agent, the Gateway ports, NICE DCV. We will avoid to use ports already in use in your system."
    echo
    echo "Press enter to continue the setup or ctrl+c to cancel."
    read p
}