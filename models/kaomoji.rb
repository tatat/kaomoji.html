class Kaomoji
  include DataMapper::Resource

  property :id, Serial
  property :text, Binary
  property :created_at, DateTime
end