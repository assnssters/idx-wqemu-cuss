#!/bin/bash
# File có lỗi, liên hệ zalo 0388779418 Để sửa lỗi :)
# You giám xem Code ha méc mẹ nè :)))
# thì ra You xem source Code méc mẹ đừng hỏi tại sao
# usr make code này là Trí :))
#---- à húu anh săn em vào lúc tối nay làm thịt rồi thành bữa tối nay anh như con sv con sv ơ à à----#

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
  read -p "'$reset"[y/n]:"$reset" " optn1
  while true;do
      case $optn in
          y|Y) $cmd1;$cmd2;$session $optn;break;exit;;
          n|N)rm session.env;rm -f win.qcow2;rm -f win.iso;break;;
          *)echo -ne ""$red"Chọn lại đê:))$reset"
      done
  esac
else
   echo -ne ""$red"Không thấy session cũ."
fi

# bắt đầu nhỉ nhiên là update package và tải mấy gói cần thiết á( do thêm cái ẩn nên ko thấy :))) )
print ""$yellow"Đang Update và Tải gói cần thiết...$reset"
sudo apt update -y > /dev/null 2>&1
sudo apt install swtpm qemu-kvm -y > /dev/null 2>&1
# Tải ít file về :)) 
wget https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.266-1/virtio-win.iso -O virtio.iso
wget https://raw.githubusercontent.com/clearlinux/common/refs/heads/master/OVMF_VARS.fd -O OVMF_VARS.fd && wget https://raw.githubusercontent.com/clearlinux/common/refs/heads/master/OVMF_CODE.fd -O OVMF_CODE.fd
