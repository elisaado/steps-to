require 'sinatra'
require "sinatra/reloader"

set :strict_paths, false

def guideparser(path)
  name = "#{path}" # hack
  name[0..6] = ''

  puts "Parsing: #{name}, #{path}"
  
  content = File.read(path)
  content = content.split("\n")
  
  title = content[1] if content[0] == "#t"
  steps_raw = content[4..-1] if content[3] == "#s"
  steps = []
  
  steps_raw.each do |step|
    steps.push step and next if step[0] == " " # hack 
    steps.push step.gsub(/(\d+)\. /, '')
  end
  
  return {title: title, steps: steps, name: name, path: path}
end

guides = []

puts "Loading stepfiles..."
Dir.foreach('guides/') do |filename|
  next if filename == '.' || filename == '..'

  puts "Loading: #{filename}"
  
  guides.push guideparser("guides/#{filename}")
end

get '/' do
  erb :index
end

get '/guides' do
  @guides = guides
  erb :guide_list
end

get '/guides/:guide' do
  guide = nil

  guides.each do |guide_obj|
    guide = guide_obj if params[:guide] == guide_obj[:name]
  end
  
  return "Guide not found!" if guide == nil
  
  @guide = guide
  erb :guide
end
