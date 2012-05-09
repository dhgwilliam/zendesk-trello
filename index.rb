require 'sinatra'
require 'trello'
require 'json'
require 'haml'
require 'resque'
require './config.rb'
require './card.rb'
require 'htmlentities'

BOARD = "4f4e8539b7b81632280c9ccf"

get '/' do
  @user = Trello::Member.find("me")
  @boards = @user.boards
  redirect to("/board/#{@boards.first.id}")
end

get '/sync/trello' do
  sync_trello(BOARD)
  redirect to("/board/#{BOARD}")
end

get '/sync/zendesk' do
  Z.tickets_all.each { |ticket| get_issue(ticket["nice_id"]) }
  redirect to("/")
end

get '/board/:trello_id' do
  unless Board.with(:trello_id, params[:trello_id])
    redirect to("/board/new/#{params[:trello_id]}")
  end
  @board = Board.with(:trello_id, params[:trello_id])
  haml :cards
end

get '/board/new/:trello_id' do
  sync_trello(params[:trello_id])
  redirect to("/board/#{params[:trello_id]}")
end

get '/issue/:number' do
  if Issue.with(:number, params[:number]).nil?
    redirect to("/issue/new/zendesk/#{params[:number]}")
  end
  @card = Issue.with(:number, params[:number])
  @status = Z.status(@card.status).first
  haml :card
end

get '/issue/new/zendesk/:number' do
  @issue = get_issue(params[:number])
  redirect to("/issue/#{params[:number]}")
end

get '/issue/delete/:number' do
  Issue.with(:number, params[:number]).delete
  redirect back
end

get '/list/:list' do
  @list = List.with(:trello_id, params[:list])
  @board = @list.board
  haml :list
end

get '/list/new/:trello_id' do
  get_list(params[:trello_id])
  redirect to("/list/#{params[:trello_id]}")
end

get '/zendesk/:id' do
  coder = HTMLEntities.new
  coder.encode(Z.ticket(params[:id]))
end

helpers do
  def sync_trello(board)
    @oboard = get_board(board)
    @oboard.lists.each { |list| get_list(list.id) }
    @oboard.cards.each { |card| get_card(card.id) }
  end

  def get_board(trello_id)
    @oboard = Trello::Board.find(trello_id)
    if Board.with(:trello_id, trello_id).nil?
      Board.create :name => @oboard.name, :trello_id => @oboard.id
    end
    return @oboard
  end

  def get_list(trello_id)
    @olist = Trello::List.find(trello_id)
    if List.with(:trello_id, trello_id).nil?
      List.create :name => @olist.name, 
        :trello_id => trello_id,
        :board => Board.with(:trello_id, @olist.board_id)
    end
    return @olist
  end

  def get_issue(zendesk_id)
    @zticket = Z.ticket(zendesk_id)
    if Issue.with(:number, zendesk_id).nil?
      issue = Issue.create :number => zendesk_id,
        :oname => "##{zendesk_id} - #{Z.org_name(@zticket["organization_id"])} - #{@zticket["current_tags"]}",
        :list => List.with(:trello_id, Z.status(@zticket["status_id"].to_s).last.first),
        :board => Board.with(:trello_id, BOARD)
      @tcard = Trello::Card.create(:name => issue.oname, :list_id => issue.list.trello_id)
      issue.update(:trello_id => @tcard.id)
    elsif Issue.with(:number, zendesk_id)
      issue = Issue.with(:number, zendesk_id)
      @ocard = Trello::Card.find(issue.trello_id)
      @lists = Z.status(@zticket["status_id"].to_s).last
      puts @lists.inspect
      issue.update(:status => @zticket["status_id"])
      puts Z.status(@zticket["status_id"].to_s).last.first
      unless @lists.include?(issue.list.trello_id)
        issue.update(:list => List.with(:trello_id, @lists.first),
                    :oname => "##{zendesk_id} - #{Z.org_name(@zticket["organization_id"])} - #{@zticket["current_tags"]}")
        card = @ocard.dup
        card.list_id = issue.list.trello_id
        card.name = issue.oname
        card.save
        puts issue.number + " updated"
      end

      # not entirely sure why this is necessary
      @ocard = Trello::Card.find(issue.trello_id)
      issue.update(:list => List.with(:trello_id, @ocard.list_id))

    end
    return issue
  end

  def get_card(trello_id)
    @ocard = Trello::Card.find(trello_id)
    if Issue.with(:trello_id, trello_id).nil? && @ocard.name.scan(/\#[0-9]+/).first
      @number = @ocard.name.scan(/\#[0-9]+/).first.delete("#")
      @zticket = Z.ticket(@number)
      if @ocard.name.scan(/\#[0-9]+/).first && Issue.with(:number, @number).nil?
        Issue.create :number => @number,
          :trello_id => trello_id,
          :timestamp => Time.now.to_i,
          :last_json => @zticket,
          :oname => @ocard.name,
          :zname => @zticket["description"],
          :status => @zticket["status_id"],
          :list => List.with(:trello_id, @ocard.list_id),
          :board => Board.with(:trello_id, @ocard.board_id)
      end
    elsif Issue.with(:trello_id, trello_id)
      @zticket = Z.ticket(Issue.with(:trello_id, trello_id).number)
      @number = @ocard.name.scan(/\#[0-9]+/).first.delete "#"
      @issue = Issue.with(:trello_id, trello_id)
      @issue.update(:oname => @ocard.name,
      :timestamp => Time.now.to_i - 60,
      :last_json => @zticket,
      :status => @zticket["status_id"],
      :number => @number )
      @lists = Z.status(@zticket["status_id"].to_s).last
      unless @lists.include? @issue.list.trello_id
        @issue.update(:list => List.with(:trello_id, @lists.first))
      end
      @tcard = Trello::Card.create(:name => @issue.oname, :list_id => @issue.list.trello_id)
      @issue.update(:trello_id => @tcard.id)
    end
  end
end
