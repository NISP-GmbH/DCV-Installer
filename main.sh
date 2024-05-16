# global vars
RED='\033[0;31m'; GREEN='\033[0;32m'; GREY='\033[0;37m'; BLUE='\034[0;37m'; NC='\033[0m'
ORANGE='\033[0;33m'; BLUE='\033[0;34m'; WHITE='\033[0;97m'; UNLIN='\033[0;4m'
service_setup_answer="no"
nice_dcv_server_install_answer="no"
nice_dcv_broker_install_answer="no"
nice_dcv_agent_install_answer="no"
nice_dcv_gateway_install_answer="no"
nice_dcv_firewall_install_answer="no"
nice_dcv_cli_install_answer="no"
broker_url=""
broker_ip=""
broker_hostname="localhost"
client_to_broker_port="8448"
agent_to_broker_port="8445"
gateway_to_broker_port="8447"
gateway_resolver_port="9000"
gateway_web_resources="9001"
dcv_port="8443"
port_used=1
dcv_will_be_installed=0
dcv_cli_hostname="localhost"
dcv_broker_config_file="/etc/dcv-session-manager-broker/session-manager-broker.properties"
dcv_gateway_config_file="/etc/dcv-connection-gateway/dcv-connection-gateway.conf"
dcv_gateway_cert_gen="/usr/share/dcv-session-manager-broker/bin/gen-gateway-certificates.sh"
dcv_gateway_pass="/etc/dcv-session-manager-broker/gateway-creds/pass"
dcv_gateway_cert_dir="/etc/dcv-session-manager-broker/gateway-creds/"
dcv_gateway_key="/etc/dcv-session-manager-broker/gateway-creds/dcv_gateway_key.pem"
dcv_gateway_cert="/etc/dcv-session-manager-broker/gateway-creds/dcv_gateway_cert.pem"

main()
{
	checkCentosVersion
	announceHowTheScriptWorks
	# disableIpv6
	setupRequiredPackages

	# dcv server setup
	askAboutServiceSetup "dcv"
	if [[ $nice_dcv_server_install_answer == "yes" ]]
	then
		dcv_will_be_installed=1
		setupNiceDcvWithoutGpu
	fi

	# dcv session manager broker setup
	askAboutServiceSetup "broker"
	if [[ $nice_dcv_broker_install_answer == "yes" ]]
	then
		setupSessionManagerBroker
	fi

	# dcv session manager agent setup
	askAboutServiceSetup "agent"
	if [[ $nice_dcv_agent_install_answer == "yes" ]]
	then
		setupSessionManagerAgent
	fi

	# dcv session manager cli setup
	askAboutServiceSetup "cli"
	if [[ $nice_dcv_cli_install_answer == "yes" ]]
	then
		setupSessionManagerCli
		registerFirstApiClient
	fi

	# dcv connection gateway setup
	askAboutServiceSetup "gateway"
	if [[ $nice_dcv_gateway_install_answer == "yes" ]]
	then
		setupSessionManagerGateway
	fi

	# firewalld setup and rules
	askAboutServiceSetup "firewall"
	if [[ $nice_dcv_firewall_install_answer == "yes" ]]
	then
		configureFirewallD
	fi

	# enableIpv6
	finishTheSetup
	exit 0
}

main
