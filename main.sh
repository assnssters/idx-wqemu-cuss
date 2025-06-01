#!/bin/bash
# File có lỗi, liên hệ zalo 0388779418 Để sửa lỗi :)
# You giám xem Code ha méc mẹ nè :)))
# thì ra You xem source Code méc mẹ đừng hỏi tại sao
# usr make code này là Trí :))
#---- à húu anh săn em vào lúc tối nay làm thịt rồi thành bữa tối nay anh như con sv con sv ơ à à----#

# Variable cho VM :)
ram=48G
disksize=180G
diskname=win.qcow2
isoname=win.iso
smp="14,cores=14,sockets=1"
option=" "
# thêm mã màu cho nó đẹp ý mà :))
red='\033[1;31m'
green='\033[1;32m'
yellow='\033[1;33m'
blue='\033[1;34m'
light_cyan='\033[1;96m'
reset='\033[0m'

# thêm version :))
version=v0.1.0
clear
echo -ne ""$green"Credit: Đ.Trí :)"
echo -ne ""$green"Version: $version"

# check session cũ
if [ -e "session.env" ]; then
  source session.env
  echo -ne ""$yellow"Đã Phát hiện session cũ ấn Y để chạy lại ,N để tạo session mới.$reset"
  read -p "'$reset"[y/n]:"$reset" optn1
  while true;do
      case $optn in
          y|Y) $cmd1;$cmd2;$session $optn;break;exit;;
          n|N)rm -f session.env;rm -f win.qcow2;rm -f win.iso;break;;
          *)echo -ne ""$red"Chọn lại đê$reset";;
      esac
  done
else
   echo -ne ""$red"Không thấy session cũ."
fi
# bắt đầu nhỉ nhiên là update package và tải mấy gói cần thiết á( do thêm cái ẩn nên ko thấy :))) )
printf ""$yellow"Đang Update và Tải gói cần thiết...$reset"
sudo apt update -y > /dev/null 2>&1
sudo apt install swtpm qemu-kvm -y > /dev/null 2>&1

# Tải ít file về :)) 
wget https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.266-1/virtio-win.iso -O virtio.iso
wget https://raw.githubusercontent.com/clearlinux/common/refs/heads/master/OVMF_VARS.fd -O OVMF_VARS.fd && wget https://raw.githubusercontent.com/clearlinux/common/refs/heads/master/OVMF_CODE.fd -O OVMF_CODE.fd

# Tải file os ;)
read -p ""$yellow"Bỏ link ISO Windows vào đây: " isourl
wget "$isourl" -O $isoname
qemu-img create -f qcow2 $diskname $disksize

# :) Set vari
cmd="xhost + ; mkdir /tmp/mytpm1; swtpm socket --tpmstate dir=/tmp/mytpm1 --ctrl type=unixio,path=/tmp/mytpm1/swtpm-sock --log level=20 &"
qemucmds="sudo kvm -cpu host,+topoext,hv_relaxed,hv_spinlocks=0x1fff,hv-passthrough,+pae,+nx,kvm=on,+svm,+vme,+avx2,+vmx,+hypervisor,+xsave -smp "$smp" -M q35,usb=on -device usb-tablet -m "$ram" -device virtio-balloon-pci -vga virtio -net nic,netdev=n0,model=virtio-net-pci -netdev user,id=n0,hostfwd=tcp::3389-:3389 -boot d     -device virtio-serial-pci -device virtio-rng-pci      -chardev socket,id=chrtpm,path=/tmp/mytpm1/swtpm-sock -tpmdev emulator,id=tpm0,chardev=chrtpm -device tpm-tis,tpmdev=tpm0 -enable-kvm -device nvme,serial=deadbeef,drive=nvm -drive file="$diskname",if=none,id=nvm -drive file="$isoname",media=cdrom -drive file=virtio.iso,media=cdrom -drive file=OVMF_CODE.fd,format=raw,if=pflash     -drive file=OVMF_VARS.fd,format=raw,if=pflash     -uuid e47ddb84-fb4d-46f9-b531-14bb15156336"

# Tạo Session (session.env) :))
echo "cmd1=apt update && apt install swtpm qemu-kvm -y" >> session.env
echo "cmd2=$cmd" >> session.env
echo "session=$qemucmds" >> session.env

