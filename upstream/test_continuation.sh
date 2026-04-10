#!/bin/bash
jq_cmd() {
    echo "jq running with args: $*"
}

out=$(echo "in" | jq_cmd \
    --arg1 "val1" \
    --arg2 "val2"
)
echo "Output: $out"

