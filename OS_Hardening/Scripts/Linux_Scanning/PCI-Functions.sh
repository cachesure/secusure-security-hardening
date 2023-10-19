export COLOR_RED='\e[0;31m'
export COLOR_GREEN='\e[0;32m'
export NO_COLOR="\e[0m"
export BOLD='\e[32;1m'
export NORMAL='\e[0m'
export EXCEPTION_MSG=""
export EXCEPTION_LOG=${SCRIPT_LOG_FILE}

function logger
{
	LOG_FILE=${1}
	MESSAGE=${2}
	if [[ "${LOG_FILE}" == "" ]];
	then
		echo "ERROR: logger() LOG_FILE is null"
		echo 1
	else
		echo -e ${MESSAGE} | cat >> ${LOG_FILE} 
	fi
}

function check_os
{
	OS_NAME=""
	if [[ -f /etc/redhat-release ]];
	then
		OS_NAME=`cat /etc/redhat-release | awk '{ print toupper($1) }'`
		OS_VERS=`cat /etc/redhat-release | awk '{ print $3 }'`
	fi
	if [[ -f /etc/debian_version ]];
	then
		OS_NAME="DEBIAN"
		OS_VERS=`cat /etc/debian_version | awk '{ print $3 }'`
	fi
	if [[ "${OS_NAME}" == "" ]];
	then
		OS_NAME="UNKNOWN"
	fi
	echo ${OS_NAME}	
}

function check_svc
{
        CHK_SVC_NAME=$1
	OS=`check_os`
	
	if [[ "${OS}" == "DEBIAN" || "${OS}" == "UNKNOWN" ]];
	then
        	if [[ "`ls -1 /etc/rc2.d | grep "^S" | sed 's/^S[0-9][0-9]//g' | grep "^${CHK_SVC_NAME}$" | wc -l`"  == "1" ]];
        	then
			echo -e "(to disable run update-rc.d ${CHK_SVC_NAME} disable)\n"
                	echo 1
        	else
                	echo 0
        	fi
	else
	  	CHK_IT=`systemctl list-unit-files --type=service | grep ${CHK_SVC_NAME} | wc -l`
		if [[ "${CHK_IT}" == "0" ]];
		then
			echo 0
		else
			echo 1
		fi
	fi
}

function check_file_perms
{
        CHK_FILE=$1
        RQD_PERMS=$2
        RQD_OWN=$3
        FILE_MSG=""

        FILE_MSG="\t\t${BOLD}Check ${CHK_FILE} "
        if [[ -f ${CHK_FILE} || -d ${CHK_FILE} ]];
        then
		TYPE_TEST="`test -f ${CHK_FILE}`"
		if [[ "${TYPE_TEST}" == "0" ]];
		then
			TYPE="File"
			FLAGS="-l"
		else
			TYPE="Directory"
			FLAGS="-dl"
		fi

                if [[ "`ls ${FLAGS} ${CHK_FILE} | awk '{ print $1 }'`" == "${RQD_PERMS}" ]];
                then
                        FILE_MSG+="${BOLD}Permissions ${COLOR_GREEN}PASSED. "
                else
                        FILE_MSG+="${BOLD}Permissions ${COLOR_RED}FAILED. ${NORMAL}(Permissions should be ${RQD_PERMS}) "
			logger ${EXCEPTION_LOG} "Permissions FAILED. (Permissions should be ${RQD_PERMS})\n"
                fi
                if [[ "`ls ${FLAGS} ${CHK_FILE} | awk '{ print $3":"$4 }'`" == "${RQD_OWN}" ]];
                then
                        FILE_MSG+="${BOLD}Ownership ${COLOR_GREEN}PASSED. "
                else
                        FILE_MSG+="${BOLD}Ownership ${COLOR_RED}FAILED. ${NORMAL}(Ownership should be ${RQD_OWN}) "
			logger ${EXCEPTION_LOG} "Ownership FAILED. (Ownership should be ${RQD_OWN})\n"
                fi
        else
                FILE_MSG+="${COLOR_RED} FAILED. (${CHK_FILE} does not exist!\n"
        fi
        echo -e ${FILE_MSG}
}

function check_kernel_param
{
	CHK_FILE=/etc/sysctl.conf
	CHK_PARAM=$1
	CHK_VALUE=$2
	KERN_MSG=""

	if [[ -f ${CHK_FILE} ]];
	then
		FILE_VAL=`cat ${CHK_FILE} | grep ${CHK_PARAM} | awk '{ print $3 }'`
		KERN_MSG="\t\t${BOLD}Check Kernel Parameter ${CHK_PARAM} ${NORMAL}"
		if [[ "${FILE_VAL}" != "${CHK_VALUE}" ]];
		then
			KERN_MSG+="${COLOR_RED} FAILED. \t(${CHK_PARAM} should be set to ${CHK_VALUE})"
			logger ${EXCEPTION_LOG} "Check Kernel Parameter ${CHK_PARAM} FAILED. \t(Set to ${CHK_VALUE})\n"
		else
			KERN_MSG+="${COLOR_GREEN} PASSED. "
		fi
	else
		KERN_MSG+=" ${COLOR_RED} FAILED. (Kernel parameter file does not exist ${CHK_FILE})"
		logger ${EXCEPTION_LOG} "FAILED. (Kernel parameter file does not exist ${CHK_FILE})\n"
	fi
	if [[ "${KERN_MSG}" != "" ]];
	then
		echo -e ${KERN_MSG}
	fi
}

function check_login_defs
{
	CHK_FILE=/etc/login.defs
	CHK_PARAM=$1
	CHK_VALUE=$2
	LOGIN_MSG=""

	if [[ -f ${CHK_FILE} ]];
	then
		LOGIN_MSG="\t\t${NO_COLOR} Check Login Definitions ${CHK_PARAM}\n"
		FILE_VAL=`cat ${CHK_FILE} |  grep -v ^# | sed '/^$/d' | grep ${CHK_PARAM} | awk '{ print $2 }'`
		if [[ "${FILE_VAL}" == "${CHK_VALUE}" ]];
		then
			LOGIN_MSG+="\t\t\t${COLOR_GREEN}+ ${CHK_PARAM} is set to ${CHK_VALUE}\n"
		else
			LOGIN_MSG+="\t\t\t${COLOR_RED}- ${CHK_PARAM} is not set to ${CHK_VALUE}\n"
		fi
	else
		LOGIN_MSG+="\t\t${COLOR_RED}- Login definitions file does not exist (${CHK_FILE})\n"
	fi
	echo -e ${LOGIN_MSG}	
}

function check_file_option
{
	CHK_FILE=$1
	CHK_PARAM=$2
	CHK_VALUE=$3

	if [[ -f ${CHK_FILE} ]];
	then
		LOG_MSG="\t\t${BOLD}Check ${CHK_PARAM}"
		FILE_VAL=`cat ${CHK_FILE} | grep -v ^# | sed '/^$/d' | grep ${CHK_PARAM} | awk '{ print $2 }'`
		if [[ "${FILE_VAL}" == "${CHK_VALUE}" ]];
		then
			LOG_MSG+="${COLOR_GREEN} PASSED."
		else
			LOG_MSG+="${COLOR_RED} FAILED. \t${NORMAL}(Set ${CHK_PARAM} to ${CHK_VALUE})"
			logger ${EXCEPTION_LOG} "${CHK_FILE} FAILED (Set ${CHK_PARAM} to ${CHK_VALUE})\n"
		fi
	else
		LOG_MSG+="${COLOR_RED} FAILED. \t${NORMAL}(${CHK_FILE} does not exist!)"
	fi
	echo -e ${LOG_MSG}
}

function check_file_exists
{
	CHK_FILE=$1

	if [[ -f ${CHK_FILE} ]];
	then
		echo 0
	else
		echo 1
	fi
}
	
