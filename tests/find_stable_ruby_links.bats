#!/usr/bin/env bats

c_helper="$(dirname "$BATS_TEST_FILENAME")/../helpers/find_stable_ruby_links"

# Minimal HTML matching the structure scraped by find_stable_ruby_links:
#   <WORD>Stable releases...</WORD> ... <WORD>Not maintained
# EOL links appear after "Not maintained" and must be excluded.
c_mock_html='<li><strong>Stable releases:</strong>
  <ul>
    <li><a href="https://cache.ruby-lang.org/pub/ruby/3.3/ruby-3.3.5.tar.gz">Ruby 3.3.5</a>
    <li><a href="https://cache.ruby-lang.org/pub/ruby/3.2/ruby-3.2.7.tar.gz">Ruby 3.2.7</a>
    <li><a href="https://cache.ruby-lang.org/pub/ruby/3.3/ruby-3.3.0-rc1.tar.gz">Ruby 3.3.0-rc1</a>
    <li><a href="https://cache.ruby-lang.org/pub/ruby/3.3/ruby-3.3.0-preview1.tar.gz">Ruby 3.3.0-preview1</a>
  </ul>
</li>
<li><strong>Not maintained anymore (EOL):</strong>
  <ul>
    <li><a href="https://cache.ruby-lang.org/pub/ruby/2.7/ruby-2.7.8.tar.gz">Ruby 2.7.8</a>
  </ul>
</li>'

setup() {
  mock_bin=$(mktemp -d)
  export PATH="$mock_bin:$PATH"

  cat > "$mock_bin/wget" << EOF
#!/bin/bash
echo '$c_mock_html'
EOF
  # Expand c_mock_html at write time
  printf '#!/bin/bash\ncat << '"'"'MOCKEOF'"'"'\n%s\nMOCKEOF\n' "$c_mock_html" > "$mock_bin/wget"
  chmod +x "$mock_bin/wget"
}

teardown() {
  rm -rf "$mock_bin"
}

@test "returns stable tarball URLs" {
  run "$c_helper"
  [ "$status" -eq 0 ]
  [[ "$output" == *"ruby-3.3.5.tar.gz"* ]]
  [[ "$output" == *"ruby-3.2.7.tar.gz"* ]]
}

@test "excludes rc versions" {
  run "$c_helper"
  [ "$status" -eq 0 ]
  [[ "$output" != *"-rc"* ]]
}

@test "excludes preview versions" {
  run "$c_helper"
  [ "$status" -eq 0 ]
  [[ "$output" != *"-preview"* ]]
}

@test "excludes EOL versions (after 'Not maintained' section)" {
  run "$c_helper"
  [ "$status" -eq 0 ]
  [[ "$output" != *"ruby-2.7"* ]]
}

@test "--latest returns exactly one URL" {
  run "$c_helper" --latest
  [ "$status" -eq 0 ]
  [ "$(echo "$output" | wc -l)" -eq 1 ]
}
