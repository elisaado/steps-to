require 'sinatra'
require "sinatra/reloader"

set :strict_paths, false

def guideparser(path)
  name = path[7..-1]

  puts "Parsing: #{name}"
  
  content = File.read(path)
  guide_raw = content.split("\n")
  
  title = guide_raw[1] if guide_raw[0] == "#t"
  steps_raw = guide_raw[4..-1] if guide_raw[3] == "#s"
  steps = []
  
  steps_raw.each do |step|
    steps.push step and next if step[0] == " "
    steps.push step.gsub(/(\d+)\. /, '')
  end
  
  return {title: title, steps: steps, name: name, path: path}
end

guides = []

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
  @guide = guides.find do |guide|
    params[:guide] == guide[:name]
  end

  return "Guide not found!" if @guide == [] || @guide == nil
  
  erb :guide
end
