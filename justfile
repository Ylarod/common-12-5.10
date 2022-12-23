tag := "android12-5.10-2022-05"
os_version := "12.0.0"
os_patch_level := "2022-05"
boot_size := "$((64*1024*1024))"

enable_thin_lto := "true"
thin_lto := if enable_thin_lto == "true" { " LTO=thin " } else { "" }

alias i := info
alias c := compdb

alias b := build
alias rb := rebuild
alias bb := build_boot
alias bgz := build_boot_gz
alias blz := build_boot_lz4

default: info
    @just --list --unsorted

info:
    @echo tag: {{ tag }}
    @echo os_version: {{ os_version }}
    @echo os_patch_level: {{ os_patch_level }}
    @echo boot_size: {{ boot_size }}
init: info
    #!/bin/bash
    echo "---------"
    echo "Current branch: `git symbolic-ref --short HEAD` "
    echo "Kernel version: " `head -4 Makefile | tail -3 | sed "s/[[:space:]]//g" | awk -F"=" '{ print $2 }' | sed ":a;N;s/\n/\./g;ta"`
    read -r -p "Are you sure? [y/N] " input
    if echo "$input" | grep -iq "^y" ;then
        @echo "[+] Initializing"
    else
        exit 0
    fi
    # remove previous out/
    if [ -d "out" ]; then
        @echo "[+] Remove out/"
        rm -rf out/
    fi
    # get vscode-linux-kernel
    if [ ! -d ".vscode" ]; then
        @echo "[+] Clone vscode-linux-kernel"
        git clone git@github.com:Ylarod/vscode-linux-kernel.git .vscode
    fi
    # get ramdisk
    @echo "[+] Download prebuilt ramdisk"
    curl -Lo gki-kernel.zip https://dl.google.com/android/gki/gki-certified-boot-{{ tag }}_r1.zip
    unzip gki-kernel.zip
    ../tools/mkbootimg/unpack_bootimg.py --boot_img=$(find . -maxdepth 1 -name "*.img")
    rm gki-kernel.zip
    rm $(find . -maxdepth 1 -name "*.img")
    # clone repo
    @echo "[+] Clone KernelSU"
    read -r -p "Use fork repo of KernelSU? [y/N] " input
    if echo "$input" | grep -iq "^y" ;then
        read -r -p "Input github repo url" repo
        git clone $repo KernelSU
        cd KernelSU
        git remote add upstream git@github.com:tiann/KernelSU.git
        cd ..
    else
        read -r -p "Use ssh instead of https? [y/N] " input
        if echo "$input" | grep -iq "^y" ;then
            git clone git@github.com:tiann/KernelSU KernelSU
        else
            git clone https://github.com/tiann/KernelSU KernelSU
        fi
    fi
    # setup
    @echo "[+] Setup KernelSU"
    ln -sf $(pwd)/KernelSU/kernel $(pwd)/drivers/kernelsu
    grep -q "kernelsu" drivers/Makefile || echo "obj-y += kernelsu/" >> drivers/Makefile
    # done
    echo "[+] Initialized"
    echo "Please run 'just build' to build first"
    echo "And run 'just compdb' to generate compile_commands.json"
build:
    #!/bin/bash
    cd ..
    if [ -d "out" ]; then
        read -r -p "out/ is already existed, are you SURE to clean and build? [y/N] " input
        if echo "$input" | grep -iq "^y" ;then
            echo Rebuilding
        else
            exit 0
        fi
    fi
    cd .. && {{ thin_lto }} BUILD_CONFIG=common/build.config.gki.aarch64 build/build.sh
rebuild:
    #!/bin/bash
    cd ..
    SKIP_MRPROPER=1 SKIP_DEFCONFIG=1 {{ thin_lto }} BUILD_CONFIG=common/build.config.gki.aarch64 build/build.sh
compdb:
    python3 .vscode/generate_compdb.py -O ../out/android12-5.10/common
gen_boot IMAGE OUTPUT:
    ../tools/mkbootimg/mkbootimg.py --header_version 4 --kernel {{ IMAGE }} --ramdisk out/ramdisk --output {{ OUTPUT }} --os_version {{ os_version }} --os_patch_level {{ os_patch_level }}
sign_boot BOOTIMG:
    ../build/build-tools/path/linux-x86/avbtool add_hash_footer --partition_name boot --partition_size {{ boot_size }} --image {{BOOTIMG}} --algorithm SHA256_RSA2048 --key ../prebuilts/kernel-build-tools/linux-x86/share/avb/testkey_rsa2048.pem
build_boot:
    @just gen_boot ../out/android12-5.10/dist/Image out/boot.img
    @just sign_boot out/boot.img
build_boot_gz:
    cat ../out/android12-5.10/dist/Image | ../prebuilts/build-tools/path/linux-x86/gzip -n -f -9 > out/Image.gz
    @just gen_boot out/Image.gz out/boot-gz.img
    @just sign_boot out/boot-gz.img
build_boot_lz4:
    @just gen_boot ../out/android12-5.10/dist/Image.lz4 out/boot-lz4.img
    @just sign_boot out/boot-lz4.img