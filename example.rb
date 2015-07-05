# encoding: utf-8
lib = File.join(File.dirname(__FILE__), 'lib')
$:.unshift lib unless $:.include?(lib)

require 'eventmachine'
require 'telegram'

EM.run do
  telegram = Telegram::Client.new do |cfg|
    cfg.daemon = './telegram-cli'
    cfg.key = '/Users/ssut/tmp/tg/tg-server.pub'
  end

  telegram.connect do
    puts telegram.profile
    telegram.contacts.each do |contact|
      puts contact
    end
    telegram.chats.each do |chat|
      puts chat
    end
    
    telegram.on[Telegram::EventType::RECEIVE_MESSAGE] = Proc.new { |ev|
      
    }

  end
end
