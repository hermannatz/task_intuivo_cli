#!/bin/bash
#
# @author Zeus Intuivo <zeus@intuivo.com>
#
#

# Compatible start with low version bash, like mac before zsh change and after
export USER_HOME
export THISSCRIPTCOMPLETEPATH
typeset -r THISSCRIPTCOMPLETEPATH="$(realpath $(which $(basename "$0")))"   # updated realpath macos 20210902 # § This goes in the FATHER-MOTHER script

export BASH_VERSION_NUMBER
typeset BASH_VERSION_NUMBER=$(echo $BASH_VERSION | cut -f1 -d.)

export  THISSCRIPTNAME
typeset -r THISSCRIPTNAME="$(realpath $(which $(basename "$0")))"   # updated realpath macos 20210902

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

_debian__64(){
  _linux_prepare https://prerelease.keybase.io/keybase_amd64.deb
  _install_rpm "${TARGET_URL}" "${DOWNLOADFOLDER}"  "${CODENAME}" 0
} # end __debian__64

_debian__32(){
  _linux_prepare
  local TARGET_URL=https://prerelease.keybase.io/keybase_i386.deb
  enforce_variable_with_value TARGET_URL "${TARGET_URL}"
  local CODENAME=$(basename "${TARGET_URL}")
  enforce_variable_with_value CODENAME "${CODENAME}"
  local DOWNLOADFOLDER="${USER_HOME}/Downloads"
  enforce_variable_with_value DOWNLOADFOLDER "${DOWNLOADFOLDER}"
  _do_not_downloadtwice "${TARGET_URL}" "${DOWNLOADFOLDER}"  "${CODENAME}"
  _install_rpm "${TARGET_URL}" "${DOWNLOADFOLDER}"  "${CODENAME}" 0
} # end __debian__64

_fedora__32() {
  _linux_prepare
  local TARGET_URL=https://prerelease.keybase.io/keybase_i386.rpm
  enforce_variable_with_value TARGET_URL "${TARGET_URL}"
  local CODENAME=$(basename "${TARGET_URL}")
  enforce_variable_with_value CODENAME "${CODENAME}"
  local DOWNLOADFOLDER="${USER_HOME}/Downloads"
  enforce_variable_with_value DOWNLOADFOLDER "${DOWNLOADFOLDER}"
  _do_not_downloadtwice "${TARGET_URL}" "${DOWNLOADFOLDER}"  "${CODENAME}"
  _install_rpm "${TARGET_URL}" "${DOWNLOADFOLDER}"  "${CODENAME}" 0
} # end _fedora__32

_fedora__64() {
  echo Fedora 29 REF: https://computingforgeeks.com/how-to-install-virtualbox-on-fedora-linux/
  echo Fedora 32 REF: https://tecadmin.net/install-oracle-virtualbox-on-fedora/
  echo Fedora 33 https://www.if-not-true-then-false.com/2010/install-virtualbox-with-yum-on-fedora-centos-red-hat-rhel/
  _linux_prepare

	if it_exists_with_spaces "/etc/yum.repos.d/virtualbox.repo" ; then
  {
    file_exists_with_spaces "/etc/yum.repos.d/virtualbox.repo"
  }
  else
  {
    cd "/etc/yum.repos.d/"
    wget http://download.virtualbox.org/virtualbox/rpm/fedora/virtualbox.repo
    file_exists_with_spaces "/etc/yum.repos.d/virtualbox.repo"
  }
  fi
   install_requirements "linux" "
    # ReadHat Flavor only
    binutils
    gcc
    make
    patch
    libgomp
    dkms
    qt5-qtx11extras
    libxkbcommon
    glibc-headers
    glibc-devel
    kernel-headers
    kernel-devel
    compat-libvpx5
    mokutil
 "
  is_not_installed pygmentize &&   dnf  -y install pygmentize
  if ( ! command -v pygmentize >/dev/null 2>&1; ) ;  then
    pip3 install pygments
  fi
  local groupsinstalled=$(dnf group list --installed)
  if [[ "${groupsinstalled}" = *"Development Tools"* ]] ; then
  {
    passed installed 'Development Tools'
  }
  else
  {
    dnf groupinstall 'Development Tools' -y
  }
  fi
  # dnf install libxcrypt-compat -y # needed by Fedora 30 and up
  verify_is_installed "
    mokutil
    curl
    git
    file
    pip3
    pygmentize
    xclip
    tree
    ag
    ack
    pv
    nano
    vim

    gcc
    make
    modinfo
  "
  echo sudo dnf install VirtualBox-6.1 -y
  install_requirements "linux" "
    # ReadHat Flavor only
    VirtualBox-6.1
  "
  verify_is_installed "
  VirtualBox
  "

  cd  "${USER_HOME}"
  [ ! -f  "${USER_HOME}/.virtualboxinstallreboot" ] && echo System will reboot now, after you press any key
  [ ! -f  "${USER_HOME}/.virtualboxinstallreboot" ] &&  touch "${USER_HOME}/.virtualboxinstallreboot" && _pause  "reboot 1" && reboot
  export KERN_DIR=/usr/src/kernels/`uname -r`
  echo $KERN_DIR
  cd  "${USER_HOME}"
  if [ ! -f  "${USER_HOME}/.virtualboxinstallrebootsigned" ] ; then
  {
    mkdir -p /root/signed-modules
    cd /root/signed-modules
    openssl req -new -x509 -newkey rsa:2048 -keyout MOK.priv -outform DER -out MOK.der -nodes -days 36500 -subj "/CN=VirtualBox/"
    chmod 600 MOK.priv
    echo Sign Mok REF: https://stackoverflow.com/questions/61248315/sign-virtual-box-modules-vboxdrv-vboxnetflt-vboxnetadp-vboxpci-centos-8
    echo 3- This command will ask you to add a password, you need this password after the next reboot.
    mokutil --import MOK.der

    echo REF: https://gist.github.com/reillysiemens/ac6bea1e6c7684d62f544bd79b2182a4
    local name="$(getent passwd $(whoami) | awk -F: '{print $5}')"
    local out_dir=/root/module-signing
    mkdir  -p  "${out_dir}"
    cd "${out_dir}"
    openssl \
        req \
        -new \
        -x509 \
        -newkey \
        rsa:2048 \
        -keyout ${out_dir}/MOK.priv \
        -outform DER \
        -out ${out_dir}/MOK.der \
        -days 36500 \
        -subj "/CN=${name}/"
    chmod 600 ${out_dir}/MOK.*
    echo 3- This command will ask you to add PEM key, for PEM Just press enter,  and input a password enter asd, you need this password after the next reboot.
    mokutil --import /root/module-signing/MOK.der

    echo 4- Reboot your system and a blue screen appear, select Enroll MOK --> Continue --> put the previous password and your system will start.
    echo System will reboot now, after you press any key
    [ ! -f  "${USER_HOME}/.virtualboxinstallrebootsigned" ] && touch "${USER_HOME}/.virtualboxinstallrebootsigned"  && _pause "sign reboot 4" && reboot
  }
  fi
  if [ ! -f  "${USER_HOME}/.virtualboxinstallrebootsigned2" ] ; then
  {
      cd /root/signed-modules
      # need to sign the kernel modules (vboxdrv, vboxnetflt, vboxnetadp, vboxpci)

    cat <<EOF | tee /root/signed-modules/sign-virtual-box
#!/bin/bash

for modfile in $(dirname $(modinfo -n vboxdrv))/*.ko; do
  echo "Signing $modfile"
  /usr/src/kernels/$(uname -r)/scripts/sign-file sha256 \
                                /root/signed-modules/MOK.priv \
                                /root/signed-modules/MOK.der "$modfile"
done
for modfile in $(dirname $(modinfo -n vboxnetflt))/*.ko; do
  echo "Signing $modfile"
  /usr/src/kernels/$(uname -r)/scripts/sign-file sha256 \
                                /root/signed-modules/MOK.priv \
                                /root/signed-modules/MOK.der "$modfile"
done
for modfile in $(dirname $(modinfo -n vboxnetadp))/*.ko; do
  echo "Signing $modfile"
  /usr/src/kernels/$(uname -r)/scripts/sign-file sha256 \
                                /root/signed-modules/MOK.priv \
                                /root/signed-modules/MOK.der "$modfile"
done
for modfile in $(dirname $(modinfo -n vboxpci))/*.ko; do
  echo "Signing $modfile"
  /usr/src/kernels/$(uname -r)/scripts/sign-file sha256 \
                                /root/signed-modules/MOK.priv \
                                /root/signed-modules/MOK.der "$modfile"
done
EOF
    echo REF: https://superuser.com/questions/1539756/virtualbox-6-fedora-30-efi-secure-boot-you-may-need-to-sign-the-kernel-modules
    chmod 700 /root/signed-modules/sign-virtual-box
    /root/signed-modules/sign-virtual-box

    echo "
    5- Reboot your system and a blue screen appear, select Enroll MOK --> Continue --> put the previous password and your system will start.
    "
    echo System will reboot now, after you press any key
    [ ! -f  "${USER_HOME}/.virtualboxinstallrebootsigned2" ] && touch "${USER_HOME}/.virtualboxinstallrebootsigned2"  && _pause "sign reboot 5" && reboot
  }
  fi


rm "${USER_HOME}/.virtualboxinstallrebootsigned"
rm "${USER_HOME}/.virtualboxinstallrebootsigned2"
rm "${USER_HOME}/.virtualboxinstallreboot"

  /usr/lib/virtualbox/vboxdrv.sh setup



# sudo dnf -y install @development-tools\
# sudo dnf -y install kernel-headers kernel-devel dkms elfutils-libelf-devel qt5-qtx11extras
# cat <<EOF | sudo tee /etc/yum.repos.d/virtualbox.repo \
# [virtualbox]\
# name=Fedora $releasever - $basearch - VirtualBox\
# baseurl=http://download.virtualbox.org/virtualbox/rpm/fedora/29/\$basearch\
# enabled=1\
# gpgcheck=1\
# repo_gpgcheck=1\
# gpgkey=https://www.virtualbox.org/download/oracle_vbox.asc\

# EOF

# sudo dnf search virtualbox
# yes | sudo dnf search virtualbox
# yes | sudo dnf -y install VirtualBox
# yes | sudo dnf -y install VirtualBox-6.0
# sudo usermod -a -G vboxusers $USER
# id $USER
# echo REF: https://computingforgeeks.com/how-to-install-virtualbox-on-fedora-linux/
# echo Start Virtual Box
# /sbin/vboxconfig
# sudo /sbin/vboxconfig
# dmesg
# sudo dnf -y update
# sudo dnf -y purge virtualbox
# sudo dnf -y remove VirtualBox
# sudo dnf -y uninstall VirtualBox
# sudo dnf -y remove VirtualBox
# sudo dnf -y remove VirtualBox-6.0-6.0.14_133895_fedora29-1.x86_64
# sudo dnf -y clean
# su - root /sbin/vboxconfig
# sudo /etc/init.d/vboxdrv setup
# sudo dnf -y install filezilla
# su

# /sbin/vboxconfig

# locate vbox{drv,netadp,netflt,pci}.ko

# modprobe vboxdrv

# dmesg

# virtualbox
# su

# KERN_DIR=/usr/src/kernels/`uname -r`

# export KERN_DIR

# virtualbox

# openssl req -config ./openssl.cnf         -new -x509 -newkey rsa:2048         -nodes -days 36500 -outform DER         -keyout "MOK.priv"         -out "MOK.der"

# ls

# ls -la

# pwd

# vim openssl.cnf

# openssl req -config ./openssl.cnf         -new -x509 -newkey rsa:2048         -nodes -days 36500 -outform DER         -keyout "MOK.priv"         -out "MOK.der"

# ls

# sudo mokutil --import MOK.der

# sudo cat /proc/keys

# kmodsign sha512 MOK.priv MOK.der module.ko

# module.ko

# hexdump -Cv module.ko | tail -n 5

# kmodsign

# openssl x509 -in MOK.der -inform DER -outform PEM -out MOK.pem

# sbsign --key MOK.priv --cert MOK.pem my_binary.efi --output my_binary.efi.signed

# kmodsign

# sudo dnf -y install kmodsign

# #!/bin/bash

# echo -n "Enter a Common Name to embed in the keys: "

# read NAME

# mokutil sha512 MOK.priv MOK.der module.ko

# keyctl list %:.system_keyring

cat << EOF > configuration_file.config
[ req ]
default_bits = 4096
distinguished_name = req_distinguished_name
prompt = no
string_mask = utf8only
x509_extensions = myexts

[ req_distinguished_name ]
O = Organization
CN = Organization signing key
emailAddress = E-mail address

[ myexts ]
basicConstraints=critical,CA:FALSE
keyUsage=digitalSignature
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid
EOF


# openssl req -x509 -new -nodes -utf8 -sha256 -days 36500 -batch -config configuration_file.config -outform DER -out public_key.der -keyout private_key.priv

openssl req -x509 -new -nodes -utf8 -sha256 -days 36500 -batch -config configuration_file.config -outform DER -out public_key.der -keyout private_key.priv

# mokutil -#-import

# ls

mokutil --import public_key.der

# make -C /usr/src/kernels/$(uname -r) M=$PWD modules

# perl /usr/src/kernels/$(uname -r)/scripts/sign-file sha256 my_signing_key.priv my_signing_key_pub.dermy_module.ko

# perl /usr/src/kernels/$(uname -r)/scripts/sign-file sha256 my_signing_key.priv my_signing_key_pub.der my_module.ko

# perl /usr/src/kernels/$(uname -r)/scripts/sign-file sha256 my_signing_key.priv my_signing_key_pub.der my_module.ko

# mokutil

# mokutil --import

# modprobe -v vbox

# modprobe -v vboxsrv

# modprobe -v vboxsrv.sh

# lsmod | grep vbox


echo now login as root su
echo and run
echo "
su
KERN_DIR=/usr/src/kernels/`uname -r`
export KERN_DIR
/sbin/vboxconfig

"
_pause " Presiona tecla para terminar aqui "

} # end _fedora__64
_pause() {
  echo "Press any key to continue ${1}"
  while [ true ] ; do
    read -t 3 -n 1
    if [ $? = 0 ] ; then
      break ;
    else
      echo "waiting for the keypress ${1}"
    fi
  done
  return 0
}
_main() {
  determine_os_and_fire_action
} # end _main

_main

echo ":)"
