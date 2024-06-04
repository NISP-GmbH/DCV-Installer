main()
{
	checkLinuxDistro
	announceHowTheScriptWorks
    askAllQuestions

    if [[ "{$ubuntu_version}x" == "x" ]]
    then
        if [[ "{$centos_version}x" == "x" ]]
        then
            echo "Is not possible to setup any package. Aborting..."
            exit 7
        else
            centosImportKey
            centosSetupRequiredPackages
		    centosSetupNiceDcvWithoutGpu
		    centosSetupSessionManagerBroker
            centosSetupSessionManagerAgent
            centosSetupSessionManagerGateway
            centosConfigureFirewall
        fi
    else
        ubuntuImportKey
        ubuntuSetupRequiredPackages
        ubuntuSetupNiceDcvWithoutGpu
        ubuntuSetupSessionManagerBroker
        ubuntuSetupSessionManagerAgent
        ubuntuSetupSessionManagerGateway
        ubuntuConfigureFirewall
    fi

	# dcv session manager cli setup
	if [[ $nice_dcv_cli_install_answer == "yes" ]]
	then
		setupSessionManagerCli
		registerFirstApiClient
	fi

	# finish the setup
	finishTheSetup
	exit 0
}

main
