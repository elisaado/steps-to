require 'sinatra'

dev = ARGV[0] == "dev"
require "sinatra/reloader" if dev

set :strict_paths, false
set :show_exceptions, false if dev

puts "Dev mode!" if dev

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

guides.sort_by!{|g| g[:name].downcase}

guide_list = {}

guides.each do |guide|
  first_letter = guide[:name][0]
  guide_list[first_letter] ||= []

  guide_list[first_letter].push guide
end # this can be done more, eh, better

get '/' do
  @title = "Home"
  @guides = guide_list
  @body = :index

  erb :main
end

get '/guides/:guide' do
  @guide = guides.find do |guide|
    params[:guide] == guide[:name]
  end

  @title = @guide[:name]
  @body = :guide
  return "Guide not found!" if @guide == [] || @guide == nil
  
  erb :main
end

get '/search/:term' do
  @results = []

  @title = "Search \"#{params[:term]}\""
  @body = :search

  guides.each do |guide|
    @results.push guide if /#{params[:term].downcase}/.match guide[:name]
  end

  erb :main
end

error 404 do
  @error = 404

  status @error

  @title = "Not found (#{@error})"
  @body = :error
  @desc = "This page could not be found"
  erb :main
end
