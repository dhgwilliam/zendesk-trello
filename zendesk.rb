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

  def status(status_id)
    case status_id
    when 0
      @status = "New"
    when 1
      @status = "Open"
    when 2
      @status = "Pending"
    when 3
      @status = "Solved"
    when 4
      @status = "Closed"
    else
      @status = "Unknown"
    end

  end
end

