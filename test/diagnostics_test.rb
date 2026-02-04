# frozen_string_literal: true

require_relative 'test_helper'

class DiagnosticsTest < Minitest::Test
  def test_slim_parser_raises_on_invalid_syntax
    invalid = "div\n  ="
    assert_raises(StandardError) { Slim::Engine.new.call(invalid) }
  end

  def test_slim_parser_accepts_valid_syntax
    valid = "div\n  | hello"
    Slim::Engine.new.call(valid)
  end
end
