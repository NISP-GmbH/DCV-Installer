main()
{
	checkLinuxDistro
	announceHowTheScriptWorks
	# disableIpv6
	centosSetupRequiredPackages

	# dcv server setup
	askAboutServiceSetup "dcv"
	if [[ $nice_dcv_server_install_answer == "yes" ]]
	then
		dcv_will_be_installed=1
		centosSetupNiceDcvWithoutGpu
	fi

	# dcv session manager broker setup
	askAboutServiceSetup "broker"
	if [[ $nice_dcv_broker_install_answer == "yes" ]]
	then
		centosSetupSessionManagerBroker
	fi

	# dcv session manager agent setup
	askAboutServiceSetup "agent"
	if [[ $nice_dcv_agent_install_answer == "yes" ]]
	then
		centosSetupSessionManagerAgent
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
		centosSetupSessionManagerGateway
	fi

	# firewalld setup and rules
	askAboutServiceSetup "firewall"
	if [[ $nice_dcv_firewall_install_answer == "yes" ]]
	then
		centosConfigureFirewallD
	fi

	# finish the setup
	finishTheSetup
	exit 0
}

main
