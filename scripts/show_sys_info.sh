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
    elif [[ "$os_name" == "CYGWIN_NT"* || "$os_name" == "MINGW64_NT"* ]]; then
        processor_name=$(cat /proc/cpuinfo | grep 'model name' | head -n1 | cut -d ':' -f2 | sed 's/^ *//')
        core_count=$(cat /proc/cpuinfo | grep 'cpu cores' | head -n1 | cut -d ':' -f2 | sed 's/^ *//')
        thread_count=$(cat /proc/cpuinfo | grep 'processor' | wc -l)
    fi

    if [[ "$processor_name" == *"Genuine Intel(R) CPU 0000"* ]]; then
        processor_name="Intel(R) Core(TM) Exotic CPU"
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
    elif [[ "$os_name" == CYGWIN* || "$os_name" == MINGW64_NT* ]]; then
        system_ram=$(wmic MEMORYCHIP get Capacity | awk 'NR>1 {sum += $1} END{print sum}')
        system_ram=$(echo "$system_ram / 1" | bc -l 2>/dev/null || echo "$system_ram")
    fi

    system_ram=$((system_ram / 1024 / 1024 / 1024))

    if [[ "$system_ram" -gt 0 ]]; then
        printf '%.2f\n' "$system_ram"
    fi
}



function get_win_sys_disk_letter() {
    system_drive=$(mount | awk '$2 == "/" {print substr($1, 1, 1)}' | tr '[:lower:]' '[:upper:]')
    if [[ -z "$system_drive" ]]; then
        system_drive=$(wmic logicaldisk where drivetype=3 get deviceid | awk 'NR>1{print $1}' | tr '[:lower:]' '[:upper:]')
    fi

    echo "$system_drive:"
}



function root_disk_info() {
    local os_name=$(uname -s)
    local disk_name=""
    local disk_free_space=""
    local disk_total_space=""

    if [[ "$os_name" == CYGWIN* || "$os_name" == MINGW64_NT* ]]; then
        root_partition=$get_win_sys_disk_letter
        disk_info=$(wmic logicaldisk where drivetype=3 get deviceid, size, freespace | awk 'NR>1')
        disk_name=$(echo "$disk_info" | awk -v partition="$root_partition" '$0 ~ partition {print $1}')
        disk_free_space=$(echo "$disk_info" | awk -v partition="$root_partition" '$0 ~ partition { printf "%.1f", $2/1024/1024/1024 }')
        disk_total_space=$(echo "$disk_info" | awk -v partition="$root_partition" '$0 ~ partition { printf "%.1f", $3/1024/1024/1024 }')
    elif [[ "$os_name" == Darwin || "$os_name" == Linux || "$os_name" == FreeBSD || "$os_name" == OpenBSD || "$os_name" == NetBSD ]]; then
        root_partition="/"
        disk_info=$(df -h $root_partition)
        disk_name=$(echo "$disk_info" | awk 'NR==2{print $1}')
        disk_total_space=$(echo "$disk_info" | awk 'NR==2{print $2}' | sed 's/Gi//')
        disk_free_space=$(echo "$disk_info" | awk 'NR==2{print $4}' | sed 's/Gi//')
    fi

    echo "$disk_name (free $disk_free_space GB/total $disk_total_space GB)"
}



function get_os_name() {
    local os_name=$(uname -s)

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
    elif echo "$os_name" | grep -q "^MINGW64_NT"; then
        os_name=$(systeminfo | grep "^OS Name" | awk -F': +' '{print $2}')
        os_name=${os_name/Pro/(Pro)}
    fi
    echo "$os_name"
}



function get_kernel_info() {
    local os_name=$(uname -s)
    kernel_info="Unknown kernel"

    if [[ "$os_name" == "Linux" || "$os_name" == "Darwin" ]]; then
        kernel_name=$(uname -s)
        kernel_version=$(uname -r)
    elif [[ "$os_name" == "FreeBSD" ]]; then
        kernel_name=$(uname -s)
        kernel_version=$(uname -r | awk -F '.' '{print $1}')
    elif [[ "$os_name" == "OpenBSD" || "$os_name" == "NetBSD" ]]; then
        kernel_name=$(uname -s)
        kernel_version=$(uname -r | awk -F '.' '{print $1"."$2}')
    elif echo "$os_name" | grep -q "^MINGW64_NT"; then
        kernel_name= "Windows_NT"
        kernel_version="$(wmic os get version | grep -v Version)"
    fi

    kernel_info=$kernel_name" "$kernel_version

    echo "$kernel_info"
}



function show_sys_info {
    # OS info
    os_name=$(get_os_name)
    kernel_info=$(get_kernel_info)

    # RAM info
    system_ram_capacity=$(get_ram_size)

    # Print system info
    echo -e "${bold}\033[38;5;27m OS:\033[0m ${normal}$os_name"
    echo -e "${bold}\033[38;5;27m Kernel:\033[0m ${normal}$kernel_info"
    echo -e "${bold}\033[38;5;27m CPU:\033[0m ${normal} $(get_cpu_info)"
    echo -e "${bold}\033[38;5;27m RAM:\033[0m ${normal}$system_ram_capacity GB"
    echo -e "${bold}\033[38;5;27m Root disk:\033[0m${normal} $(root_disk_info)"
    echo "------------------------------------"
}