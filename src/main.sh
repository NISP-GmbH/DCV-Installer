checkParameters $@

main()
{
    temp_dir=$(mktemp -d -t dcv_installer_XXXXXXXXXX)
    original_dir=$(pwd)
    cd "$temp_dir"

	checkLinuxDistro

    if ! $without_interaction_parameter
    then
    	announceHowTheScriptWorks
    fi

    setup_guardian_var="false"
    if [[ "${ubuntu_version}x" != "x" ]]
    then
        ubuntuImportKey
        ubuntuSetupRequiredPackages
        askAboutServiceSetup "dcv"
        installNiceDcvSetup
        askAboutSessionManagerComponents
        ubuntuSetupSessionManagerBroker
        ubuntuSetupSessionManagerAgent
        ubuntuSetupSessionManagerGateway
        ubuntuConfigureFirewall
        setup_guardian_var="true"
    fi

    
    if [[ "${redhat_distro_based_version}x" != "x" ]]
    then
        centosImportKey
        centosSetupRequiredPackages
        askAboutServiceSetup "dcv"
        installNiceDcvSetup
        askAboutSessionManagerComponents
		centosSetupSessionManagerBroker
        centosSetupSessionManagerAgent
        centosSetupSessionManagerGateway
        centosConfigureFirewall
        setup_guardian_var="true"
    fi

    if [[ "${amazon_distro_version}x"  != "x" ]]
    then
        centosImportKey
        centosSetupRequiredPackages
        askAboutServiceSetup "dcv"
        installNiceDcvSetup
        askAboutSessionManagerComponents
		centosSetupSessionManagerBroker
        centosSetupSessionManagerAgent
        centosSetupSessionManagerGateway
        centosConfigureFirewall
        setup_guardian_var="true"
    fi

    if ! $setup_guardian_var
    then
        exit 7
        echo "Is not possible to setup any package because the OS version was not found. Aborting..."
    fi

	# dcv session manager cli setup
	if [[ $nice_dcv_cli_install_answer == "yes" ]]
	then
		setupSessionManagerCli
		registerFirstApiClient
	fi

	# finish the setup
	finishTheSetup

    cd "$original_dir"
	exit 0
}

main
