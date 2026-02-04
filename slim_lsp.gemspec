# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = 'slim_lsp'
  spec.version = '0.1.0.pre.1'
  spec.authors = ['Wiktor Rojecki']
  spec.email = ['wixaxis@users.noreply.github.com']

  spec.summary = 'LSP server for Slim templates'
  spec.description = 'Slim LSP provides diagnostics, completions, and Tailwind class sorting for Slim templates.'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1'

  spec.files = Dir.glob('{bin,lib,docs,scripts}/**/*', File::FNM_DOTMATCH).reject do |path|
    path.end_with?('/.') || path.end_with?('/..') || path.include?('/.git')
  end
  spec.bindir = 'bin'
  spec.executables = ['slim-lsp']
  spec.require_paths = ['lib']

  spec.add_dependency 'slim', '>= 5.2'
end
