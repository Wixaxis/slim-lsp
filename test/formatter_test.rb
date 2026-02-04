# frozen_string_literal: true

require 'stringio'
require 'json'
require 'open3'
require_relative 'test_helper'

class FormatterTest < Minitest::Test
  def test_format_no_tailwind_returns_original
    config = Marshal.load(Marshal.dump(SlimLsp::Server::DEFAULT_CONFIG))
    config['tailwind']['enabled'] = false

    formatter = SlimLsp::Formatter.new(config: config, workspace_root: Dir.pwd, io_err: StringIO.new)
    input = "div class=\"text-center font-bold\""

    assert_equal input, formatter.format(input)
  end

  def test_tailwind_sorter_matches_node_output
    config = Marshal.load(Marshal.dump(SlimLsp::Server::DEFAULT_CONFIG))
    config['tailwind']['enabled'] = true
    config['tailwind']['nodePath'] = ENV['NODE_PATH'] if ENV['NODE_PATH'] && !ENV['NODE_PATH'].empty?

    formatter = SlimLsp::Formatter.new(config: config, workspace_root: Dir.pwd, io_err: StringIO.new)
    input = "div class=\"text-center font-bold\""

    script_path = File.expand_path('../scripts/tailwind_sorter.mjs', __dir__)
    payload = {
      classes: 'text-center font-bold',
      tailwindConfig: nil,
      tailwindStylesheet: nil,
      baseDir: Dir.pwd,
      tailwindPreserveDuplicates: false,
      tailwindPreserveWhitespace: true
    }

    node_path = config['tailwind']['nodePath'] || 'node'
    stdout, _stderr, status = Open3.capture3(node_path, script_path, stdin_data: JSON.generate(payload))

    unless status.success?
      skip('Node Tailwind sorter not available; skipping integration test.')
    end

    expected = JSON.parse(stdout)['classes']
    formatted = formatter.format(input)
    match = formatted.match(/class\\s*=\\s*\"([^\"]*)\"/)

    refute_nil match, 'Expected class attribute in formatted output.'
    assert_equal expected, match[1]
  end

  def test_format_matches_fixture_simple
    input = File.read(fixture_path('format/input_simple.slim'))
    expected = File.read(fixture_path('format/expected_simple.slim'))

    formatted = formatter.format(input)
    assert_equal expected, formatted
  end

  def test_format_matches_fixture_multi_attrs
    input = File.read(fixture_path('format/input_multi_attrs.slim'))
    expected = File.read(fixture_path('format/expected_multi_attrs.slim'))

    formatted = formatter.format(input)
    assert_equal expected, formatted
  end

  private

  def formatter
    config = Marshal.load(Marshal.dump(SlimLsp::Server::DEFAULT_CONFIG))
    config['tailwind']['enabled'] = true
    config['tailwind']['nodePath'] = ENV['NODE_PATH'] if ENV['NODE_PATH'] && !ENV['NODE_PATH'].empty?

    SlimLsp::Formatter.new(config: config, workspace_root: Dir.pwd, io_err: StringIO.new)
  end

  def fixture_path(relative_path)
    File.expand_path(File.join('fixtures', relative_path), __dir__)
  end
end
