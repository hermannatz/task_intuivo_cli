#!/bin/bash
#
# @author Zeus Intuivo <zeus@intuivo.com>
#

# Compatible start with low version bash, like mac before zsh change and after
export USER_HOME
export THISSCRIPTCOMPLETEPATH
typeset -r THISSCRIPTCOMPLETEPATH="$(realpath $(which $(basename "$0")))"  # updated realpath macos 20210902 # § This goes in the FATHER-MOTHER script

export BASH_VERSION_NUMBER
typeset BASH_VERSION_NUMBER=$(echo $BASH_VERSION | cut -f1 -d.)

export  THISSCRIPTNAME
typeset -r THISSCRIPTNAME="$(realpath $(which $(basename "$0")))"  # updated realpath macos 20210902

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
  [ $? -gt 0 ] && failed to sudo_it raise_to_sudo_and_user_home && exit 1
  enforce_variable_with_value SUDO_USER "${SUDO_USER}"
  enforce_variable_with_value SUDO_UID "${SUDO_UID}"
  enforce_variable_with_value SUDO_COMMAND "${SUDO_COMMAND}"
  # Override bigger error trap  with local
  function _trap_on_error(){
    echo -e "\033[01;7m*** TRAP $THISSCRIPTNAME \\n${BASH_SOURCE}:${BASH_LINENO[-0]} ${FUNCNAME[-0]}\(\) \\n$0:${BASH_LINENO[1]} ${FUNCNAME[1]}\(\) \\n ERR INT ...\033[0m"

  }
  trap _trap_on_error ERR INT
} # end sudo_it

_linux_prepare(){
  sudo_it
  [ $? -gt 0 ] && (failed to sudo_it raise_to_sudo_and_user_home  || exit 1)
  export USER_HOME="/home/${SUDO_USER}"
  enforce_variable_with_value USER_HOME "${USER_HOME}"
}  # end _linux_prepare

_get_download_target(){
  # Sample call:
  #
  #  _get_download_target "https://linux.dropbox.com/packages/fedora/" rpm 64
  #  _get_download_target "https://linux.dropbox.com/packages/fedora/" rpm 32
  #  _get_download_target "https://linux.dropbox.com/packages/debian/" deb 32
  #
  # DEBUG=1
  local URL="${1}"   #           param order    varname    varvalue     sample_value
  enforce_parameter_with_value           1        URL      "${URL}"     "https://linux.dropbox.com/packages/fedora/"
  #
  #
  local PLATFORM="${2}"  #       param order    varname     varvalue        valid_options
  (( DEBUG )) && Message "${2}"
  enforce_parameter_with_options         2      PLATFORM   "${PLATFORM}"    "rpm   deb"
  #
  #
  local BITS="${3}"      #       param order    varname     varvalue        valid_options
  (( DEBUG )) && Message "${3}"
  enforce_parameter_with_options         3       BITS       "${BITS}"        "64   32"
  #
  #
  (( DEBUG )) && echo "CODEFILE=\"\"\"\$(wget --quiet --no-check-certificate  \"${URL}\" -O -  2>/dev/null)\"\"\""
  local CODEFILE="""$(wget --quiet --no-check-certificate  "${URL}" -O -  2>/dev/null )""" # suppress only wget download messages, but keep wget output for variable
  enforce_variable_with_value CODEFILE "${CODEFILE}"
  #
  #
  local CODELASTESTBUILD=$(_extract_version "${CODEFILE}")
  enforce_variable_with_value CODEFILE "${CODEFILE}"
  local TARGETNAME=$(echo -n "${CODELASTESTBUILD}" | grep "${PLATFORM}" | grep "${PLATFORM}" |  tail -1)
  enforce_variable_with_value TARGETNAME "${TARGETNAME}"
  echo -n "${URL}/${TARGETNAME}"
  return 0
} # end _get_download_target

_extract_version(){
  echo "${*}" | sed s/\>/\>\\n/g | sed "s/&apos;/\'/g" | sed 's/&nbsp;/ /g'  | grep -v "<a" | sort | sed s/\</\\n\</g | grep -v "</a"
} # end _extract_version

_centos__64() {
  _fedora__64
}
_fedora__64() {
  _linux_prepare
  local TARGET_URL=$(_get_download_target "https://linux.dropbox.com/packages/fedora/" "rpm" "64")
  # DEBUG=1
  (( DEBUG )) && echo -n """${TARGET_URL}""" > .tmp.html
  (( DEBUG )) && echo -n "${TARGET_URL}"
  (( DEBUG )) && echo "DEBUG EXIT 0"
  (( DEBUG )) && exit 0
  enforce_variable_with_value TARGET_URL "${TARGET_URL}"
  local CODENAME=$(basename "${TARGET_URL}")
  enforce_variable_with_value CODENAME "${CODENAME}"
  local DOWNLOADFOLDER="$(_find_downloads_folder)"
  enforce_variable_with_value DOWNLOADFOLDER "${DOWNLOADFOLDER}"
  _do_not_downloadtwice "${TARGET_URL}" "${DOWNLOADFOLDER}"  "${CODENAME}"
  _install_rpm "${TARGET_URL}" "${DOWNLOADFOLDER}"  "${CODENAME}" 0
} # end _fedora__64

_main() {
  determine_os_and_fire_action
} # end _main

_main

echo ":)"
