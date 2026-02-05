# frozen_string_literal: true

module SlimLsp
  class Server
    CONTENT_LENGTH = 'content-length'

    HTML_TAGS = %w[
      a abbr address area article aside audio b base bdi bdo blockquote body br
      button canvas caption cite code col colgroup data datalist dd del details
      dfn dialog div dl dt em embed fieldset figcaption figure footer form h1 h2
      h3 h4 h5 h6 head header hr html i iframe img input ins kbd label legend li
      link main map mark meta meter nav noscript object ol optgroup option output
      p param picture pre progress q rp rt ruby s samp script section select small
      source span strong style sub summary sup table tbody td template textarea tfoot
      th thead time title tr track u ul var video wbr
    ].freeze

    SLIM_KEYWORDS = %w[
      doctype
      javascript:
      css:
      markdown:
      ruby:
      coffeescript:
      sass:
      scss:
      less:
    ].freeze

    DEFAULT_CONFIG = {
      'tailwind' => {
        'enabled' => true,
        'configPath' => nil,
        'stylesheetPath' => nil,
        'preserveDuplicates' => false,
        'preserveWhitespace' => true,
        'nodePath' => 'node'
      },
      'lint' => {
        'enabled' => false,
        'command' => 'slim-lint',
        'useBundler' => true,
        'reporter' => 'json',
        'configPath' => nil,
        'includeLinters' => [],
        'excludeLinters' => [],
        'exclude' => [],
        'extraArgs' => []
      },
      'completion' => {
        'enabled' => true
      }
    }.freeze

    def initialize(io_in: $stdin, io_out: $stdout)
      @io_in = io_in
      @io_out = io_out
      @documents = {}
      @config = Marshal.load(Marshal.dump(DEFAULT_CONFIG))
      @workspace_root = Dir.pwd
      @formatter = Formatter.new(config: @config, workspace_root: @workspace_root)
    end

    def run
      loop do
        message = read_message
        break unless message

        handle_message(message)
      end
    end

    private

    def read_message
      headers = {}

      loop do
        line = @io_in.gets
        return nil if line.nil?

        line = line.strip
        break if line.empty?

        key, value = line.split(':', 2)
        headers[key.downcase] = value.strip
      end

      length = headers[CONTENT_LENGTH].to_i
      return nil if length <= 0

      body = @io_in.read(length)
      JSON.parse(body)
    end

    def send_message(payload)
      json = JSON.generate(payload)
      @io_out.write("Content-Length: #{json.bytesize}\r\n\r\n")
      @io_out.write(json)
      @io_out.flush
    end

    def send_response(id, result: nil, error: nil)
      payload = { jsonrpc: '2.0', id: id }
      if error
        payload[:error] = error
      else
        payload[:result] = result
      end
      send_message(payload)
    end

    def send_notification(method, params)
      send_message({ jsonrpc: '2.0', method: method, params: params })
    end

    def handle_message(message)
      if message['method']
        handle_request(message)
      end
    end

    def handle_request(message)
      case message['method']
      when 'initialize'
        handle_initialize(message)
      when 'initialized'
        # no-op
      when 'shutdown'
        send_response(message['id'], result: nil)
      when 'exit'
        exit(0)
      when 'textDocument/didOpen'
        handle_did_open(message['params'])
      when 'textDocument/didChange'
        handle_did_change(message['params'])
      when 'textDocument/didClose'
        handle_did_close(message['params'])
      when 'textDocument/formatting'
        handle_formatting(message)
      when 'textDocument/completion'
        handle_completion(message)
      when 'workspace/didChangeConfiguration'
        handle_config_change(message['params'])
      else
        # ignore
      end
    end

    def handle_initialize(message)
      params = message['params'] || {}
      root_uri = params['rootUri'] || params['rootPath']
      @workspace_root = uri_to_path(root_uri) if root_uri
      @formatter = Formatter.new(config: @config, workspace_root: @workspace_root)

      if params['initializationOptions'].is_a?(Hash)
        merge_config(params['initializationOptions'])
      end

      result = {
        serverInfo: {
          name: 'slim-lsp',
          version: SlimLsp::VERSION
        },
        capabilities: {
          textDocumentSync: {
            openClose: true,
            change: 1
          },
          completionProvider: {
            resolveProvider: false,
            triggerCharacters: ['.', '#', '=', '"', "'"]
          },
          documentFormattingProvider: true
        }
      }

      send_response(message['id'], result: result)
    end

    def handle_did_open(params)
      uri = params.dig('textDocument', 'uri')
      text = params.dig('textDocument', 'text')
      return unless uri && text

      @documents[uri] = text
      publish_diagnostics(uri, text)
    end

    def handle_did_change(params)
      uri = params.dig('textDocument', 'uri')
      changes = params['contentChanges'] || []
      return unless uri && !changes.empty?

      text = changes.last['text']
      return unless text

      @documents[uri] = text
      publish_diagnostics(uri, text)
    end

    def handle_did_close(params)
      uri = params.dig('textDocument', 'uri')
      @documents.delete(uri) if uri
      send_notification('textDocument/publishDiagnostics', { uri: uri, diagnostics: [] }) if uri
    end

    def handle_formatting(message)
      params = message['params'] || {}
      uri = params.dig('textDocument', 'uri')
      text = @documents[uri]
      return send_response(message['id'], result: []) unless uri && text

      formatted = format_text(text)
      if formatted == text
        send_response(message['id'], result: [])
        return
      end

      lines = text.split("\n", -1)
      edit = {
        range: {
          start: { line: 0, character: 0 },
          end: { line: lines.length, character: 0 }
        },
        newText: formatted
      }
      send_response(message['id'], result: [edit])
    end

    def handle_completion(message)
      return send_response(message['id'], result: { isIncomplete: false, items: [] }) unless @config.dig('completion', 'enabled')

      items = []
      HTML_TAGS.each do |tag|
        items << { label: tag, kind: 10 }
      end
      SLIM_KEYWORDS.each do |keyword|
        items << { label: keyword, kind: 14 }
      end

      send_response(message['id'], result: { isIncomplete: false, items: items })
    end

    def handle_config_change(params)
      settings = params['settings'] || {}
      merge_config(settings)
    end

    def merge_config(update)
      deep_merge!(@config, update)
    end

    def deep_merge!(target, update)
      update.each do |key, value|
        if value.is_a?(Hash) && target[key].is_a?(Hash)
          deep_merge!(target[key], value)
        else
          target[key] = value
        end
      end
    end

    def publish_diagnostics(uri, text)
      diagnostics = parse_diagnostics(text)
      diagnostics.concat(slim_lint_diagnostics(uri, text))
      send_notification('textDocument/publishDiagnostics', { uri: uri, diagnostics: diagnostics })
    end

    def parse_diagnostics(text)
      Slim::Engine.new.call(text)
      []
    rescue StandardError => e
      message, line, column = parse_error_location(e)
      [{
        range: {
          start: { line: line, character: column },
          end: { line: line, character: column + 1 }
        },
        severity: 1,
        source: 'slim',
        message: message
      }]
    end

    def slim_lint_diagnostics(uri, text)
      return [] unless @config.dig('lint', 'enabled')

      path = uri_to_path(uri)
      return [] unless path && !path.empty?

      runner = SlimLsp::SlimLintRunner.new(
        config: @config['lint'],
        workspace_root: @workspace_root,
        io_err: $stderr
      )

      runner.run(path, text)
    end

    def parse_error_location(error)
      message = error.message.to_s
      line = 0
      column = 0

      if (match = message.match(/Line\s+(\d+)/i))
        line = match[1].to_i - 1
      elsif (match = message.match(/line\s+(\d+)/i))
        line = match[1].to_i - 1
      end

      if (match = message.match(/Column\s+(\d+)/i))
        column = match[1].to_i - 1
      elsif (match = message.match(/column\s+(\d+)/i))
        column = match[1].to_i - 1
      end

      [message, [line, 0].max, [column, 0].max]
    end

    def format_text(text)
      @formatter.format(text)
    end

    def uri_to_path(uri)
      return uri unless uri.start_with?('file://')

      uri.sub('file://', '')
    end
  end
end
