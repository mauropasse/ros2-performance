#!/bin/bash
# scp -P 2222 -r root@192.168.1.113:/data/ros2-application-qcs40x-2024_04_02/irobot_benchmark/all_results .

# Set governor to performance
echo "echo performance > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor"
echo performance > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor

# Get the directory where the script is located
script_dir=$(dirname "$(readlink -f "$0")")
irobot_benchmark="${script_dir}/../../irobot_benchmark"
topologies_dir="${script_dir}/../topologies"
profiles_dir="${script_dir}/../profiles"

# Create a directory to store log folders
MP="${PWD}/results_mix_process"
rm -rf $MP && mkdir -p $MP

# Define message sizes and communication types
comms=("ipc_off" "loaned")

# Nme of the results folders
results=("10b" "100kb" "1mb" "4mb" "sierra_nevada_fixed_size" "white_mountain_fixed_size")
# Define topologies pairs
topology1=("pub_sub_10b" "pub_sub_100kb" "pub_sub_1mb" "pub_sub_4mb" "sierra_nevada_fixed_size" "white_mountain_fixed_size")
topology2=("sub_10b" "sub_100kb" "sub_1mb" "sub_4mb" "debug_sierra_nevada_fixed_size" "debug_white_mountain_fixed_size")

# Loop through each index in the topology1 array
for i in "${!topology1[@]}"; do
    t1=${topology1[i]}
    t2=${topology2[i]}
    res=${results[i]}

    for comm in "${comms[@]}"; do
        result_folder="$MP/${res}/${comm}"
        mkdir -p $result_folder

        # Set environment variables for "loaned" communication type
        if [ "$comm" == "loaned" ]; then
            export FASTRTPS_DEFAULT_PROFILES_FILE="${profiles_dir}/shared_memory_fastdds_config_dynamic_reusable.xml"
            export RMW_FASTRTPS_USE_QOS_FROM_XML=1
        fi

        # Topology
        if [ "$comm" == "loaned" ]; then
            top="${topologies_dir}/${t1}_loaned.json"
        else
            top="${topologies_dir}/${t1}.json"
        fi

        debug_topology="${topologies_dir}/${t2}.json"

        # Results folder

        # Run the command
        COMMAND="${irobot_benchmark} $top $debug_topology -x 3 --ipc off -t 60 -s 1000 --csv-out on --timers-separate-thread on"
        echo -e "\nCommand: \n$COMMAND\n"
        eval $COMMAND

        # Move log folders
        mv *log $result_folder

        # Unset environment variables after running "loaned" command
        if [ "$comm" == "loaned" ]; then
            unset FASTRTPS_DEFAULT_PROFILES_FILE
            unset RMW_FASTRTPS_USE_QOS_FROM_XML
        fi
    done
done
