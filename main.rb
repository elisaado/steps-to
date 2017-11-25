require 'sinatra'

dev = ARGV[0] == "dev"
require "sinatra/reloader" if dev

set :strict_paths, false
set :show_exceptions, false if !dev

puts "Starting in dev mode" if dev

def guideparser(path)
  name = path.split('/')[1]

  puts "Parsing: #{name}"

  content = File.read(path)

  title = content.split("#t")[1].split("\n")[1]
  by = content.split("#b")[1].split("\n")[1]

  needed_raw = content.split("#n").drop(1).join("").split("\n").drop(1)
  needed_stuff = []
  needed_raw.each do |needed|
    break if needed[0] != "*"
    needed_stuff.push(needed[2..-1])
  end

  steps_raw = content.split("#s").drop(1).join("").split("\n").drop(1)
  steps = []
  steps_raw.each do |step|
    steps.push step and next if step[0] == " "
    steps.push step.gsub(/(\d+)\. /, '')
  end

  return {title: title, by: by, steps: steps, name: name, path: path, needed_stuff: needed_stuff}
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
  if @guide.to_s.size > 0 && @guide.to_s != "[]"
    @title = @guide[:name]
    @body = :guide

    erb :main
  else
    @error = 404

    status @error

    @title = "Not found (#{@error})"
    @body = :error
    @desc = "This page could not be found"
    erb :main
  end
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

get '/info' do
  @title = "Info"
  @body = :info

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
