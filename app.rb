require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/flash'
require 'omniauth-github'

require_relative 'config/application'

helpers do
  def current_user
    if @current_user.nil? && session[:user_id]
      @current_user = User.find_by(id: session[:user_id])
      session[:user_id] = nil unless @current_user
    end
    @current_user
  end

  def signed_in?
    current_user.present?
  end
end




get '/' do
  erb :index
end

get '/auth/github/callback' do
  user = User.find_or_create_from_omniauth(env['omniauth.auth'])
  session[:user_id] = user.id
  flash[:notice] = "You're now signed in as #{user.username}!"

  redirect '/'
end

get '/sign_out' do
  session[:user_id] = nil
  flash[:notice] = "You have been signed out."

  redirect '/'
end

get '/meetups' do
  @meetups = Meetup.all.order(:name)
  erb :'meetups/index'
end

get '/meetups/:id' do
  @meetup = Meetup.find(params[:id])
  erb :'meetups/show'
end

post '/search' do
  name = params['name']
  description = params['description']
  location = params['location']

  @results = Meetup.all.where("name like ? and description like ? and location like ?", "%#{name}%", "%#{description}%", "%#{location}%").order(:name)
  erb :search
end

get '/create' do
  erb :'meetups/new'
end

post '/create' do
  @current_meetup = Meetup.new(name: params[:name], location: params[:location], description: params[:description])
  @id = @current_meetup.id

  if current_user
    if @current_meetup.name != "" && @current_meetup.description != "" && @current_meetup.location != ""
      @current_meetup.save
      @id = Meetup.last.id
      redirect "/meetups/#{@id}"
    else
      flash[:notice] = "Please complete all fields!"
      redirect "/create"
    end
  end
end
