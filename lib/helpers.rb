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
    changed = false
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
      new_name = "##{zendesk_id} - #{Z.org_name(@zticket["organization_id"])} - #{@zticket["current_tags"]}"
      unless new_name == issue.oname
        changed = true
      end
      issue.update(:status => @zticket["status_id"],
                    :oname => new_name)
      @ocard.name = issue.oname
      unless @lists.include?(issue.list.trello_id)
        issue.update(:list => List.with(:trello_id, @lists.first))
        @ocard.list_id = issue.list.trello_id
        changed = true
      end
      if changed
        @ocard.save
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

