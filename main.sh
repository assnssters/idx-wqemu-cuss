#!/bin/bash

#==============================================================#
# Script: idx wqemu QEMU/KVM Windows VM Setup (Phiên bản tinh gọn)     #
# Version: v0.1.0 (Tester)                                 #
# Credit:  Đ.Trí                               #
#==============================================================#

readonly RAM="48G"
readonly DISK_SIZE="180G"
readonly DISK_NAME="win.qcow2"
readonly ISO_NAME="win.iso"
readonly SMP_CONFIG="14,cores=14,sockets=1"

readonly RED='\033[1;31m'
readonly GREEN='\033[1;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[1;34m'
readonly LIGHT_CYAN='\033[1;96m'
readonly RESET='\033[0m'

log_info() { echo -e "${LIGHT_CYAN}[INFO]${RESET} $1"; }
log_success() { echo -e "${GREEN}[OK]${RESET} $1"; }
log_warning() { echo -e "${YELLOW}[CẢNH BÁO]${RESET} $1"; }
log_error() { echo -e "${RED}[LỖI]${RESET} $1"; }

manage_session() {
    log_info "Đang kiểm tra session cũ..."
    if [[ -e "session.env" ]]; then
        source session.env
        log_warning "Đã phát hiện session cũ."
        echo -ne "${YELLOW}Bạn muốn chạy lại session cũ (Y) hay tạo session mới (N)? ${RESET}\n"
        while true; do
            read -p "[y/n]: " optn1
            case $optn1 in
                y|Y)
                    log_info "Đang chạy lại session cũ..."
                    eval "$CMD_APT_UPDATE_INSTALL" || log_error "Không thể thực thi lệnh APT."
                    eval "$CMD_SWTPM" || log_error "Không thể khởi động SWTPM."
                    sleep 2
                    eval "$CMD_QEMU_LAUNCH" || log_error "Không thể khởi động QEMU VM."
                    log_success "Session cũ đã được khởi chạy."
                    exit 0
                    ;;
                n|N)
                    log_info "Đang xóa session cũ và các file liên quan..."
                    rm -f session.env "$DISK_NAME" "$ISO_NAME" virtio.iso OVMF_VARS.fd OVMF_CODE.fd
                    log_success "Session cũ đã được xóa."
                    break
                    ;;
                *)
                    log_error "Lựa chọn không hợp lệ. Vui lòng chọn 'y' hoặc 'n'."
                    ;;
            esac
        done
    else
        log_info "Không tìm thấy session cũ. Đang thiết lập mới."
    fi
}

update_and_install_packages() {
    log_info "Đang cập nhật hệ thống và cài đặt gói cần thiết..."
    sudo apt update -y > /dev/null 2>&1 || { log_error "Không thể cập nhật APT. Kiểm tra kết nối mạng." && exit 1; }
    sudo apt install swtpm qemu-kvm -y > /dev/null 2>&1 || { log_error "Không thể cài đặt swtpm/qemu-kvm." && exit 1; }
    log_success "Update và cài đặt gói hoàn tất."
}

download_files() {
    log_info "Đang tải file VirtIO.iso và OVMF firmware..."
    trap 'log_error "Tải file $download_file thất bại. Kiểm tra kết nối mạng." && exit 1' ERR

    download_file="virtio.iso"
    wget --progress=bar:force:noscroll -O "$download_file" https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.266-1/virtio-win.iso || exit 1
    log_success "Đã tải: $download_file"

    download_file="OVMF_VARS.fd"
    wget --progress=bar:force:noscroll -O "$download_file" https://raw.githubusercontent.com/clearlinux/common/refs/heads/master/OVMF_VARS.fd || exit 1
    log_success "Đã tải: $download_file"

    download_file="OVMF_CODE.fd"
    wget --progress=bar:force:noscroll -O "$download_file" https://raw.githubusercontent.com/clearlinux/common/refs/heads/master/OVMF_CODE.fd || exit 1
    log_success "Đã tải: $download_file"

    trap - ERR
    log_success "Tải VirtIO.iso và OVMF firmware hoàn tất."

    read -p "${YELLOW}Dán link ISO Windows vào đây: ${RESET}" isourl
    if [[ -z "$isourl" ]]; then
        log_error "Link ISO Windows không được trống."
        exit 1
    fi
    log_info "Đang tải ISO Windows từ: ${isourl}..."
    download_file="$ISO_NAME"
    wget --progress=bar:force:noscroll -O "$download_file" "$isourl" || { log_error "Không thể tải ISO Windows. Kiểm tra lại URL." && exit 1; }
    log_success "Tải ISO Windows hoàn tất: $ISO_NAME"
}

create_virtual_disk() {
    log_info "Đang tạo ổ đĩa ảo ${DISK_NAME} (${DISK_SIZE})..."
    qemu-img create -f qcow2 "$DISK_NAME" "$DISK_SIZE" || { log_error "Không thể tạo ổ đĩa ảo. Kiểm tra dung lượng trống." && exit 1; }
    log_success "Tạo ổ đĩa ảo hoàn tất: ${DISK_NAME}."
}

launch_vm() {
    log_info "Đang chuẩn bị khởi động máy ảo Windows..."

    local swtpm_cmd="xhost + ; mkdir -p /tmp/mytpm1; swtpm socket --tpmstate dir=/tmp/mytpm1 --ctrl type=unixio,path=/tmp/mytpm1/swtpm-sock --log level=20 &"

    local qemu_cmds="sudo kvm \
        -cpu host,+topoext,hv_relaxed,hv_spinlocks=0x1fff,hv-passthrough,+pae,+nx,kvm=on,+svm,+vme,+avx2,+vmx,+hypervisor,+xsave \
        -smp ${SMP_CONFIG} \
        -M q35,usb=on \
        -device usb-tablet \
        -m ${RAM} \
        -device virtio-balloon-pci \
        -vga virtio \
        -net nic,netdev=n0,model=virtio-net-pci \
        -netdev user,id=n0,hostfwd=tcp::3389-:3389 \
        -boot d \
        -device virtio-serial-pci \
        -device virtio-rng-pci \
        -chardev socket,id=chrtpm,path=/tmp/mytpm1/swtpm-sock \
        -tpmdev emulator,id=tpm0,chardev=chrtpm \
        -device tpm-tis,tpmdev=tpm0 \
        -enable-kvm \
        -device nvme,serial=deadbeef,drive=nvm \
        -drive file=${DISK_NAME},if=none,id=nvm \
        -drive file=${ISO_NAME},media=cdrom \
        -drive file=virtio.iso,media=cdrom \
        -drive file=OVMF_CODE.fd,format=raw,if=pflash \
        -drive file=OVMF_VARS.fd,format=raw,if=pflash \
        -uuid e47ddb84-fb4d-46f9-b531-14bb15156336"

    log_info "Đang lưu cấu hình session vào session.env..."
    echo "CMD_APT_UPDATE_INSTALL=\"sudo apt update -y > /dev/null 2>&1 && sudo apt install swtpm qemu-kvm -y > /dev/null 2>&1\"" > session.env
    echo "CMD_SWTPM=\"$swtpm_cmd\"" >> session.env
    echo "CMD_QEMU_LAUNCH=\"$qemu_cmds\"" >> session.env
    log_success "Đã lưu session."

    log_info "Đang khởi động TPM ảo (swtpm)..."
    eval "$swtpm_cmd" &
    sleep 2

    log_info "Đang khởi động máy ảo Windows. Cửa sổ QEMU sẽ xuất hiện..."
    eval "$qemu_cmds"
    log_success "Máy ảo đã đóng hoặc đang chạy."
}

main() {
    clear
    echo -e "${GREEN}==============================================================${RESET}"
    echo -e "${GREEN}             SCRIPT THIẾT LẬP MÁY ẢO WINDOWS QEMU/KVM          ${RESET}"
    echo -e "${GREEN}                    Bởi Đ.Trí (Phiên bản ${version})             ${RESET}"
    echo -e "${GREEN}==============================================================${RESET}\n"

    manage_session

    update_and_install_packages
    download_files
    create_virtual_disk
    launch_vm

    log_success "Thiết lập máy ảo hoàn tất!"
    log_info "Bạn có thể chạy lại script này và chọn 'Y' để khởi động lại máy ảo lần sau."
}

version="v0.1.0"
main
