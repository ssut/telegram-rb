lib = File.join(File.dirname(__FILE__), 'lib')
$:.unshift lib unless $:.include?(lib)

require 'telegram/version'

Gem::Specification.new do |s|
  s.date        = Date.today.to_s
  s.name        = 'telegram-rb'
  s.version     = Telegram::VERSION
  s.licenses    = ['MIT']
  s.summary     = 'A Ruby wrapper that communicates with the telegram-cli.'
  s.description = "A Ruby wrapper that communicates with the telegram-cli."
  s.authors     = ["SuHun Han (ssut)"]
  s.email       = 'ssut@ssut.me'
  s.files       = `git ls-files`.split("\n")
  s.homepage    = 'https://github.com/ssut/telegram-rb'

  s.add_dependency('eventmachine')
  s.add_dependency('em-synchrony')
  s.add_dependency('em-http-request')
  s.add_dependency('activesupport')
  s.add_dependency('fastimage')
  s.add_dependency('oj')

  s.add_development_dependency('rubysl-irb')
  s.add_development_dependency('yard')
  s.add_development_dependency('ruby-prof')
end
