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
