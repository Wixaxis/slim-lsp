# frozen_string_literal: true

require 'json'
require 'open3'
require 'pathname'

module SlimLsp
  class SlimLintRunner
    def initialize(config:, workspace_root:, io_err: $stderr)
      @config = config
      @workspace_root = workspace_root
      @io_err = io_err
      @warned = false
    end

    def run(path, text)
      return [] unless @config['enabled']

      stdout, stderr, status = Open3.capture3(*build_command(path), stdin_data: text)
      diagnostics = parse_output(stdout)
      diagnostics.empty? ? [] : diagnostics
    rescue StandardError => e
      warn_once("slim-lint failed: #{e.message}\n#{stderr}")
      []
    ensure
      if status && !status.success? && stdout.to_s.strip.empty?
        warn_once("slim-lint exited with status #{status.exitstatus}:\n#{stderr}")
      end
    end

    private

    def build_command(path)
      command = []
      if @config['useBundler']
        command += ['bundle', 'exec']
      end

      command << (@config['command'] || 'slim-lint')
      command += ['--stdin-file-path', path]
      command += ['--reporter', @config['reporter']] if @config['reporter'] && !@config['reporter'].empty?
      command += ['-c', resolve_path(@config['configPath'])] if @config['configPath'] && !@config['configPath'].empty?

      Array(@config['includeLinters']).each do |linter|
        command += ['-i', linter]
      end

      Array(@config['excludeLinters']).each do |linter|
        command += ['-e', linter]
      end

      Array(@config['exclude']).each do |pattern|
        command += ['-x', pattern]
      end

      Array(@config['extraArgs']).each do |arg|
        command << arg
      end

      command
    end

    def parse_output(output)
      stripped = output.to_s.strip
      return [] if stripped.empty?

      if @config['reporter'] == 'json'
        parse_json(stripped)
      else
        parse_text(stripped)
      end
    end

    def parse_json(output)
      data = JSON.parse(output)
      files = if data.is_a?(Array)
                data
              else
                data['files'] || data['results'] || data['offenses'] || []
              end

      diagnostics = []
      files.each do |entry|
        if entry.is_a?(Hash) && entry.key?('offenses')
          diagnostics.concat(map_offenses(entry['offenses']))
        elsif entry.is_a?(Hash) && entry.key?('file') && entry.key?('offense')
          diagnostics.concat(map_offenses([entry['offense']]))
        elsif entry.is_a?(Hash) && entry.key?('offense')
          diagnostics.concat(map_offenses([entry['offense']]))
        end
      end

      diagnostics
    rescue JSON::ParserError
      parse_text(output)
    end

    def map_offenses(offenses)
      Array(offenses).filter_map do |offense|
        next unless offense.is_a?(Hash)

        line = (offense['line'] || 1).to_i - 1
        column = (offense['column'] || 1).to_i - 1
        message = offense['message'] || offense['reason'] || 'Slim-Lint offense'
        linter = offense['linter'] || offense['name'] || 'slim-lint'
        severity = map_severity(offense['severity'])

        {
          range: {
            start: { line: [line, 0].max, character: [column, 0].max },
            end: { line: [line, 0].max, character: [column + 1, 0].max }
          },
          severity: severity,
          source: linter,
          message: message
        }
      end
    end

    def parse_text(output)
      diagnostics = []
      output.each_line do |line|
        line = line.strip
        next if line.empty?

        if (match = line.match(/^(.*?):(\d+)(?::(\d+))?\s+\[(.+?)\]\s+(.*)$/))
          line_num = match[2].to_i - 1
          column = match[3] ? match[3].to_i - 1 : 0
          linter = match[4]
          message = match[5]

          diagnostics << {
            range: {
              start: { line: [line_num, 0].max, character: [column, 0].max },
              end: { line: [line_num, 0].max, character: [column + 1, 0].max }
            },
            severity: 2,
            source: linter,
            message: message
          }
        end
      end
      diagnostics
    end

    def map_severity(value)
      case value.to_s.downcase
      when 'error', 'fatal'
        1
      when 'warning', 'warn'
        2
      when 'info', 'information'
        3
      when 'hint'
        4
      else
        2
      end
    end

    def resolve_path(path)
      return nil unless path && !path.empty?
      return path if Pathname.new(path).absolute?

      File.expand_path(path, @workspace_root)
    end

    def warn_once(message)
      return if @warned

      @warned = true
      @io_err.puts("[slim-lsp] #{message}")
    end
  end
end
