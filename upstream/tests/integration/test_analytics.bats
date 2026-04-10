#!/usr/bin/env bats
# test_analytics.bats - Integration tests for analytics features
#
# Covers:
#   - backfill command (metrics generation)
#   - stats export formats (json/csv/md)
#   - export filtering (rounds)

load '../helpers/test_helper'

setup() {
    setup_test_environment
    log_test_start "${BATS_TEST_NAME}"

    cd "$TEST_PROJECT"
    setup_test_workflow "default"

    # Create a couple of rounds for backfill/export tests
    create_mock_round 1 "default" "# Round 1\nInitial feedback."
    create_mock_round 2 "default" "# Round 2\nRefined feedback."
}

teardown() {
    log_test_end "${BATS_TEST_NAME}" "$([[ ${status:-0} -eq 0 ]] && echo pass || echo fail)"
    teardown_test_environment
}

skip_if_no_jq() {
    if ! command -v jq &>/dev/null; then
        skip "jq not available"
    fi
}

@test "backfill: generates metrics file and marks rounds as backfilled" {
    skip_if_no_jq

    run "$APR_SCRIPT" backfill

    log_test_output "$output"
    assert_success

    local metrics_path="$TEST_PROJECT/.apr/analytics/default/metrics.json"
    assert_file_exists "$metrics_path"

    local backfilled
    backfilled=$(jq -r 'any(.rounds[]?; .backfilled == true)' "$metrics_path")
    [[ "$backfilled" == "true" ]]
}

@test "stats --export json: outputs valid JSON" {
    skip_if_no_jq

    run "$APR_SCRIPT" backfill
    assert_success

    run "$APR_SCRIPT" stats --export json

    log_test_output "$output"
    assert_success
    assert_valid_json "$output"

    local schema
    schema=$(echo "$output" | jq -r '.schema_version')
    [[ "$schema" == "1.0.0" ]]
}

@test "stats --export csv: outputs header row" {
    run "$APR_SCRIPT" backfill
    assert_success

    run "$APR_SCRIPT" stats --export csv

    log_test_output "$output"
    assert_success
    # CSV headers may be quoted or unquoted
    [[ "$output" == *"round"*"timestamp"*"output_chars"* ]]
}

@test "stats --export md: outputs report header" {
    run "$APR_SCRIPT" backfill
    assert_success

    run "$APR_SCRIPT" stats --export md

    log_test_output "$output"
    assert_success
    [[ "$output" == *"APR Metrics Report"* ]]
}

@test "stats --export json --rounds filters rounds" {
    skip_if_no_jq

    run "$APR_SCRIPT" backfill
    assert_success

    run "$APR_SCRIPT" stats --export json --rounds 1-1

    log_test_output "$output"
    assert_success
    assert_valid_json "$output"

    local count
    count=$(echo "$output" | jq -r '.rounds | length')
    [[ "$count" == "1" ]]
}
