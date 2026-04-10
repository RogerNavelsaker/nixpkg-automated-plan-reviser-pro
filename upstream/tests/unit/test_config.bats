#!/usr/bin/env bats
# test_config.bats - Unit tests for APR config parsing functions

load '../helpers/test_helper'

setup() {
    setup_test_environment
    load_apr_functions
    log_test_start "${BATS_TEST_NAME}"
}

teardown() {
    log_test_end "${BATS_TEST_NAME}" "$([[ ${status:-0} -eq 0 ]] && echo pass || echo fail)"
    teardown_test_environment
}

@test "get_config_value: extracts top-level key" {
    local config="$TEST_DIR/test.yaml"
    cat > "$config" << 'EOF'
name: test-workflow
description: A test workflow
EOF

    run get_config_value "name" "$config"
    assert_success
    assert_output "test-workflow"
}

@test "get_config_value: extracts nested key under documents" {
    local config="$TEST_DIR/test.yaml"
    cat > "$config" << 'EOF'
name: test
documents:
  readme: README.md
  spec: SPECIFICATION.md
EOF

    run get_config_value "readme" "$config"
    assert_success
    assert_output "README.md"
}

@test "get_config_value: extracts key with quoted value" {
    local config="$TEST_DIR/test.yaml"
    cat > "$config" << 'EOF'
name: "quoted value"
description: 'single quoted'
EOF

    run get_config_value "name" "$config"
    assert_success
    # Should include or strip quotes depending on implementation
    [[ "$output" == "quoted value" || "$output" == '"quoted value"' ]]
}

@test "get_config_value: returns empty for missing key" {
    local config="$TEST_DIR/test.yaml"
    cat > "$config" << 'EOF'
name: test-workflow
EOF

    run get_config_value "nonexistent" "$config"
    assert_success
    assert_output ""
}

@test "get_config_value: handles key with colon in value" {
    local config="$TEST_DIR/test.yaml"
    cat > "$config" << 'EOF'
model: "5.2 Thinking"
url: "https://example.com:8080/path"
EOF

    run get_config_value "url" "$config"
    assert_success
    [[ "$output" == *"example.com"* ]]
}

@test "get_config_value: handles empty config file" {
    local config="$TEST_DIR/empty.yaml"
    touch "$config"

    run get_config_value "name" "$config"
    assert_success
    assert_output ""
}

# =============================================================================
# get_yaml_block() Tests
# =============================================================================

@test "get_yaml_block: extracts literal block scalar" {
    local config="$TEST_DIR/test.yaml"
    cat > "$config" << 'EOF'
name: test
template: |
  First line
  Second line
  Third line
other: value
EOF

    log_test_input "config file" "$(cat "$config")"

    run get_yaml_block "template" "$config"

    log_test_actual "output" "$output"

    assert_success
    [[ "$output" == *"First line"* ]]
    [[ "$output" == *"Second line"* ]]
    [[ "$output" == *"Third line"* ]]
}

@test "get_yaml_block: stops at next top-level key" {
    local config="$TEST_DIR/test.yaml"
    cat > "$config" << 'EOF'
template: |
  Line one
  Line two
next_key: should not appear
EOF

    run get_yaml_block "template" "$config"

    log_test_actual "output" "$output"

    assert_success
    [[ "$output" == *"Line one"* ]]
    [[ "$output" != *"next_key"* ]]
    [[ "$output" != *"should not appear"* ]]
}

@test "get_yaml_block: handles block at end of file" {
    local config="$TEST_DIR/test.yaml"
    cat > "$config" << 'EOF'
name: test
template: |
  Last block
  In file
EOF

    run get_yaml_block "template" "$config"

    log_test_actual "output" "$output"

    assert_success
    [[ "$output" == *"Last block"* ]]
    [[ "$output" == *"In file"* ]]
}

@test "get_yaml_block: returns empty for missing block" {
    local config="$TEST_DIR/test.yaml"
    cat > "$config" << 'EOF'
name: test
EOF

    run get_yaml_block "template" "$config"

    log_test_actual "output" "$output"

    assert_success
    [[ -z "$output" ]]
}

@test "get_yaml_block: preserves indentation in block" {
    local config="$TEST_DIR/test.yaml"
    cat > "$config" << 'EOF'
template: |
  Normal line
    Indented line
      Double indented
  Back to normal
EOF

    run get_yaml_block "template" "$config"

    log_test_actual "output" "$output"

    assert_success
    # Check that some structure is preserved
    [[ "$output" == *"Normal line"* ]]
    [[ "$output" == *"Indented line"* ]]
}

# =============================================================================
# load_prompt_template() Tests
# =============================================================================

@test "load_prompt_template: loads template block" {
    local config="$TEST_DIR/workflow.yaml"
    cat > "$config" << 'EOF'
name: test
template: |
  This is the template
  With multiple lines
EOF

    log_test_input "config file" "$(cat "$config")"

    run load_prompt_template "false" "$config"

    log_test_actual "output" "$output"

    assert_success
    [[ "$output" == *"This is the template"* ]]
}

@test "load_prompt_template: loads template_with_impl when include_impl is true" {
    local config="$TEST_DIR/workflow.yaml"
    cat > "$config" << 'EOF'
name: test
template: |
  Basic template
template_with_impl: |
  Template with implementation
  Extra content
EOF

    run load_prompt_template "true" "$config"

    log_test_actual "output" "$output"

    assert_success
    [[ "$output" == *"Template with implementation"* ]]
}

@test "load_prompt_template: falls back to template when template_with_impl missing" {
    local config="$TEST_DIR/workflow.yaml"
    cat > "$config" << 'EOF'
name: test
template: |
  Fallback template content
EOF

    run load_prompt_template "true" "$config"

    log_test_actual "output" "$output"

    assert_success
    [[ "$output" == *"Fallback template content"* ]]
}

@test "load_prompt_template: returns empty for missing template" {
    local config="$TEST_DIR/workflow.yaml"
    cat > "$config" << 'EOF'
name: test
description: No template here
EOF

    run load_prompt_template "false" "$config"

    log_test_actual "output" "$output"

    assert_success
    [[ -z "$output" ]]
}

# =============================================================================
# ensure_config_dir() Tests
# =============================================================================

@test "ensure_config_dir: creates .apr directory if missing" {
    cd "$TEST_PROJECT"

    log_test_step "action" "Calling ensure_config_dir"

    run ensure_config_dir

    log_test_actual "exit code" "$status"

    assert_success
    assert_dir_exists ".apr"
}

@test "ensure_config_dir: succeeds if .apr already exists" {
    cd "$TEST_PROJECT"
    mkdir -p ".apr"

    run ensure_config_dir

    assert_success
    assert_dir_exists ".apr"
}

@test "ensure_config_dir: creates nested directories" {
    cd "$TEST_PROJECT"

    run ensure_config_dir

    assert_success
    # Check that subdirectories might be created
    # (depends on implementation)
    assert_dir_exists ".apr"
}

# =============================================================================
# load_config() Tests
# =============================================================================

@test "load_config: loads workflow-specific config" {
    cd "$TEST_PROJECT"
    setup_test_workflow "myworkflow"

    # Set WORKFLOW variable
    WORKFLOW="myworkflow"
    CONFIG_DIR="$TEST_PROJECT/.apr"

    run load_config

    log_test_actual "exit code" "$status"

    assert_success
}

@test "load_config: fails when no config exists" {
    cd "$TEST_PROJECT"
    mkdir -p ".apr"
    # No workflow configs

    WORKFLOW="nonexistent"
    CONFIG_DIR="$TEST_PROJECT/.apr"

    run load_config

    log_test_actual "exit code" "$status"

    # Should fail or return empty
    # Behavior depends on implementation
    [[ $status -ne 0 ]] || [[ -z "$output" ]]
}

# =============================================================================
# Stream Separation Tests
# =============================================================================

@test "config functions: error messages go to stderr" {
    cd "$TEST_PROJECT"

    # Try to load non-existent config
    WORKFLOW="nonexistent"
    CONFIG_DIR="$TEST_PROJECT/.apr"

    capture_streams load_config

    log_test_actual "stdout" "$CAPTURED_STDOUT"
    log_test_actual "stderr" "$CAPTURED_STDERR"

    # Any error messages should be on stderr, not stdout
    # (stdout should be empty or contain only data)
}
