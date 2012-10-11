# This class defines how the app interacts with Zendesk. There are very few
# things we really need to do besides retrieve tickets.
require 'httparty'
require 'json'

class Zendesk
  include HTTParty
  base_uri Zendesk::BASE_URI

  def initialize(u, p)
    @auth = {:username => u, :password => p}
  end

  # ## ticket(string "1979")
  # returns the complete ticket hash
  def ticket(id, options={})
    options.merge!({:basic_auth => @auth})
    JSON::parse(self.class.get("/tickets/#{id}.json", options).body)
  end

  # ## tickets_all()
  # returns an array of all tickets updated in the last 24 hours
  # as defined by Zendesk View Z_RECENT_VIEW
  def tickets_all(options={})
    options.merge!({:basic_auth => @auth})
    JSON::parse(self.class.get(Z_RECENT_VIEW, options).body)
  end

  # ## org_name(string "22356783")
  # Returns either the name of organization identified by organization_id or
  # "No Org" if no such organization exists (or organization_id is not passed)
  def org_name(organization_id, options={})
    options.merge!({:basic_auth => @auth})
    begin
      org = JSON::parse(self.class.get("/organizations/#{organization_id}.json", options).body)
    rescue JSON::ParserError => e
      org = { "name" => "No Org" }
    end
    org["name"]
  end

  # ## who_touched(string "1979")
  # Returns a hash of agents who have updated the Zendesk Ticket with id number
  #
  # WIP
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

  # ## who_is(string "289470191")
  # Returns an array of information about Zendesk user author_id  
  # [ username, user role id]
  #
  #     Role          value
  #     End user      0
  #     Administrator 2
  #     Agent         4
  def who_is(author_id, options={})
    options.merge!({:basic_auth => @auth})
    user = JSON::parse(self.class.get("/users/#{author_id}.json", options).body)
    return [ user["name"], user["roles"] ]
  end


  # ## status(int "1")
  # Returns an array with  
  # [ Local status name, [ array of one or more Trello ids of lists that
  # correspond to this status] ]
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

