#!/bin/bash

readonly DISK="/dev/sda"
readonly DISK_PASS="1234"
readonly HOST="tosca"
readonly ROOT_PASS="1234"
readonly USER="abc"
readonly USER_PASS="1234"
readonly REGION_CITY="Europe/Amsterdam"
readonly PKGS=(
  'vim'
  'man'
  'terminus-font'
)

err() { echo "$*"; exit 1; }

install() {
  # check connection
  ping -c 1 mit.edu >& /dev/null || err "No Internet" 

  # create dos parition table
  # + boot + system parition
  echo "==> Partitioning ${DISK}..."
  parted --script "${DISK}" \
    mklabel msdos \
    mkpart primary 1 256 \
    mkpart primary 256 100% \
    set 1 boot on \
    set 2 lvm on

  local boot_part="${DISK}1"
  local syst_part="${DISK}2"

  # setup encrypted lvm container 
  local crypt_cont="/dev/mapper/crypt"
  echo -n "${DISK_PASS}" | cryptsetup luksFormat "${syst_part}" -
  echo "${DISK_PASS}" | cryptsetup open "${syst_part}" crypt -

  # setup logical volumes
  pvcreate "${crypt_cont}"
  vgcreate data "${crypt_cont}"
  lvcreate -L 10G data -n root
  lvcreate -L  5G data -n home

  # format boot parition and LVs
  echo "==> Formatting ${DISK}..." 
  yes | mkfs.ext4 -q "${boot_part}"
  yes | mkfs.ext4 -q /dev/data/root 
  yes | mkfs.ext4 -q /dev/data/home 

  # mount new partitions
  mount /dev/data/root /mnt
  mkdir -p /mnt/home /mnt/boot
  mount /dev/data/home /mnt/home
  mount "${boot_part}" /mnt/boot

  # find fastest mirrors
  echo "==> Downloading mirrorlist..."
  local iso=$(curl -4s ifconfig.co/country-iso)
  reflector -p https -a 48 -c "${iso}" -l 5 --save /etc/pacman.d/mirrorlist

  # set parallel downloads
  sed -i 's/^#Para/Para/' /etc/pacman.conf

  # setup arch
  pacstrap /mnt base linux linux-firmware intel-ucode iwd grub doas lvm2
  genfstab -U /mnt > /mnt/etc/fstab

  # install grub
  grub-install --boot-directory=/mnt/boot ${DISK}

  # copy setup files to new system
  cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist
  cp "$0" /mnt/root/setup.sh

  # run post-install setup in chroot
  arch-chroot /mnt ./root/setup.sh setup 
}

setup() {
  # set root password
  echo -e "${ROOT_PASS}\n${ROOT_PASS}" | passwd

  # setup new user
  useradd -m "${USER}"
  echo -e "${USER_PASS}\n${USER_PASS}" | passwd "${USER}"

  # add new user to doas
  echo "permit ${USER} as root" > /etc/doas.conf
  chmod 600 /etc/doas.conf

  # auto-login as new user
  local tty_config="/etc/systemd/system/getty@tty1.service.d/autologin.conf"
  mkdir -p $(dirname "${tty_config}") 
  printf "%b" "[Service]\nExecStart=\nExecStart=" \
    "-/usr/bin/agetty -i --autologin ${USER} %I \$TERM" > "${tty_config}"

  # set hostname
  echo "${HOST}" > /etc/hostname

  # set timezone
  ln -sf "/usr/share/zoneinfo/${REGION_CITY}" /etc/localtime
  hwclock --systohc
  timedatectl set-ntp true

  # set locale
  sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
  locale-gen
  echo "LANG=en_US.UTF-8" > /etc/locale.conf

  # add hook for encrypted boot
  sed -i 's/autodetect modconf block/block encrypt lvm2/' /etc/mkinitcpio.conf

  # intel graphics early kms for coreboot
  sed -i 's/^MODULES=(/&i915/' /etc/mkinitcpio.conf
  mkinitcpio -p linux

  # configure grub for encrypted boot
  local uuid="$(blkid | grep crypto_LUKS | cut -d \" -f 2)"
  local grub_cmdline=$(echo "cryptdevice=UUID=${uuid}:crypt" \
    "root=\/dev\/data\/root")
  sed -i "s/^GRUB_CMDLINE_LINUX=\"/&${grub_cmdline}/" /etc/default/grub

  # remove boot menu / install grub
  sed -i 's/^GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/' /etc/default/grub
  grub-mkconfig -o /boot/grub/grub.cfg

  # setup wireless
  echo -e "\n# Cloudflare\nnameserver 1.1.1.1" >> /etc/resolv.conf
  mkdir -p /etc/iwd
  printf "%b" "[General]\nEnableNetworkConfiguration=true\n\n" \
    "[Network]\nNameResolvingService=systemd\n" > /etc/iwd/main.conf
  systemctl enable iwd
  systemctl enable systemd-resolved  

  # setup firewall
  # pacman -Sy ufw
  # systemctl enable ufw
  # ufw logging off
  # ufw enable

  # install packages
  for pkg in "${PKGS[@]}"; do
    pacman -Sy "${pkg}" --noconfirm --needed
  done
}

main() {
  set -x
  if [ "$1" = "setup" ]; then
    setup # run in chroot 
  else
    install
  fi
}

main "$@"
