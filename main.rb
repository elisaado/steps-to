require 'sinatra'
require 'json'

set :protection, :except => [:json_csrf]

if ARGV[0] == "dev"
  require "sinatra/reloader"
  puts "Starting in dev mode!"
else
  set :environment, :production
  puts "Starting in production mode!"
end

set :strict_paths, false

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
    if needed[1].match(/\s/)
      needed_stuff.push(needed[2..-1])
    else
      needed_stuff.push(needed[1..-1])
    end
  end

  steps_raw = content.split("#s").drop(1).join("").split("\n").drop(1)
  steps = []
  steps_raw.each do |step|
    steps.push step and next if step[0] == " "
    steps.push step.sub(/(\d+)\. /, '')
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

def jsonResponse(ok: true, error: nil, description: nil, result: nil)
  if ok
    return {ok: true, result: result}.to_json
  else
    return {ok: false, error: error, description: description}.to_json
  end
end

before ['/api', '/api/*'] do
  content_type 'application/json'
end

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
  params[:term].gsub!(/\%20/, ' ')
  @results = []

  @title = "Search \"#{params[:term]}\""
  @body = :search

  guides.each do |guide|
    @results.push guide if /#{params[:term]}/i.match guide[:title]
  end

  erb :main
end

get '/info' do
  @title = "Info"
  @body = :info

  erb :main
end

get '/api' do
  jsonResponse(result: "Welcome to our API! See /api/docs for docs")
end

get '/api/docs' do
  # TODO: write docs
  jsonResponse(result: "Yeah... I still need to write docs")
end

get '/api/guides' do
  jsonResponse(result: guides)
end

get '/api/guides/:name' do
  guide = guides.find do |guide|
    params[:name] == guide[:name]
  end

  if guide.nil?
    return jsonResponse(ok: false, error: 404, description: "Guide not found")
  end
  
  jsonResponse(result: guide)
end

get '/api/guides/search/:term' do
  results = []

  guides.each do |guide|
    results.push guide if /#{params[:term].downcase}/i.match guide[:title]
  end

  jsonResponse(result: results)
end

not_found do
  if request.path_info[0..4] == "/api/" 
    @error = 404
    status @error
    jsonResponse(ok: false, error: 404, description: "Method not found")
  else
    @error = 404
    status @error

    @title = "Not found (#{@error})"
    @body = :error
    @desc = "This page could not be found"
    erb :main
  end
end
