
checkLinuxDistro()
{
    echo "If you know what you are doing, please use --force option to avoid our Linux Distro compatibility test."
    if [ -f /etc/centos-release ]
    then
        centos_distro="true"
        if cat /etc/centos-release | egrep -iq "(7|8|9)"
        then
            if cat /etc/centos-release | egrep -iq "7"
            then
                centos_version=7
            else
                if cat /etc/centos-release | egrep -iq "8"
                then
                    centos_version=8
                else
                    if cat /etc/centos-release | egrep -iq "9"
                    then
                        centos_version=9
                    else
                        echo "Your RedHat Based Linux distro version..."
                        cat /etc/centos-release
                        echo "is not supported. Aborting..."
                        exit 18
                    fi
                fi
            fi
        else
            echo "Your RedHat Based Linux distro..."
            cat /etc/centos-release
            echo "is not supported. Aborting..."
            exit 19
        fi
    else
        if [ -f /etc/debian_version ]
        then
            if cat /etc/issue | egrep -iq "ubuntu"
            then
                ubuntu_distro="true"
                ubuntu_version=$(lsb_release -rs)
                ubuntu_major_version=$(echo $ubuntu_version | cut -d '.' -f 1)
                ubuntu_minor_version=$(echo $ubuntu_version | cut -d '.' -f 2)
                if ( [[ $ubuntu_major_version -lt 18 ]] || [[ $ubuntu_major_version -gt 24  ]] ) && [[ $ubuntu_minor_version -ne 04 ]]
                then
                    echo "Your Ubuntu version >>> $ubuntu_version <<< is not supported. Aborting..."
                    exit 20
                fi
            else
                echo "Your Debian Based Linxu distro is not supported."
                echo "Aborting..."
                exit 21
            fi
        else
            echo "Not able to find which distro you are using."
            echo "Aborting..."
            exit 22
        fi
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

askAllQuestions()
{
    askAboutServiceSetup "dcv"
    askAboutServiceSetup "broker"
    askAboutServiceSetup "agent"
    askAboutServiceSetup "cli"
    askAboutServiceSetup "gateway"
    askAboutServiceSetup "firewall"
}

askAboutServiceSetup()
{
	service_name=$1
    if echo $service_name | egrep -iq "dcv"
    then
        askAboutNiceDcvSetup
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

askAboutNiceDcvSetup()
{
    echo 
    echo -e "Do you want to install ${GREEN}Nice DCV (with or without gpu support)${NC}?"
	readTheServiceSetupAnswer
    if echo $service_setup_answer | egrep -iq "yes"
    then
        dcv_will_be_installed="true"
        echo -e "Do you want to install ${GREEN}Nice DCV with GPU Support?${NC}?"
	    readTheServiceSetupAnswer
        if echo $service_setup_answer | egrep -iq "yes"
        then
            dcv_gpu_support="true"
            echo -e "Do you want to install ${GREEN}Nice DCV with Nvidia Support?${NC}?"
	        readTheServiceSetupAnswer
            if echo $service_setup_answer | egrep -iq "yes"
            then
                dcv_gpu_type="nvidia"
            else
                echo -e "Do you want to install ${GREEN}Nice DCV with AMD/RadeonD Support?${NC}?"
                if echo $service_setup_answer | egrep -iq "yes"
                then
                    dcv_gpu_type="amd"
                else
                    echo -e "You did not select a NVIDIA or AMD/Radeon support. This setup can not continue. Aborting..."
                    exit 24
                fi
            fi
        else
            dcv_gpu_support="false"
        fi
    else
        dcv_will_be_installed="false"
    fi

	askThePort "Nice DCV"
}

installNiceDcvSetup()
{
    # if dcv server will be installed
    if [[ "$dcv_will_be_installed" == "true" ]]
    then
        # if dcv server will have gpu support
        if [[ "$dcv_gpu_support" == "true" ]]
        then
            # if dcv server driver support will be nvidia
            if [[ "$dcv_gpu_type" == "nvidia" ]]
            then
                if [[ "$centos_distro" == "true" ]]
                then
                    centosSetupNiceDcvWithGpuNvidia
                else
                    if [[ "$ubuntu_distro" == "true" ]]
                    then
                        ubuntuSetupNiceDcvWithGpuNvidia
                    fi
                fi
            # if the dcv driver support will be amd
            else
                # if dcv server driver support will be amd
                if [[ "$dcv_gpu_type" == "amd" ]]
                then
                    if [[ "$centos_distro" == "true" ]]
                    then
                        centosSetupNiceDcvWithGpuAmd
                    else
                        if [[ "$ubuntu_distro" == "true" ]]
                        then
                           ubuntuSetupNiceDcvWithGpuAmd
                        fi
                    fi
                fi
            fi           
        # if dcv server will not have gpu support
        else
            if [[ "$centos_distro" == "true" ]]
            then
                centosSetupNiceDcvWithoutGpu
            else
                if [[ "$ubuntu_distro" == "true" ]]
                then
                    ubuntuSetupNiceDcvWithoutGpu
                fi
            fi
        fi

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

ubuntuImportKey()
{
    wget https://d1uj6qtbmh3dt5.cloudfront.net/NICE-GPG-KEY
    sudo gpg --import NICE-GPG-KEY
    rm -f NICE-GPG-KEY
}

ubuntuSetupRequiredPackages()
{
    sudo apt update
    export DEBIAN_FRONTEND=noninteractive

    case "${ubuntu_version}" in
        "18.04")
            sudo apt install tasksel
            sudo tasksel install ubuntu-desktop
            ;;
        "20.04")
            sudo apt install ubuntu-desktop
            sudo apt install gdm3
            sudo apt upgrade
            ;;
        "22.04")
            sudo apt install ubuntu-desktop
            sudo apt install gdm3
            sudo apt upgrade
            ;;
    esac

    if [ -f /etc/gdm3/custom.conf ]
    then

        gdm3_file="/etc/gdm3/custom.conf"
        if [ -f $gdm3_file ]
        then
            target_line="WaylandEnable=false"

            sudo cp "$gdm3_file" "${gdm3_file}.bak"

            sudo awk -v target="$TARGET_LINE" '
    BEGIN { in_daemon = 0; inserted = 0 }
    /^\[daemon\]/ { in_daemon = 1 }
    in_daemon && /^$/ { in_daemon = 0 }
    in_daemon && /WaylandEnable/ { $0 = target; inserted = 1 }
    { print }
    END {
        if (in_daemon && !inserted) {
            print target
        }
    }
' "$gdm3_file" > "$gdm3_file.tmp"
        fi
        sudo mv "${gdm3_file}.tmp" "$gdm3_file"
    fi

    sudo systemctl restart gdm3
    sudo systemctl get-default
    sudo systemctl set-default graphical.target
    sudo systemctl isolate graphical.target
}

ubuntuSetupNiceDcvWithGpuPrepareBase()
{
    sudo apt install -y mesa-utils
    sudo apt-get install -y gcc make linux-headers-$(uname -r)

    if ! cat /etc/modprobe.d/blacklist.conf | egrep -iq "blacklist nouveau"
    then  
        cat << EOF | sudo tee --append /etc/modprobe.d/blacklist.conf
blacklist vga16fb
blacklist nouveau
blacklist rivafb
blacklist nvidiafb
blacklist rivatv
EOF
    fi

    if ! cat /etc/modprobe.d/blacklist.conf | egrep -iq "blacklist nouveau"
    then  
        echo 'GRUB_CMDLINE_LINUX="rdblacklist=nouveau"' | sudo tee -a /etc/default/grub > /dev/null
        sudo update-grub
    fi
}

ubuntuSetupNvidiaDriver()
{
    wget --no-check-certificate $url_nvidia_tesla_driver
    sudo /bin/sh ./NVIDIA-Linux-x86_64*.run -s
    sudo nvidia-xconfig --preserve-busid --enable-all-gpus
    rm -f ./NVIDIA-Linux-x86_64*.run -s
}

ubuntuSetupAmdDriver()
{
    sudo apt -y install gcc make awscli bc sharutils
    sudo apt -y install linux-modules-extra-$(uname -r) linux-firmware
    if [ $ubuntu_major_version -eq 22 ]
    then
        sudo apt -y install libdrm-common libdrm-amdgpu1 libdrm2 libdrm-dev libdrm2-amdgpu pkg-config libncurses-dev libpciaccess0 libpciaccess-dev libxcb1 libxcb1-dev libxcb-dri3-0 libxcb-dri3-dev libxcb-dri2-0 libxcb-dri2-0-dev gettext
        cat << EOF | sudo tee --append /etc/X11/xorg.conf.d/20-amdgpu.conf
Section "Device"
    Identifier "AMD"
    Driver "amdgpu"
EndSection
EOF
        cat << EOF | sudo tee --append /etc/modprobe.d/20-amdgpu.conf
options amdgpu virtual_display=0000:00:1e.0,2
EOF
        wget --no-check-certificate $url_amd_ubuntu_driver
        sudo apt -y install ./amdgpu-install*
        sudo apt -y install amdgpu-dkms
        sudo amdgpu-install -y --opencl=legacy,rocr --vulkan=amdvlk,pro --usecase=graphics --accept-eula
    fi

    if [ $ubuntu_major_version -eq 20 ]
    then
        sudo apt -y install libdrm-common libdrm-amdgpu1 libdrm2 libdrm-dev libdrm2-amdgpu pkg-config libncurses-dev libpciaccess0 libpciaccess-dev libxcb1 libxcb1-dev libxcb-dri3-0 libxcb-dri3-dev libxcb-dri2-0 libxcb-dri2-0-dev gettext
        cat <<EOF> /usr/share/X11/xorg.conf.d/20-amdgpu.conf
Section "Device"
    Identifier "AMD"
    Driver "amdgpu"
EndSection
EOF
        cat <<EOF> /etc/modprobe.d/20-amdgpu.conf
options amdgpu virtual_display=0000:00:1e.0,2
EOF
        wget --no-check-certificate $url_amd_ubuntu_driver
        sudo apt -y install ./amdgpu-install*
        sudo apt -y install amdgpu-dkms
        sudo amdgpu-install -y --opencl=legacy,rocr --vulkan=amdvlk,pro --usecase=graphics --accept-eula

    fi

    if [ $ubuntu_major_version -eq 18 ]
    then
        #TODO
    fi

    if [ -f /etc/X11/xorg.conf ]
    then
        rm -f /etc/X11/xorg.conf
    fi

    compileAndSetupRadeonTop
}

compileAndSetupRadeonTop()
{
    git clone https://github.com/clbr/radeontop.git
    cd radeontop
    sudo make
    sudo make install
    cd ..
    sudo rm -rf radeontop
}

ubuntuSetupNiceDcvServer()
{
    case "${ubuntu_version}" in
        "18.04")
            dcv_server="https://d1uj6qtbmh3dt5.cloudfront.net/2021.3/Servers/nice-dcv-2021.3-11591-ubuntu1804-x86_64.tgz"
            ;;
        "20.04")
            dcv_server=$(curl --silent --output - https://download.nice-dcv.com/ | grep href | egrep "$dcv_version" | grep "ubuntu${ubuntu_major_version}${ubuntu_minor_version}" | grep Server | sed -e 's/.*http/http/' -e 's/tgz.*/tgz/' | head -1)
            ;;
        "22.04")
            dcv_server=$(curl --silent --output - https://download.nice-dcv.com/ | grep href | egrep "$dcv_version" | grep "ubuntu${ubuntu_major_version}${ubuntu_minor_version}" | grep Server | sed -e 's/.*http/http/' -e 's/tgz.*/tgz/' | head -1)
            ;;
    esac

    wget --no-check-certificate $dcv_server
    if [[ "$?" -eq "0" ]]
    then
        echo "Failed to download the right dcv server tarball to setup the service. Aborting..."
        exit 23
    fi 
    tar zxvf nice-dcv-*ubun*.tgz
    rm -f nice-dcv-*.tgz
    cd nice-dcv-*64

    sudo apt -y install ./nice-dcv-server*
    sudo apt -y install ./nice-dcv-web-viewer*
    sudo usermod -aG video dcv
    sudo apt -y install ./nice-xdcv*
    sudo apt -y install ./nice-dcv-gl*
    sudo apt -y install ./nice-dcv-simple-external-authenticato*
    sudo apt -y install dkms
    sudo dcvusbdriverinstaller --quiet
    sudo apt -y install pulseaudio-utils

    rm -rf nice-dcv-*64
    createDcvSsl

    sudo sed -ie 's/#owner = ""/owner = "ubuntu"/' /etc/dcv/dcv.conf
    sudo sed -ie 's/#create-session = true/create-session = true/' /etc/dcv/dcv.conf
    sudo sed -ie 's/"1"/"0"/g' /etc/apt/apt.conf.d/20auto-upgrades
    sudo systemctl isolate multi-user.target
    sudo dcvgladmin enable
    sudo systemctl isolate graphical.target

    sudo systemctl enable --now dcvserver
}

ubuntuSetupNiceDcvWithGpuNvidia()
{
    if [[ $dcv_will_be_installed == "false" ]]
    then
        return 0
    else
        if [[ $dcv_gpu_support == "false" ]]
        then
            return 0
        else
            if [[ $dcv_gpu_type != "nvidia" ]]
            then
                return 0
            else
                if [[ $ubuntu_distro == "false" ]]
                then
                    return 0
                fi
            fi
        fi
    fi

    ubuntuSetupNiceDcvWithGpuPrepareBase
    ubuntuSetupNvidiaDriver
    ubuntuSetupNiceDcvServer
}

ubuntuSetupNiceDcvWithGpuAmd()
{
    if [[ $dcv_will_be_installed == "false" ]]
    then
        return 0
    else
        if [[ $dcv_gpu_support == "false" ]]
        then
            return 0
        else
            if [[ $dcv_gpu_type != "amd" ]]
            then
                return 0
            else
                if [[ $ubuntu_distro == "false" ]]
                then
                    return 0
                fi
            fi
        fi
    fi

    ubuntuSetupNiceDcvWithGpuPrepareBase
    ubuntuSetupAmdDriver
    ubuntuSetupNiceDcvServer
}

ubuntuSetupNiceDcvWithoutGpu()
{
    if [[ $dcv_will_be_installed == "false" ]]
    then
        return 0
    else
        if [[ $dcv_gpu_support == "true" ]]
        then
            return 0
        else
            if [[ $ubuntu_distro == "false" ]]
            then
                return 0
            fi
        fi
    fi

    sudo systemctl get-default
    sudo systemctl set-default graphical.target
    sudo systemctl isolate graphical.target
}

ubuntuSetupSessionManagerBroker()
{
    if [[ $nice_dcv_broker_install_answer != "yes" ]]
    then
        return 0
   fi

    genericSetupSessionManagerBroker

    case "${ubuntu_version}" in
        "18.04")
            dcv_broker="https://d1uj6qtbmh3dt5.cloudfront.net/2021.3/SessionManagerBrokers/nice-dcv-session-manager-broker_2021.3.307-1_all.ubuntu1804.deb"
            ;;
        "20.04")
            dcv_broker=$(curl --silent --output - https://download.nice-dcv.com/ | grep href | egrep "$dcv_version" | grep "ubuntu${ubuntu_major_version}${ubuntu_minor_version}" | grep Broker i | sed -e 's/.*http/http/' -e 's/deb.*/deb/' | head -1)
            ;;
        "22.04")
            dcv_broker=$(curl --silent --output - https://download.nice-dcv.com/ | grep href | egrep "$dcv_version" | grep "ubuntu${ubuntu_major_version}${ubuntu_minor_version}" | grep Broker | sed -e 's/.*http/http/' -e 's/deb.*/deb/' | head -1)
            ;;
    esac

    wget --no-check-certificate $dcv_broker
    sudo apt install -y ./nice-dcv-session-manager-broker*ubuntu*.deb
    rm -f nice-dcv-session-manager-broker*ubuntu*.deb
}

ubuntuSetupSessionManagerAgent()
{
    if [[ $nice_dcv_agent_install_answer != "yes" ]]
    then
        return 0
    fi
    case "${ubuntu_version}" in
        "18.04")
            dcv_agent="https://d1uj6qtbmh3dt5.cloudfront.net/2021.3/SessionManagerAgents/nice-dcv-session-manager-agent_2021.3.453-1_amd64.ubuntu1804.deb"
            ;;
        "20.04")
            dcv_agent=$(curl --silent --output - https://download.nice-dcv.com/ | grep href | egrep "$dcv_version" | grep "ubuntu${ubuntu_major_version}${ubuntu_minor_version}" | grep agent | sed -e 's/.*http/http/' -e 's/deb.*/deb/' | head -1)
            ;;
        "22.04")
            dcv_agent=$(curl --silent --output - https://download.nice-dcv.com/ | grep href | egrep "$dcv_version" | grep "ubuntu${ubuntu_major_version}${ubuntu_minor_version}" | grep agent | sed -e 's/.*http/http/' -e 's/deb.*/deb/' | head -1)
            ;;
    esac

    wget --no-check-certificate $dcv_agent
    sudo apt install -y ./nice-dcv-session-manager-agent*.deb
    rm -f ./nice-dcv-session-manager-agent*.deb

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
}

ubuntuSetupSessionManagerGateway()
{
    if [[ $nice_dcv_gateway_install_answer != "yes" ]]
    then
        return 0
    fi

    genericSetupSessionManagerGateway

    case "${ubuntu_version}" in

        "18.04")
            dcv_gateway="https://d1uj6qtbmh3dt5.cloudfront.net/2021.3/Gateway/nice-dcv-connection-gateway_2021.3.251-1_amd64.ubuntu1804.deb"
            ;;
        "20.04")
            dcv_gateway=$(curl --silent --output - https://download.nice-dcv.com/ | grep href | egrep "$dcv_version" | grep "ubuntu${ubuntu_major_version}${ubuntu_minor_version}" | grep Gateway | sed -e 's/.*http/http/' -e 's/deb.*/deb/' | head -1)
            ;;
        "22.04")
            dcv_gateway=$(curl --silent --output - https://download.nice-dcv.com/ | grep href | egrep "$dcv_version" | grep "ubuntu${ubuntu_major_version}${ubuntu_minor_version}" | grep Gateway | sed -e 's/.*http/http/' -e 's/deb.*/deb/' | head -1)
            ;;
    esac

    wget --no-check-certificate $dcv_gateway
    sudo apt install -y ./nice-dcv-connection-gateway*.deb
    rm -f ./nice-dcv-connection-gateway*.deb

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
}

ubuntuConfigureFirewall()
{
    if [[ $nice_dcv_firewall_install_answer != "yes" ]]
    then
        return 0
    fi
    sudo apt -y install firewalld

    setFirewalldRules
	sudo iptables-save 
}

centosSetupNiceDcvWithGpuPrepareBase()
{
    # upgrade
    sudo yum upgrade -y

    # setup server GUI
    sudo yum groupinstall 'Server with GUI' -y
    sudo systemctl get-default
    sudo systemctl set-default graphical.target
    sudo systemctl isolate graphical.target
    sudo yum install glx-utils -y

    # prepare to setup nvidia driver
    sudo yum erase nvidia cuda
    sudo yum install -y make gcc kernel-devel-$(uname -r) wget
    cat << EOF | sudo tee --append /etc/modprobe.d/blacklist.conf
blacklist vga16fb
blacklist nouveau
blacklist rivafb
blacklist nvidiafb
blacklist rivatv
EOF
    echo 'GRUB_CMDLINE_LINUX="rdblacklist=nouveau"' | sudo tee -a /etc/default/grub > /dev/null
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg
    sudo rmmod nouveau
}

centosSetupNvidiaDriver()
{
    wget --no-check-certificate $url_nvidia_tesla_driver
    sudo /bin/sh ./NVIDIA-Linux-x86_64*.run -s
    sudo nvidia-xconfig --preserve-busid --enable-all-gpus
    rm -f ./NVIDIA-Linux-x86_64*.run -s
}

centosSetupAmdDriver()
{
    #TODO
}

adaptColord()
{
    cat << EOF | sudo tee --append /etc/polkit-1/localauthority/50-local.d/45-allow-colord.pkla
[Allow Colord all Users]
Identity=unix-user:*
Action=org.freedesktop.color-manager.create-device;org.freedesktop.color-manager.create-profile;org.freedesktop.color-manager.delete-device;org.freedesktop.color-manager.delete-profile;org.freedesktop.color-manager.modify-device;org.freedesktop.color-manager.modify-profile
ResultAny=no
ResultInactive=no
ResultActive=yes
EOF
}

createDcvSsl()
{
    sudo openssl req -x509 -newkey rsa:4096 -keyout /etc/dcv/key.pem -out /etc/dcv/cert.pem -days 365
    sudo echo 'ca-file="/etc/dcv/cert.pem"  ' >> /etc/dcv/dcv.conf
}

centos7SpecificSettings()
{
    return 0
}

centos8SpecificSettings()
{
    adaptColord
}

centos9SpecificSettings()
{
    adaptColord
}

centosSetupNiceDcvServer()
{
	dcv_server=$(curl -k --silent --output - https://download.nice-dcv.com/ | grep href | egrep "$dcv_version" | grep "el${centos_version}" | grep Server | sed -e 's/.*http/http/' -e 's/tgz.*/tgz/' | head -1)

    if ! echo "$dcv_server" | egrep -iq "^https.*.tgz"
    then
        echo "Failed to get the right dcv server tarball file to dowload and install. Aborting..."
        exit 22
    fi
	wget --no-check-certificate $dcv_server
	if [[ "$?" -eq "0" ]]
	then
		cd
		tar zxvf nice-dcv-*el${centos_version}*.tgz
		rm -f nice-dcv-*el${centos_version}*.tgz
		cd nice-dcv-*x86_64

		sudo yum -y install nice-dcv-server-*.el${centos_version}.x86_64.rpm nice-xdcv-*.el${centos_version}.x86_64.rpm nice-dcv-web-viewer*.el${centos_version}.x86_64.rpm nice-dcv-gltest-*.el${centos_version}.x86_64.rpm nice-dcv-simple-external-authenticator-*.el${centos_version}.x86_64.rpm
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
        createDcvSsl
		sudo systemctl enable --now dcvserver
	else
		echo "Failed to download the file >>> $dcv_server <<<. Aborting..."
		exit 1
	fi

    rm -rf nice-dcv-*x86_64

    if [[ "$centos_version" == "7" ]]
    then
        centos7SpecificSettings
    else
        if [[ "$centos_version" == "8" ]]
        then
            centos8SpecificSettings
        else
            if [[ "$centos_version" == "9" ]]
            then
                centos9SpecificSettings
            fi
        fi
    fi

	echo "Nice DCV service was installed. Please press enter to continue the installing process or ctrl+c to stop here."
	read p
}

centosSetupNiceDcvWithGpuNvidia()
{
    if [[ $dcv_will_be_installed == "false" ]]
    then
        return 0
    else
        if [[ $dcv_gpu_support == "false" ]]
        then
            return 0
        else
            if [[ $dcv_gpu_type != "nvidia" ]]
            then
                return 0
            else
                if [[ $centos_distro == "false" ]]
                then
                    return 0
                fi
            fi
        fi
    fi

    centosSetupNiceDcvWithGpuPrepareBase
    centosSetupNvidiaDriver
    centosSetupNiceDcvServer
}

centosSetupNiceDcvWithGpuAmd()
{
    if [[ $dcv_will_be_installed == "false" ]]
    then
        return 0
    else
        if [[ $dcv_gpu_support == "false" ]]
        then
            return 0
        else
            if [[ $dcv_gpu_type != "amd" ]]
            then
                return 0
            else
                if [[ $centos_distro == "false" ]]
                then
                    return 0
                fi
            fi
        fi
    fi

    centosSetupNiceDcvWithGpuPrepareBase
    centosSetupAmdDriver
    centosSetupNiceDcvServer
}

centosSetupNiceDcvWithoutGpu()
{
    if [[ $dcv_will_be_installed == "false" ]]
    then
        return 0
    else
        if [[ $dcv_gpu_support == "true" ]]
        then
            return 0
        else
            if [[ $centos_distro == "false" ]]
            then
                return 0
            fi
        fi
    fi
	
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
    centosSetupNiceDcvServer
}

centosImportKey()
{
    sudo rpm --import https://d1uj6qtbmh3dt5.cloudfront.net/NICE-GPG-KEY
}

centosSetupRequiredPackages()
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

genericSetupSessionManagerBroker()
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
}

centosSetupSessionManagerBroker()
{
    if [[ $nice_dcv_broker_install_answer != "yes" ]]
    then
        return 0
    fi

    genericSetupSessionManagerBroker

    dcv_broker=$(curl -k --silent --output - https://download.nice-dcv.com/ | grep href | egrep "$dcv_version" | grep "el${centos_version}" | grep broker | sed -e 's/.*http/http/' -e 's/rpm.*/rpm/' | head -1)
	wget --no-check-certificate $dcv_broker
	
    if [[ "$?" -eq "0" ]]
    then
		sudo yum install -y nice-dcv-session-manager-broker-*.noarch.rpm
        rm -f nice-dcv-session-manager-broker*.rpm
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

genericSetupSessionManagerGateway()
{
	askThePort "Session Manager Gateway"
	askThePort "Session Resolver"
	askThePort "Web Resources"
}

centosSetupSessionManagerGateway()
{
    if [[ $nice_dcv_gateway_install_answer != "yes" ]]
    then
        return 0
    fi

    genericSetupSessionManagerGateway

	dcv_gateway=$(curl -k --silent --output - https://download.nice-dcv.com/ | grep href | egrep "$dcv_version" | grep "el${centos_version}" | grep gateway | sed -e 's/.*http/http/' -e 's/rpm.*/rpm/' | head -1)

	wget --no-check-certificate $dcv_gateway

    if [[ "$?" -eq "0" ]]
    then
		sudo yum install -y nice-dcv-connection-gateway*.rpm
        rm -f nice-dcv-connection-gateway*.rpm
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

centosSetupSessionManagerAgent()
{
    if [[ $nice_dcv_agent_install_answer != "yes" ]]
    then
        return 0
    fi

    dcv_agent=$(curl -k --silent --output - https://download.nice-dcv.com/ | grep href | egrep "$dcv_version" | grep "el${centos_version}" | grep agent | sed -e 's/.*http/http/' -e 's/rpm.*/rpm/' | head -1)
    wget --no-check-certificate $dcv_agent

    if [[ "$?" -eq "0" ]]
    then
	sudo yum install -y nice-dcv-session-manager-agent*.rpm
    rm -f nice-dcv-session-manager-agent*.rpm

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
    wget --no-check-certificate https://d1uj6qtbmh3dt5.cloudfront.net/nice-dcv-session-manager-cli.zip
    if [[ "$?" -eq "0" ]]
    then
		unzip nice-dcv-session-manager-cli.zip
        rm -f nice-dcv-session-manager-cli.zip
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

setFirewalldRules()
{
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

centosConfigureFirewall()
{
    if [[ $nice_dcv_firewall_install_answer != "yes" ]]
    then
        return 0
    fi
	sudo yum -y install firewalld
	sudo iptables-save

    setFirewalldRules
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
