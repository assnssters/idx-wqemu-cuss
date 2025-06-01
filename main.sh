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
# check session cũ
if [ -e "session.env" ]; then
  source session.env
  
fi

# bắt đầu nhỉ nhiên là update package và tải mấy gói cần thiết á( do thêm cái ẩn nên ko thấy :))) )
print ""$yellow"Đang Update và Tải gói cần thiết..."
sudo apt update -y > /dev/null 2>&1
sudo apt install p7zip-full qemu-kvm -y > /dev/null 2>&1
#
