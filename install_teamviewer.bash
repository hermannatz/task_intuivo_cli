#!/bin/bash
#
# @author Zeus Intuivo <zeus@intuivo.com>
#
#
  export THISSCRIPTCOMPLETEPATH
  typeset -gr THISSCRIPTCOMPLETEPATH="$(basename "$0")"   # § This goes in the FATHER-MOTHER script
  export _err
  typeset -i _err=0

load_struct_testing_wget(){
    local provider="$HOME/_/clis/execute_command_intuivo_cli/struct_testing"
    [   -e "${provider}"  ] && source "${provider}" && echo "Loaded locally"
    [ ! -e "${provider}"  ] && eval """$(wget --quiet --no-check-certificate  https://raw.githubusercontent.com/zeusintuivo/execute_command_intuivo_cli/master/struct_testing -O -  2>/dev/null )"""   # suppress only wget download messages, but keep wget output for variable
    ( ( ! command -v passed >/dev/null 2>&1; ) && echo -e "\n \n  ERROR! Loading struct_testing \n \n " && exit 69; )
} # end load_struct_testing_wget
load_struct_testing_wget


export sudo_it
function sudo_it() {
  raise_to_sudo_and_user_home
} # end sudo_it


_downloadfile_link(){
	_downloadfile_link "${PLATFORM}"  "${CODELASTESTBUILD}" "${URL}"
	local CODENAME=""
  case ${1} in
  mac)
    CODENAME="${3}-${2}.dmg"
    ;;

  windows)
    CODENAME="${3}-${2}.exe"
    CODENAME="${3}-${2}.win.zip"
    ;;

  linux)
    CODENAME="${3}-${2}.tar.gz"
    ;;

  *)
    CODENAME=""
    ;;
  esac
  echo "${CODENAME}"
  return 0
} # end _downloadfile_link

_version() {
  local URL="${1}"      # https://www.website.com/product/
  #                    param order varname    varvalue    sampleregex
  enforce_parameter_with_value 1 URL "${URL}" "https://www.website.com/product/"
  local PLATFORM="${2}" # mac windows linux
  #                    param order varname    varvalue      validoptions
  enforce_parameter_with_options 2 PLATFORM "${PLATFORM}" "mac windows linux"
  local PATTERN="${3}"
  #                    param order varname    varvalue    sampleregex
  enforce_parameter_with_value 3 PATTERN "${PATTERN}" "BCompareOSX*.*.*.*.zip"
  DEBUG=1
  local CODEFILE="""$(wget --quiet --no-check-certificate  "${URL}" -O -  2>/dev/null )""" # suppress only wget download messages, but keep wget output for variable
  enforce_variable_with_value CODEFILE "${CODEFILE}"
  local CODELASTESTBUILD=$(_extract_version "${CODEFILE}")
  enforce_variable_with_value CODELASTESTBUILD "${CODELASTESTBUILD}"
  echo "${CODELASTESTBUILD}"
  return 0
} # end _version

_extract_version(){
	echo "${*}" | sed s/\</\\n\</g | sed s/\>/\>\\n/g | sed "s/&apos;/\'/g" | sed 's/&nbsp;/ /g' | grep  "New in WebStorm ${PATTERN}" | sed s/\ /\\n/g | tail -1
	# | grep "What&apos;s New in&nbsp;WebStorm&nbsp;" | sed 's/\;/\;'\\n'/g' | sed s/\</\\n\</g  )
} # end _extract_version


_fedora__64() {
  sudo_it
  [ $? -gt 0 ] && failed to sudo_it raise_to_sudo_and_user_home
	# [ $? -gt 0 ] && exit 1
  enforce_variable_with_value USER_HOME "${USER_HOME}"
  local TARGET_URL=https://download.teamviewer.com/download/linux/teamviewer.x86_64.rpm
  enforce_variable_with_value TARGET_URL "${TARGET_URL}"
  local CODENAME=$(basename "${TARGET_URL}")
  enforce_variable_with_value CODENAME "${CODENAME}"
	local DOWNLOADFOLDER="${USER_HOME}/Downloads"
	enforce_variable_with_value DOWNLOADFOLDER "${DOWNLOADFOLDER}"
 	_do_not_downloadtwice "${TARGET_URL}" "${DOWNLOADFOLDER}"  "${CODENAME}"
  _install_rpm "${TARGET_URL}" "${DOWNLOADFOLDER}"  "${CODENAME}" 0
} # end _fedora__64

_main() {
  determine_os_and_fire_action
} # end _main

_main

echo ":)"