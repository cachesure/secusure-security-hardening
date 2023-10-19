#!/bin/bash

# Debian PCI Scan
# Gareth Coffey
# Version: 1


MYNETS="192.168.0.0/24"
SCRIPT_LOG_FILE=/var/log/PCI-Scan.log

#########

source './PCI-Functions.sh'

TODAY=`date +%d%m%Y`
OS_NAME=`check_os`

clear
echo "###########################"
echo -e "${COLOR_GREEN}${OS_NAME} - ${BOLD}`hostname`${NORMAL}"
echo "###########################"

WELCOME_MSG="${NO_COLOR} #####################\n
${NO_COLOR}PCI DSS Scan\n
${NO_COLOR}#####################\n
\n
${NO_COLOR}###################################################\n
${NO_COLOR}# 2.2.2 Enable only necessary and secure services #\n
${NO_COLOR}###################################################\n"

logger ${EXCEPTION_LOG} "PCI DSS Scan - `hostname` - `date +'%H:%M %d/%m/%Y'`\n\n"
logger ${EXCEPTION_LOG} "Only FAILED items appear in this log.\n\n"
echo -e ${WELCOME_MSG}

SVC_MSG=""
TMP_SVC_MSG=""

for SVC_INS in proftpd ftp inetd xinetd sendmail portmap samba nfs-user-server nfs-common nfs-kernel-server lpd apache apache2 snmpd bind postgresql mysql webmin squid nis wu-ftpd vsftpd hpoj cupsys exim4 hotplug pop23d sendmail nmbd pcmcia bluez-utilz xfs;
do
        if [[ `check_svc ${SVC_INS}`  == "1" ]];
        then
                SVC_MSG+="\t${COLOR_RED}- ${SVC_INS}\n"
		TMP_SVC_MSG+="\t- ${SVC_INS}\n"
        fi
done

if [[ "${SVC_MSG}" == "" ]];
then
        SVC_MSG="\t${BOLD}Enable only necessary services ${COLOR_GREEN}PASSED.\n"
else
        echo -e "\tThe following services are enabled but should be disabled if possible:\n"
	logger ${EXCEPTION_LOG} "2.2.2 Enable only necessary and secure services\n"
	logger ${EXCEPTION_LOG} "The following services are enabled but should be disabled if possible:\n"
	logger ${EXCEPTION_LOG} "${TMP_SVC_MSG}"
fi

echo -e ${SVC_MSG}

##############

ENV_MSG="${NO_COLOR}################################################################\n
${NO_COLOR}# 2.2.3 Configure system security parameters to prevent misuse #\n
${NO_COLOR}################################################################\n
\n"
logger ${EXCEPTION_LOG} "2.2.3 Configure system security parameters to prevent misuse\n"

echo -e ${ENV_MSG}

#
# Default run level
#
DESKTOP_MSG="\t${BOLD}Disable Desktop GUI ${NORMAL}"

if [[ "`cat /etc/inittab | grep 'id:5:initdefault' | wc -l`" != "0" ]];
then
        DESKTOP_MSG+="${COLOR_RED} FAILED. \n\t\tDisable the desktop GUI by changing the default runlevel in /etc/inittab\n"
	logger ${EXCEPTION_LOG} "2.2.3 - Disable Desktop GUI "
	logger ${EXCEPTION_LOG} "FAILED.\tDisable the desktop GUI by changing the default runlevel in /etc/inittab\n"
else
        DESKTOP_MSG+="${COLOR_GREEN} PASSED.\n"
fi
echo -e ${DESKTOP_MSG}

#
# Check default umask
#
UMASK_MSG="\t${NORMAL}Ensure a default umask of 077 is set\n"
for UM_FILE in profile csh.login csh.cshrc bash.bashrc
do
        UM_FILE=/etc/${UM_FILE}
        if [[ -f ${UM_FILE} ]];
        then
                FILE_UMASK="`cat ${UM_FILE} | grep -i ^umask`"
                UMASK_MSG+="\t\t${BOLD}Checking ${UM_FILE} ${NORMAL}"


                if [[ "${FILE_UMASK}" == "" ]];
                then
                        UMASK_MSG+="${COLOR_RED}FAILED.\t${NORMAL}(Set umask 077)\n"
			logger ${EXCEPTION_LOG} "2.2.3 - Ensure a default umask of 077 is set\n"
			logger ${EXCEPTION_LOG} "\tChecking ${UM_FILE} \n"
			logger ${EXCEPTION_LOG} "FAILED. (umask 077 should be set in ${UM_FILE})\n"
                else
                        if [[ ${FILE_UMASK} != "umask 077" ]];
                        then
                                UMASK_MSG+="${COLOR_RED}FAILED.\t${NORMAL}(Umask is set to ${FILE_UMASK}, recommended setting umask 077)\n"
				logger ${EXCEPTION_LOG} "2.2.3 - Ensure a default umask of 077 is set\n"
				logger ${EXCEPTION_LOG} "\tChecking ${UM_FILE} \n"
				logger ${EXCEPTION_LOG} "FAILED.(Umask is ${FILE_UMASK}, recommended setting umask 077)\n"
                        else
                                UMASK_MSG+="${COLOR_GREEN}PASSED.\n"
                        fi
                fi
        fi
done
echo -e ${UMASK_MSG}

#
# Recommended Kernel configuration
#
echo -e "\t${NORMAL}Recommended Kernel configuration"
logger ${EXCEPTION_LOG} "2.2.3 - Recommended Kernel configuration\n"
check_kernel_param net.ipv4.ip_forward 0
check_kernel_param net.ipv4.tcp_max_syn_backlog 4096
check_kernel_param net.ipv4.tcp_syncookies 1
check_kernel_param net.ipv4.conf.all.rp_filter 1
check_kernel_param net.ipv4.conf.all.accept_source_route 0
check_kernel_param net.ipv4.conf.all.accept_redirects 0
check_kernel_param net.ipv4.conf.all.secure_redirects 0
check_kernel_param net.ipv4.conf.all.send_redirects 0
check_kernel_param net.ipv4.conf.default.rp_filter 1
check_kernel_param net.ipv4.conf.default.send_redirects 0
check_kernel_param net.ipv4.conf.default.accept_source_route 0
check_kernel_param net.ipv4.conf.default.accept_redirects 0
check_kernel_param net.ipv4.conf.default.secure_redirects 0
check_kernel_param net.ipv4.icmp_echo_ignore_broadcasts 1
echo

#
# Core Dumps
#
CORE_DUMPS=`ulimit -c`
DUMP_MSG=""

DUMP_MSG+="\t${BOLD}Disable core dumps ${NORMAL}"

if [[ "${CORE_DUMPS}" != "0" ]];
then
	logger ${EXCEPTION_LOG} "2.2.3 - Disable Core Dumps "
	logger ${EXCEPTION_LOG} "FAILED. \t(Set '* soft core 0' in /etc/security/limits.conf)\n"
        DUMP_MSG+="${COLOR_RED} FAILED. \t${NORMAL}(Set \"* soft core 0\" in /etc/security/limits.conf)\n"
else
	DUMP_MSG+="${COLOR_GREEN} PASSED.\n"
fi
echo -e ${DUMP_MSG}

#
# Audit Logging
#
# Check auth messages are set to write to /var/log/auth.log
AUTH_MSG="\t${BOLD}Audit logging ${NORMAL}"
if [[ "`cat /etc/rsyslog.conf | grep ^auth,authpriv.* | wc -l`" != "0" ]];
then
        if [[ -f /var/log/auth.log ]];
        then
                 AUTH_MSG+="${COLOR_GREEN} PASSED.\n"
        fi
else
	logger ${EXCEPTION_LOG} "2.2.3 - Log Auth Messages to /var/log/auth.log "
	logger ${EXCEPTION_LOG} "FAILED. \t(Log AUTHPRIV to /var/log/auth.log)\n"
        AUTH_MSG+="${COLOR_RED} FAILED. \t${NORMAL}(Log AUTHPRIV to /var/log/auth.log)\n"
fi
echo -e ${AUTH_MSG}

#
# Check that the user accounting process is installed
#
USR_ACCT_MSG="\t${BOLD}Check user accounting is enabled ${NORMAL}"
if [[ "${OS_NAME}" == "DEBIAN" ]];
then
  ACCT_STATE="`dpkg -l | grep ^ii | awk '( print $2 )' | grep ^acct | wc -l`"
else
  ACCT_STATE="`dnf list --installed | grep psacct | wc -l`"
fi

if [[ "${ACCT_STATE}" == "1" ]];
then
	USR_ACCT_MSG+="${COLOR_GREEN}PASSED.\n"
else
  if [[ "${OS_NAME}" == "DEBIAN" ]];
  then
    USR_ACCT_MSG+="${COLOR_RED}FAILED. (Install user accounting 'apt-get install acct')\n"
  else
    USR_ACCT_MSG+="${COLOR_RED}FAILED. (Install user accounting 'yum install psacct')\n"
  fi
fi

echo -e ${USR_ACCT_MSG}

#
# System file permissions
#
echo -e "\t${NO_COLOR}System files should have strict user ownership and permissions."
logger ${EXCEPTION_LOG} "2.2.3 / 10.5 - System File Permissions"
check_file_perms /etc/passwd "-rw-r--r--" "root:root"
check_file_perms /etc/group "-rw-r--r--" "root:root"
check_file_perms /etc/shadow "-r--------" "root:root"
check_file_perms /etc/sysctl.conf "-rw-------" "root:root"

echo
echo -e "\t${NO_COLOR}#########################"
echo -e "\t${NO_COLOR}# User Account Security #"
echo -e "\t${NO_COLOR}#########################"
echo -e "\t${NO_COLOR}User accounts should be secured and removed if not in use.\n"
logger ${EXCEPTION_LOG} "2.2.3 - User Account Security\n"

#
# User Accounts
#
NOPW_MSG=""
BAD_SH=""
for PW_USER in `cat /etc/passwd | cut -d":" -f1`
do
        USER_ID=`cat /etc/passwd | grep "${PW_USER}" | awk -F":" '{ print $3 }'`

        # Check for null password
        USER_PW=`cat /etc/shadow | grep ^${PW_USER} | cut -d":" -f2`
        if [[ "${USER_PW}" == "" || "${USER_PW}" == "!*" || "${USER_PW}" == "!" ]];
        then
        	NOPW_MSG+="\t\t${BOLD}${PW_USER} ${COLOR_RED}FAILED. \t${NORMAL}(No password assigned)\n"
		logger ${EXCEPTION_LOG} "${PW_USER} FAILED. (No password assigned)\n"
        fi

        # Check for a valid shell
        USER_SHELL="`cat /etc/passwd | grep ^${PW_USER} | cut -d":" -f7`"
        if [[ "`echo ${USER_SHELL} | grep 'bash\|sh' | wc -l`" == "1" && ${USER_ID} != 0 && ${USER_ID} < 500 ]];
        then
        	BAD_SH+="\t\t${BOLD}${PW_USER} ${COLOR_RED}FAILED. \t${NO_COLOR}(UID is ${USER_ID})\n"
		logger ${EXCEPTION_LOG} "${PW_USER} FAILED. (UID is ${USER_ID})\n"
        fi
done

echo -e "\t\t${NO_COLOR}############"
echo -e "\t\t${NO_COLOR}# User IDs #"
echo -e "\t\t${NO_COLOR}############"
BAD_SH_MSG="\t\t${BOLD}Normal user accounts should have UID > 500${NORMAL} "

if [[ "${BAD_SH}" != "" ]];
then
	BAD_SH_MSG+="${COLOR_GREEN}PASSED.${NORMAL}\n"
else
	BAD_SH_MSG+="${BAD_SH}"
fi
echo -e ${BAD_SH_MSG}

echo
echo -e "\t\t${NO_COLOR}##################"
echo -e "\t\t${NO_COLOR}# User Passwords #"
echo -e "\t\t${NO_COLOR}##################"
echo -e "\t\t${NO_COLOR}All user accounts should have a password assigned.\n"
echo -e ${NOPW_MSG}

echo -e "\t\t${NO_COLOR}##################"
echo -e "\t\t${NO_COLOR}# Password Aging #"
echo -e "\t\t${NO_COLOR}##################"
echo -e "\t\t${NO_COLOR}Password aging & minimum password length options should be set.\n"
PWAGING_FILE=/etc/login.defs

logger ${EXCEPTION_LOG} "2.2.3 / 8.5.9 / 8.5.10 - Password Aging\n"

echo -e "\t\t${NORMAL}Check settings in ${PWAGING_FILE}"
check_file_option ${PWAGING_FILE} PASS_MAX_DAYS 90
check_file_option ${PWAGING_FILE} PASS_MIN_DAYS 7
check_file_option ${PWAGING_FILE} PASS_MIN_LEN 8
echo

if [[ "${SVC_ACC}" != "" ]];
then
        echo -e "\t\t${NO_COLOR}####################"
        echo -e "\t\t${NO_COLOR}# Service accounts #"
        echo -e "\t\t${NO_COLOR}####################"
        echo -e "\t\t${NO_COLOR}Service accounts should be secured and removed if not in use.\n"
        echo -e ${SVC_ACC}
fi

#
# Verify no legacy '+' entries in system files
#
echo -e "\t\t${NO_COLOR}########################"
echo -e "\t\t${NO_COLOR}# Legacy User Accounts #"
echo -e "\t\t${NO_COLOR}########################"
echo -e "\t\t${NO_COLOR}Legacy user accounts e.g. NIS, should be removed."
echo
FIND_LEGACY=""

for SYS_FILE in /etc/passwd /etc/shadow /etc/group
do
        LEGACY_DATA=`grep ^+: ${SYS_FILE}`
	LEGACY_MSG+="\t\t${BOLD}Check for legacy user entries (+) in ${SYS_FILE} ${NORMAL}"
        if [[ "${LEGACY_DATA}" == "" ]];
        then
                LEGACY_MSG+="${COLOR_GREEN} PASSED.\n"
        else
                LEGACY_MSG+="${COLOR_RED} FAILED. Remove legacy users.\n"
                LEGACY_MSG+="\t\t\t${LEGACY_DATA}"
		logger ${EXCEPTION_LOG} "2.2.3 - Legacy User Accounts\n"
		logger ${EXCEPTION_LOG} "${SYS_FILE} FAILED. Remove Legacy Users\n"
        fi
done
echo -e ${LEGACY_MSG}
echo

#############

echo -e "${NO_COLOR}##########################################"
echo -e "${NO_COLOR}# 2.2.4 Remove unnecessary functionality #"
echo -e "${NO_COLOR}##########################################\n"

## Check for unnecessary functionality
RMPKG_MSG="\t${BOLD}Check for unnecessary applications "
RMTHESE=""

for RMPKG in curl exim4 geoip-database isc-dhcp-client nfs-common procmail
do
  if [[ "${OS_NAME}" == "DEBIAN" ]];
  then
    RM_STATE="`dpkg -l | grep ^ii | awk '( print $2 )' | grep ^${RMPKG} | wc -l`"
  else
    RM_STATE="`dnf list --installed | grep ${RMPKG} | wc -l`"
  fi
  if [[ "${RM_STATE}" == "1" ]];
  then
    RMTHESE+="\t\t\t${COlOR_RED}${RMPKG}\n"
  fi
done

if [[ "${RMTHESE}" != "" ]];
then
	RMPKG_MSG+="${COLOR_RED}FAILED.\n \t\t${BOLD}The following packages should be removed:\n"
	RMPKG_MSG+="${RMTHESE}"
else
	RMPKG_MSG+="${COLOR_GREEN}PASSED.\n"
fi

echo -e ${RMPKG_MSG}

#############

echo -e "${NO_COLOR}######################################################"
echo -e "${NO_COLOR}# 2.3 Encrypt admin access using strong cryptography #"
echo -e "${NO_COLOR}######################################################\n"

## Check for SSH
SSH_MSG="\t${BOLD}Check for the SSH service "

if [[ -f /etc/ssh/sshd_config ]];
then
	SSH_MSG+="${COLOR_GREEN}PASSED\n"
	echo -e ${SSH_MSG}
	echo -e "\t${NORMAL}Check SSH Config "
	check_file_option /etc/ssh/sshd_config PermitRootLogin no
	check_file_option /etc/ssh/sshd_config UsePrivilegeSeparation yes
	check_file_option /etc/ssh/sshd_config AllowAgentForwarding no
	check_file_option /etc/ssh/sshd_config AllowTcpForwarding no
	check_file_option /etc/ssh/sshd_config StrictModes yes
	echo
else
	SSH_MSG+="${COLOR_RED}FAILED\n"
	echo -e ${SSH_MSG}
fi	

############

echo -e "${NO_COLOR}####################################################################"
echo -e "${NO_COLOR}# 6.1 Ensure latest vendor-supplied security patches are installed #"
echo -e "${NO_COLOR}####################################################################\n"

# Check for the latest patches in the repository
if [[ "${OS_NAME}" == "DEBIAN" ]];
then
  UPGR_STATE="`echo n | apt-get upgrade | grep installed | cut -d"," -f1-1 | awk '{ print $1 }'`"
else
  UPGR_STATE="`dnf check-update | grep -v "Last meta" | wc -l`"
fi

UPGRADE_MSG="\t${BOLD}Check for OS security updates "

if [[ "${UPGR_STATE}" != "0" ]];
then
	UPGRADE_MSG+="${COLOR_RED}FAILED "
else
	UPGRADE_MSG+="${COLOR_GREEN}PASSED "
fi 
	UPGRADE_MSG+="\t${BOLD}(There are ${UPGR_STATE} updates available)\n"
	echo -e ${UPGRADE_MSG}

###########

echo -e "${NO_COLOR}####################################################################"
echo -e "${NO_COLOR}# 6.3.1 Remove custom application accounts, user IDs and passwords #"
echo -e "${NO_COLOR}####################################################################\n"

RM_MSG="\t${BOLD}Remove unnecessary user accounts "
RM_USR_MSG=""

# Find unused user accounts and remove
for RM_USR in sync games lp news irc list gnats
do
	if [[ "`cat /etc/passwd | grep ${RM_USR} | wc -l`" == "1" ]];
	then
		RM_USR_MSG+="\t${COLOR_RED}${RM_USR}\n"
	fi
done


if [[ "${RM_USR_MSG}" == "" ]];
then
        RM_MSG+="${COLOR_GREEN}PASSED\n"
else
	RM_MSG+="${COLOR_RED}FAILED\n"
	RM_MSG+="\t${BOLD}Remove the following user accounts:\n ${RM_USR_MSG}\n"
	logger ${EXCEPTION_LOG} "6.3.1 Remove unnecessary user accounts\n"
	logger ${EXCEPTION_LOG} "${RM_MSG}"
fi

echo -e ${RM_MSG}


###########

echo -e "${NO_COLOR}#########################"
echo -e "${NO_COLOR}# 6.5.8 Server Security #"
echo -e "${NO_COLOR}#########################\n"

IPTABLES_MSG="\t${BOLD}Check Firewall service "

if [[ "${OS_NAME}" == "DEBIAN" ]];
then
  CHECK_FW="`ls -l /etc/network/if-pre-up.d/ | grep iptables | wc -l`"
  FW_CONFIG="/etc/default/iptables"
else
  CHECK_FW="`systemctl list-unit-files | grep enabled | grep firewalld | wc -l`"
  FW_CONFIG="/etc/firewalld/firewalld.conf"
fi

if [[ "${CHECK_FW}" == "0" ]];
then
	IPTABLES_MSG+="${COLOR_RED}FAILED\t${BOLD}(Firewall not installed)\n"
else
	if [[ -f "${FW_CONFIG}" ]];
	then
		IPTABLES_MSG+="${COLOR_GREEN}PASSED\n"
	else
		IPTABLES_MSG+="${COLOR_RED}FAILED\t${BOLD}(Firewall config not installed)\n"
	fi
fi
echo -e ${IPTABLES_MSG}

echo -e "${NO_COLOR}#################################"
echo -e "${NO_COLOR}# 7.1.1 Restrict access rights  #"
echo -e "${NO_COLOR}#################################\n"
echo
#
# Check sudo is installed
#
SUDO_MSG="\t${BOLD}Check SUDO is installed "

if [[ "${OS_NAME}" == "DEBIAN" ]];
then
  SUDO_STATE="`dpkg -l | grep ^ii | awk '( print $2 )' | grep ^sudo | wc -l`"
else
  SUDO_STATE="`dnf list --installed | grep sudo | wc -l`"
fi

if [[ "${SUDO_STATE}" == "1" ]];
then
	SUDO_MSG+="${COLOR_GREEN}PASSED.\n"
else
	SUDO_MSG+="${COLOR_RED}FAILED.\n"
fi

echo -e ${SUDO_MSG}

###########

echo -e "${NO_COLOR}###########################"
echo -e "${NO_COLOR}# 7.2.3 Default deny all  #"
echo -e "${NO_COLOR}###########################\n"

ACCESS_MSG="\t${BOLD}Check TCP wrappers are in use ${NORMAL} "

if [[ -f /etc/hosts.deny ]];
then
	if [[ "`cat /etc/hosts.deny | grep -v ^# | cut -d":" -f2-2 | grep ALL | wc -l`" == "1" ]];
	then
		ACCESS_MSG+="${COLOR_GREEN}PASSED.\n"
	else
		ACCESS_MSG+="${COLOR_RED}FAILED.\n"
	fi
else
	ACCESS_MSG+="${COLOR_RED}FAILED.\n"
fi	

echo -e ${ACCESS_MSG}

###########


echo -e ${NO_COLOR}
echo "Completed at "`date +%H:%M`" "`date +%d/%m/%Y`

