# frozen_string_literal: true

require 'json'
require 'open3'
require 'pathname'

module SlimLsp
  class Formatter
    def initialize(config:, workspace_root:, io_err: $stderr)
      @config = config
      @workspace_root = workspace_root
      @io_err = io_err
      @warned = false
    end

    def format(text)
      sort_tailwind_classes_in_attributes(text)
    end

    private

    def sort_tailwind_classes_in_attributes(text)
      return text unless @config.dig('tailwind', 'enabled')

      text.gsub(/class\s*=\s*("([^"]*)"|'([^']*)')/) do
        match = Regexp.last_match
        classes = match[2] || match[3] || ''
        quote = match[2] ? '"' : "'"
        sorted = sort_tailwind_classes(classes)
        "class=#{quote}#{sorted}#{quote}"
      end
    end

    def sort_tailwind_classes(classes)
      return classes unless @config.dig('tailwind', 'enabled')

      script_path = File.expand_path('../../scripts/tailwind_sorter.mjs', __dir__)
      payload = {
        classes: classes,
        tailwindConfig: resolve_path(@config.dig('tailwind', 'configPath')),
        tailwindStylesheet: resolve_path(@config.dig('tailwind', 'stylesheetPath')),
        baseDir: @workspace_root,
        tailwindPreserveDuplicates: @config.dig('tailwind', 'preserveDuplicates'),
        tailwindPreserveWhitespace: @config.dig('tailwind', 'preserveWhitespace')
      }

      node_path = @config.dig('tailwind', 'nodePath') || 'node'
      stderr = ''
      stdout, stderr, status = Open3.capture3(node_path, script_path, stdin_data: JSON.generate(payload))
      return warn_tailwind_disabled(classes, stderr) unless status.success?

      result = JSON.parse(stdout)
      result['classes'] || classes
    rescue StandardError => e
      warn_tailwind_disabled(classes, e.message)
    end

    def warn_tailwind_disabled(classes, detail)
      return classes if @warned

      @warned = true
      @io_err.puts('[slim-lsp] Tailwind class sorting disabled. Run `npm install` in the repo or gem directory.')
      @io_err.puts("[slim-lsp] Tailwind sorter error: #{detail}") unless detail.to_s.strip.empty?
      classes
    end

    def resolve_path(path)
      return nil unless path && !path.empty?
      return path if Pathname.new(path).absolute?

      File.expand_path(path, @workspace_root)
    end
  end
end
