#!/bin/bash

function get_cpu_info() {
    local os_name=$(uname -s)
    local processor_name="Unknown"
    local core_count="Unknown"
    local thread_count="Unknown"

    if [[ "$os_name" == "Linux" ]]; then
        processor_name=$(grep 'model name' /proc/cpuinfo | head -n1 | cut -d ':' -f2 | sed 's/^ *//')
        core_count=$(grep 'cpu cores' /proc/cpuinfo | head -n1 | cut -d ':' -f2 | sed 's/^ *//')
        thread_count=$(grep 'processor' /proc/cpuinfo | wc -l)
    elif [[ "$os_name" == "Darwin" ]]; then
        processor_name=$(sysctl -n machdep.cpu.brand_string)
        core_count=$(sysctl -n machdep.cpu.core_count)
        thread_count=$(sysctl -n machdep.cpu.thread_count)
    elif [[ "$os_name" == "FreeBSD" || "$os_name" == "OpenBSD" ]]; then
        processor_name=$(sysctl -n hw.model)
        core_count=$(sysctl -n hw.ncpu)
        thread_count=$(sysctl -n hw.smt)
    fi

    if [[ "$processor_name" == *"Genuine Intel(R) CPU 0000"* ]]; then
        processor_name="IntelExotic"
    fi

    # CPU arch
    os_arch=$(uname -m)

    echo $processor_name" ("$core_count"c/"$thread_count"t, "$os_arch")"
}



function get_ram_size() {
    local os_name=$(uname -s)
    local system_ram=0

    if [[ "$os_name" == "Linux" || "$os_name" == "FreeBSD" || "$os_name" == "OpenBSD" || "$os_name" == "NetBSD" ]]; then
        system_ram=$(free -b | awk '/^Mem:/ {print $2}')
    elif [[ "$os_name" == "Darwin" ]]; then
        system_ram=$(sysctl -n hw.memsize)
    fi

    if [[ "$system_ram" -gt 0 ]]; then
        system_ram=$(echo "scale=2; $system_ram / 1024^3" | bc -l)
    fi

    echo "$system_ram"
}



function root_disk_info() {
    root_partition=$(df / | awk '{print $1}')
    disk_name=$(df / | awk 'NR==2{print $1}')
    disk_free_space=$(df -h / | awk '{print $4}' | tail -1)
    disk_total_space=$(df -h / | awk '{print $2}' | tail -1)

    echo "$disk_name ($disk_free_space""B/$disk_total_space""B)"
}



function get_os_name() {
    local os_name=$(uname -s)
    local code_name= "empty"
    
    if [[ "$os_name" == "Linux" ]]; then
        local code_name=$(lsb_release -cs)
        os_name=$(lsb_release -is)" "$(lsb_release -rs)" ("${code_name^}")"
    elif [[ "$os_name" == "Darwin" ]]; then
        os_version=$(sw_vers -productVersion)
        os_name="Apple macOS ${os_version} ("
        case "${os_version}" in
            11.*) os_name+="Big Sur" ;;
            10.15.*) os_name+="Catalina" ;;
            10.14.*) os_name+="Mojave" ;;
            10.13.*) os_name+="High Sierra" ;;
            # add more versions here if needed
        esac
        os_name+=")"
    fi
    echo "$os_name"
}



function show_sys_info {
    # OS info
    os_name=$(get_os_name)

    # Kernel info
    kernel_name=$(uname -s)
    kernel_version=$(uname -r)

    # RAM info
    system_ram_capacity=$(get_ram_size)

    # Print system info
    echo -e "${bold}\033[38;5;27m OS:\033[0m ${normal}$os_name"
    echo -e "${bold}\033[38;5;27m Kernel:\033[0m ${normal}$kernel_name $kernel_version"
    echo -e "${bold}\033[38;5;27m CPU:\033[0m ${normal} $(get_cpu_info)"
    echo -e "${bold}\033[38;5;27m RAM:\033[0m ${normal}$system_ram_capacity GB"
    echo -e "${bold}\033[38;5;27m Root disk:\033[0m${normal} $(root_disk_info)"
    echo "------------------------------------"
}
