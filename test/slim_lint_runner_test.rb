# frozen_string_literal: true

require_relative 'test_helper'

class SlimLintRunnerTest < Minitest::Test
  def test_parse_json_reporter_output
    runner = SlimLsp::SlimLintRunner.new(
      config: { 'enabled' => true, 'reporter' => 'json', 'command' => 'slim-lint', 'useBundler' => false },
      workspace_root: Dir.pwd,
      io_err: StringIO.new
    )

    output = File.read(fixture_path('slim_lint/json_reporter_output.json'))
    diagnostics = runner.send(:parse_output, output)

    assert_equal 2, diagnostics.length
    assert_equal 'LineLength', diagnostics[0][:source]
    assert_equal 2, diagnostics[0][:severity]
    assert_equal 'ImplicitDiv', diagnostics[1][:source]
    assert_equal 1, diagnostics[1][:severity]
  end

  def test_parse_text_reporter_output
    runner = SlimLsp::SlimLintRunner.new(
      config: { 'enabled' => true, 'reporter' => 'text', 'command' => 'slim-lint', 'useBundler' => false },
      workspace_root: Dir.pwd,
      io_err: StringIO.new
    )

    output = File.read(fixture_path('slim_lint/text_reporter_output.txt'))
    diagnostics = runner.send(:parse_output, output)

    assert_equal 2, diagnostics.length
    assert_equal 'LineLength', diagnostics[0][:source]
    assert_equal 2, diagnostics[0][:severity]
  end

  private

  def fixture_path(relative_path)
    File.expand_path(File.join('fixtures', relative_path), __dir__)
  end
end
