# I wrote this code at 00:14 Christmas day so...
# By Eli Saado and contributors

require 'net/http'
require 'json'

pid = fork do
  exec "ruby main.rb #{ARGV[0]}"
end

last_sha = JSON.parse(Net::HTTP.get(URI("https://api.github.com/repos/elisaado/steps-to/commits")))[0]["sha"]
old_last_sha = last_sha

loop do
  sleep 10
  last_sha = JSON.parse(Net::HTTP.get(URI("https://api.github.com/repos/elisaado/steps-to/commits")))[0]["sha"]
  old_last_sha = last_sha

  if old_last_sha == last_sha
    next
  else
    puts "Restarting..."
    Process.kill "TERM", pid
    Process.wait pid
    `git pull`
    pid = fork do
      exec "ruby main.rb #{ARGV[0]}"
    end
  end
end