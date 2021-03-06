# Using [Ohm](http://ohm.keyvalue.org/) to model datatypes and store in redis
require 'ohm'

class Issue < Ohm::Model
  attribute :number
  attribute :trello_id
  attribute :oname
  attribute :zname
  attribute :timestamp
  attribute :last_json
  attribute :status

  reference :list, :List
  reference :board, :Board

  reference :user, :User
  collection :user, :User

  unique :number

  index :number
  index :trello_id

  def validate
    assert_present :number
    assert_numeric :number
  end
end

class List < Ohm::Model
  attribute :name
  attribute :trello_id
  attribute :status

  reference :board, :Board
  collection :issues, :Issue

  unique :trello_id
  unique :name

  index :name
  index :trello_id

  def validate
    assert_present :name
  end
end

class Board < Ohm::Model
  attribute :name
  attribute :trello_id

  unique :trello_id
  index :trello_id
  index :name

  collection :lists, :List
  collection :issues, :Issue

  def validate
    assert_present :trello_id
  end
end

class User < Ohm::Model
  attribute :name
  attribute :zendesk_id
  attribute :trello_id

  collection :issues, :Issue
  reference :issues, :Issue
end
