require 'socket'
require 'byebug'
require 'dotenv/load'

TWITCH_HOST = "irc.chat.twitch.tv"
TWITCH_PORT = 6667

class TwitchBot
  
  def initialize
    @nickname = "futubot"
    @password = ENV['TWITCH_PASSWORD']
    @channel = "beginbot"
    @socket = TCPSocket.open(TWITCH_HOST, TWITCH_PORT)
    
    write_to_system "PASS #{@password}"
    write_to_system "NICK #{@nickname}"
    write_to_system "JOIN #{@channel}"
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

      if message.match(/PRIVMSG ##{@channel} :(.*)$/)
        content = $~[1]
        username = message.match(/@(.*).tmi.twitch.tv/)[1]
        
        if content.include? "hola"
          write_to_chat "hola #{username}"
        end

        puts "new message"
        puts "#{content} #{username}"
      end
    end

  end
end

#bot = TwitchBot.new
#bot.run

