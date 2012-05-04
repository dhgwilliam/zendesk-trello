require 'sinatra'
require 'trello'
require 'json'
require 'haml'
require './config.rb'

include Trello


get '/' do
  @user = Member.find("me")
  @boards = @user.boards
  "<a href=\"/user/#{@user.id}\">#{@user.full_name}</a><br /> <a href=\"/board/#{@boards.first.id}\">#{@boards.first.name}</a>"
end

get '/user/:user' do
  @user = Member.find(params[:user])
  "<img src=\"#{@user.avatar_url}\" /><br />#{@user.full_name}"
end

get '/board/:board' do
  @board = Board.find(params[:board])
  @cards = {}
  @board.cards.each { |card| @cards[card.id] = card.name}
  "#{@cards}"
end

get '/card/:card' do
  @card = Card.find(params[:card])
  "#{@card.name}"
end


