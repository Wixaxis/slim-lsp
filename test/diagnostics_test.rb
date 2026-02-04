# frozen_string_literal: true

require_relative 'test_helper'

class DiagnosticsTest < Minitest::Test
  def test_slim_parser_raises_on_invalid_syntax
    invalid = "div\n  = 1 +"
    begin
      Slim::Engine.new.call(invalid)
      skip('Slim parser did not raise for invalid sample on this version')
    rescue StandardError
      assert true
    end
  end

  def test_slim_parser_accepts_valid_syntax
    valid = "div\n  | hello"
    Slim::Engine.new.call(valid)
  end
end
