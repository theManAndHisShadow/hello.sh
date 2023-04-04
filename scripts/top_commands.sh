#!/bin/bash

export LANG=C
export LC_CTYPE=C

function trim_and_pad {
    local input_text=$1
    local max_length=${2:-10}

    if ((max_length > 3)); then
        if ((${#input_text} > max_length)); then
            echo "${input_text:0:max_length-3}..."
        else
            printf "%-${max_length}s" "$input_text"
        fi
    fi
}



function top_commands() {
    os_name=$(uname -s)

    LISTLENGTH=${1:-5}
    SHELLNAME=$(basename "$SHELL") # get current shell name without "/bin/"
    HOME_DIR="$HOME"
    COLUMN="2"

    if echo "$os_name" | grep -q "MINGW64_NT"; then
        HOME_DIR=$(cygpath -m ~) # get Windows-style home directory path
        COLUMN="1"

    fi

    HISTORY_FILE="$HOME_DIR/.${SHELLNAME}_history" # get the history file for the current shell

    if [[ -f $HISTORY_FILE ]]; then
        # check if history file exists
        CMD_COUNT=$(cat $HISTORY_FILE | awk -v col="$COLUMN" 'BEGIN {FS=";"} {print $col}' | awk 'length($0) > 0' | sort | uniq -c | sort -rn | head -n $LISTLENGTH) # count the frequency of each command and get the top 10 frequent commands

        # count the total number of commands in history
        TOTAL_CMD=$(cat $HISTORY_FILE | wc -l)

        # loop index
        i=0

        echo "* Top used commands: "

        echo "$CMD_COUNT" | while read count command; do
            # increase i
            i=$((i + 1))

            # calculate percentage of usage
            percentage=$(awk -v count="$count" -v total="$TOTAL_CMD" 'BEGIN {printf "%.2f", count/total*100}')

            command=$(trim_and_pad "$command" 20)

            # format output
            echo "$i.$command  $percentage%  ($count)"
        done
    else
        echo "No history file found for $SHELLNAME shell"
    fi

    exit 0
}
