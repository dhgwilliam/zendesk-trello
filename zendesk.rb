require 'httparty'
require 'json'

class Zendesk
  include HTTParty
  base_uri Zendesk::BASE_URI

  def initialize(u, p)
    @auth = {:username => u, :password => p}
  end

  def ticket(id, options={})
    options.merge!({:basic_auth => @auth})
    JSON::parse(self.class.get("/tickets/#{id}.json", options).body)
  end

  def tickets_all(options={})
    options.merge!({:basic_auth => @auth})
    JSON::parse(self.class.get(Z_RECENT_VIEW, options).body)
  end

  def org_name(organization_id, options={})
    options.merge!({:basic_auth => @auth})
    org = JSON::parse(self.class.get("/organizations/#{organization_id}.json", options).body)
    org["name"]
  end

  def who_touched(number)
    ticket = self.ticket(number)
    comments = ticket["comments"]
    authors = {}
    comments.each do |comment|
      unless authors.has_key?(comment["author_id"])
        authors[comment["author_id"]] ||=  nil
      end
    end
    authors.each_key do |author_id|
      author = self.who_is(author_id)
      if author.last != 0
        authors[author_id] = author.first
      end
    end
    return authors.keep_if{ |k,v| v }
  end

  def who_is(author_id, options={})
    options.merge!({:basic_auth => @auth})
    user = JSON::parse(self.class.get("/users/#{author_id}.json", options).body)
    return [ user["name"], user["roles"] ]
  end


  def status(status_id)
    @target_list = []
    case status_id
    when "0"
      @status = "New"
      @target_list << List.with(:name, BACKLOG_LIST).trello_id
    when "1"
      @status = "Open"
      @target_list = [ List.with(:name, ACTIVE_LIST).trello_id, List.with(:name, BLOCKED_LIST).trello_id]
    when "2"
      @status = "Pending"
      @target_list << List.with(:name, PENDING_LIST).trello_id
    when "3"
      @status = "Solved"
      @target_list = [ List.with(:name, COMPLETE_LIST).trello_id, List.with(:name, TBD_LIST).trello_id ]
    when "4"
      @status = "Closed"
      @target_list = [ List.with(:name, COMPLETE_LIST).trello_id, List.with(:name, TBD_LIST).trello_id ]
    else
      @status = "Unknown"
    end
    return [ @status, @target_list ]
  end
end

