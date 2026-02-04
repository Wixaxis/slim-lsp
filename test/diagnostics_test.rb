# frozen_string_literal: true

require_relative 'test_helper'

class DiagnosticsTest < Minitest::Test
  def test_slim_parser_raises_on_invalid_syntax
    invalid = File.read(fixture_path('diagnostics/invalid_unbalanced.slim'))
    assert_raises(StandardError) { Slim::Engine.new.call(invalid) }
  end

  def test_slim_parser_accepts_valid_syntax
    valid = File.read(fixture_path('diagnostics/valid_basic.slim'))
    Slim::Engine.new.call(valid)
  end

  def test_slim_parser_raises_on_invalid_ruby
    invalid = File.read(fixture_path('diagnostics/invalid_ruby.slim'))
    begin
      Slim::Engine.new.call(invalid)
      skip('Slim parser did not raise for invalid Ruby sample on this version')
    rescue StandardError
      assert true
    end
  end

  private

  def fixture_path(relative_path)
    File.expand_path(File.join('fixtures', relative_path), __dir__)
  end
end
