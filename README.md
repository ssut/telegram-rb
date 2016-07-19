# Telegram API for Ruby!

[![DUB](https://img.shields.io/dub/l/vibe-d.svg)](http://opensource.org/licenses/MIT)
[![Gem Version](https://badge.fury.io/rb/telegram-rb.svg)](http://badge.fury.io/rb/telegram-rb)
[![Code Climate](https://codeclimate.com/github/ssut/telegram-rb/badges/gpa.svg)](https://codeclimate.com/github/ssut/telegram-rb)
[![Inline docs](http://inch-ci.org/github/ssut/telegram-rb.svg?branch=master)](http://inch-ci.org/github/ssut/telegram-rb)

[![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/ssut/telegram-rb?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

A Ruby wrapper that communicates with the [Telegram-CLI](https://github.com/vysheng/tg).

## Installation

### Requirements

* You need to install the [Telegram-CLI](https://github.com/vysheng/tg) first.

### RubyGems

In order to use the telegram-rb you will need to install the gem (either manually or using Bundler), and require the library in your Ruby application:

```bash
$ gem install telegram-rb
```

or in your `Gemfile`: 

```ruby
# latest stable
gem 'telegram-rb', require: 'telegram'

# or track master repo
gem 'telegram-rb', github: 'ssut/telegram-rb', require: 'telegram'
```

## Usage

The library uses EventMachine, so the logic is wrapped in `EM.run`.

```ruby
# When using Bundler, let it load all libraries
require 'bundler' 
Bundler.require(:default) 

# Otherwise, require 'telegram', which will load its dependencies
# require 'telegram'

EM.run do
  telegram = Telegram::Client.new do |cfg|
    cfg.daemon = '/path/to/tg/bin/telegram-cli'
    cfg.key = '/path/to/tg/tg-server.pub'
    cfg.profile = 'user2' # optional, the profiles must be configured in ~/.telegram-cli/config
  end

  telegram.connect do
    # This block will be executed when initialized.
    
    # See your telegram profile
    puts telegram.profile

    telegram.contacts.each do |contact|
      puts contact
    end
    
    telegram.chats.each do |chat|
      puts chat
    end
    
    # Event listeners
    # When you've received a message:
    telegram.on[Telegram::EventType::RECEIVE_MESSAGE] = Proc.new do |event|
      # `tgmessage` is TelegramMessage instance
      puts event.tgmessage
    end 

    # When you've sent a message:
    telegram.on[Telegram::EventType::SEND_MESSAGE] = Proc.new do |event|
      puts event
    end
  end
end
```

### Documentation

**You can check documentation from [here](http://www.rubydoc.info/github/ssut/telegram-rb)!**

My goal is to have the code fully documentated for the project, so developers can use this library easily!

## Coverage (TODO)

- [ ] Messaging/Multimedia
    - [x] Send typing signal to specific user or chat
    - [x] Send a message to specific user or chat 
    - [x] Send an image to specific user or chat
    - [x] Send a video to specific user or chat
    - [ ] Download an image of someone sent
    - [ ] Forward a message to specific user
    - [ ] Mark as read all received messages
    - [ ] Set profile picture
- [ ] Group chat options
    - [x] Add a user to the group
    - [x] Remove a user from the group
    - [x] Leave from the group
    - [x] Create a new group chat
    - [ ] Set group chat photo
    - [ ] Rename group chat title
- [ ] Search
    - [ ] Search for specific message from a conversation
    - [ ] Search for specific message from all conversions
- [ ] Secret chat
    - [x] Reply message in secret chat
    - [ ] Visualize of encryption key of the secret chat
    - [ ] Create a new secret chat
- [ ] Stats and various info
    - [x] Get user profile
    - [x] Get chat list
    - [x] Get contact list
    - [ ] Get history and mark it as read
- [ ] Card
    - [ ] export card
    - [ ] import card

## Contributing

If there are bugs or things you would like to improve, fork the project, and implement your awesome feature or patch in its own branch, then send me a pull request here!

## License

**telegram-rb** is licensed under the MIT License.

```
The MIT License (MIT)

Copyright (c) 2015 SuHun Han

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
