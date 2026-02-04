# frozen_string_literal: true

require 'stringio'
require_relative 'test_helper'

class FormatterTest < Minitest::Test
  def test_format_no_tailwind_returns_original
    config = Marshal.load(Marshal.dump(SlimLsp::Server::DEFAULT_CONFIG))
    config['tailwind']['enabled'] = false

    formatter = SlimLsp::Formatter.new(config: config, workspace_root: Dir.pwd, io_err: StringIO.new)
    input = "div class=\"text-center font-bold\""

    assert_equal input, formatter.format(input)
  end
end
