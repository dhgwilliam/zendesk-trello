require 'sinatra'
require 'trello'
require 'json'
require 'haml'
require 'resque'
require './config.rb'
require './card.rb'

get '/' do
  @user = Trello::Member.find("me")
  @boards = @user.boards
  redirect to("/sync?board=#{@boards.first.id}")
end

get '/user/:user' do
  @user = Trello::Member.find(params[:user])
  haml :user
end

get '/sync' do
  @oboard = get_board(params[:board])
  @oboard.lists.each { |list| get_list(list.id) }
  @oboard.cards.each { |card| get_card(card.id) }
  redirect to("/board/#{Board.find(:trello_id => params[:board])}")
end

get '/board/inspect' do
  @user = Trello::Member.find("me")
  @boards = @user.boards

  "#{get_board(@boards.first.id)}"
end

get '/board/:trello_id' do
  unless Board.find(:trello_id => params[:trello_id]).first
    redirect to("/board/new/#{params[:trello_id]}")
  end

  @board = Board.find(:trello_id => params[:trello_id]).first
  @cards = @board.issues
  @lists = @board.lists
  # Trello::Board.find(params[:trello_id]).lists.each { |list| @lists << list }
  haml :cards
end

get '/board/new/:trello_id' do
  get_board(params[:trello_id])
  redirect to("/board/#{params[:trello_id]}")
end


get '/card/:card' do
  unless Issue.find(:trello_id => params[:card]).first
    redirect to("/issue/new/trello/#{params[:card]}?intent=#{request.url}")
  end

  @card = Issue.find(:trello_id => params[:card]).first
  @list = @card.list
  @ticket = @card.last_json
  @status = Z.status(@card.status.to_i)
  haml :card
end

get '/issue/new/trello/:trello_id' do
  redirect to("/card/#{params[:trello_id]}")
end

get '/list/:list' do
  @list = Trello::List.find(params[:list])
  @board = Trello::Board.find(@list.board_id)
  haml :list
end

get '/list/new/:trello_id' do
  get_list(params[:trello_id])
  # redirect to(params[:intent])
  redirect to("/list/#{params[:trello_id]}")
end

get '/zendesk/:ticket' do
  @ticket = Z.ticket(params[:ticket])
  "#{@ticket}"
end

helpers do
  def get_list(trello_id)
    if List.find(:trello_id => trello_id).first.nil?
      @olist = Trello::List.find(trello_id)
      List.create :name => @olist.name, 
        :trello_id => trello_id,
        :board => Board.find(:trello_id => @olist.board_id).first
    end
  end

  def get_board(trello_id)
    @oboard = Trello::Board.find(trello_id)
    unless Board.find(:trello_id => trello_id) then
      @board = Board.create :name => @oboard.name, :trello_id => @oboard.id
    end
    return @oboard
  end

  def get_card(trello_id)
    unless Issue.find(:trello_id => trello_id).first
      @ocard = Trello::Card.find(trello_id)
      if @ocard.name.scan(/\#[0-9]+/).first
        @number = @ocard.name.scan(/\#[0-9]+/).first.delete "#"
        @zticket = Z.ticket(@number)
        get_list(@ocard.list_id)
        get_board(@ocard.board_id)
        @card = Issue.create :number => @number,
          :trello_id => trello_id,
          :timestamp => Time.now.to_i,
          :last_json => @zticket,
          :oname => @ocard.name,
          :zname => @zticket["description"],
          :status => @zticket["status_id"],
          :list => Board.find(:trello_id => @ocard.list_id).first,
          :board => Board.find(:trello_id => @ocard.board_id).first
      end
    end
  end
end
