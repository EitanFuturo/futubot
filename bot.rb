require 'socket'
require 'byebug'
require 'dotenv/load'
require "google/cloud/translate"

TWITCH_HOST = "irc.chat.twitch.tv"
TWITCH_PORT = 6667

class TwitchBot
  def initialize
    @nickname = ENV['TWITCH_USER']
    @password = ENV['TWITCH_PASSWORD']
    @channel = ENV['TWITCH_CHANNEL']
    @socket = TCPSocket.open(TWITCH_HOST, TWITCH_PORT)
    @api_project_id = ENV['TRANSLATE_ID']

    write_to_system "PASS #{@password}"
    write_to_system "NICK #{@nickname}"
    write_to_system "JOIN ##{@channel}"
  end

  def write_to_system(message)
    @socket.puts message
  end

  def write_to_chat(message)
    write_to_system "PRIVMSG ##{@channel} :#{message}"
  end

  def run
    until @socket.eof? do
      message = @socket.gets
      puts message

      case message
      when /^PING :(.*)$/
        write_to_system "PONG #{$~[1]}"
        next
      when /PRIVMSG ##{@channel} :(.*)$/
        content = $~[1]
        username = message.match(/@(.*).tmi.twitch.tv/)[1]

        if content.include? "!!hola"
          write_to_chat "hola #{username}"
        end

        if content.include? "!!give"
          write_to_chat "!props"
        end

        if content.include? "!!translate"
          content.slice! "!!translate"
          text = content.slice! /(["'])(?:(?=(\\?))\2.)*?\1/
          text = text.force_encoding('UTF-8') if text
          text.gsub!("\"", "").encode!('UTF-8', invalid: :replace, undef: :replace, replace: '🤷') if text
          lang = content.strip!

          translate = Google::Cloud::Translate.translation_v2_service project_id: @api_project_id
          begin
            translation = translate.translate text, to: lang
            write_to_chat "#{username} translated: #{text} to: #{translation.text.inspect} from: #{translation.from} to: #{translation.to}"
          rescue 
            write_to_chat "#{username} try this format: !!translate \"some text between double quotes\" lang_code (i.e.: en)"
          end
        end
        
      end
    end
  end

  def quit
    write_to_system "PART ##{@channel}"
    write_to_system "QUIT"
  end
end

bot = TwitchBot.new
bot.run
