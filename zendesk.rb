require 'httparty'
require 'json'

class Zendesk
  include HTTParty
  base_uri 'https://support.puppetlabs.com'

  def initialize(u, p)
    @auth = {:username => u, :password => p}
  end

  def ticket(id, options={})
    options.merge!({:basic_auth => @auth})
    JSON::parse(self.class.get("/tickets/#{id}.json", options).body)
  end

  def tickets_all(options={})
    options.merge!({:basic_auth => @auth})
    JSON::parse(self.class.get("/rules/73318.json", options).body)
  end

  def org_name(organization_id, options={})
    options.merge!({:basic_auth => @auth})
    org = JSON::parse(self.class.get("/organizations/#{organization_id}.json", options).body)
    org["name"]
  end


  def status(status_id)
    @target_list = []
    case status_id
    when "0"
      @status = "New"
      @target_list << List.with(:name, "Back Log").trello_id
    when "1"
      @status = "Open"
      @target_list = [ List.with(:name, "Active").trello_id, List.with(:name, "Blocked").trello_id]
    when "2"
      @status = "Pending"
      @target_list << List.with(:name, "Pending Client Response").trello_id
    when "3"
      @status = "Solved"
      @target_list = [ List.with(:name, "Complete").trello_id, List.with(:name, "To Be Documented").trello_id ]
    when "4"
      @status = "Closed"
      @target_list = [ List.with(:name, "Complete").trello_id, List.with(:name, "To Be Documented").trello_id ]
    else
      @status = "Unknown"
    end
    return [ @status, @target_list ]
  end
end

