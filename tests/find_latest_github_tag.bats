#!/usr/bin/env bats

c_helper="$(dirname "$BATS_TEST_FILENAME")/../helpers/find_latest_github_tag"

setup() {
  mock_bin=$(mktemp -d)
  export PATH="$mock_bin:$PATH"

  # Default mock: mixed tags across two prefixes, plus peeled annotated-tag entries
  cat > "$mock_bin/git" << 'EOF'
#!/bin/bash
printf '%s\n' \
  'abc123	refs/tags/3.5.0' \
  'abc123	refs/tags/3.5.0^{}' \
  'def456	refs/tags/3.5.1' \
  'ghi789	refs/tags/3.6.0' \
  'ghi789	refs/tags/3.6.0^{}' \
  'jkl012	refs/tags/3.6.1' \
  'mno345	refs/tags/3.7.0'
EOF
  chmod +x "$mock_bin/git"
}

teardown() {
  rm -rf "$mock_bin"
}

@test "returns the latest tag matching the prefix" {
  run "$c_helper" https://example.com/repo.git 3.6
  [ "$status" -eq 0 ]
  [ "$output" = "3.6.1" ]
}

@test "does not return tags from a different prefix" {
  run "$c_helper" https://example.com/repo.git 3.5
  [ "$status" -eq 0 ]
  [ "$output" = "3.5.1" ]
}

@test "sorts versions numerically, not lexicographically" {
  cat > "$mock_bin/git" << 'EOF'
#!/bin/bash
printf '%s\n' \
  'aaa	refs/tags/3.6.2' \
  'bbb	refs/tags/3.6.9' \
  'ccc	refs/tags/3.6.10'
EOF
  chmod +x "$mock_bin/git"

  run "$c_helper" https://example.com/repo.git 3.6
  [ "$status" -eq 0 ]
  [ "$output" = "3.6.10" ]
}

@test "dots in prefix are treated as literal dots, not regex wildcards" {
  cat > "$mock_bin/git" << 'EOF'
#!/bin/bash
printf '%s\n' \
  'aaa	refs/tags/3.6.0' \
  'bbb	refs/tags/3X6.0'
EOF
  chmod +x "$mock_bin/git"

  run "$c_helper" https://example.com/repo.git 3.6
  [ "$status" -eq 0 ]
  [ "$output" = "3.6.0" ]
}

@test "ignores peeled annotated-tag entries (^{})" {
  cat > "$mock_bin/git" << 'EOF'
#!/bin/bash
printf '%s\n' \
  'aaa	refs/tags/3.6.0' \
  'aaa	refs/tags/3.6.0^{}'
EOF
  chmod +x "$mock_bin/git"

  run "$c_helper" https://example.com/repo.git 3.6
  [ "$status" -eq 0 ]
  [ "$output" = "3.6.0" ]
}
