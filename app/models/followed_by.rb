class FollowedBy < ActiveRecord::Base
  belongs_to :word
  belongs_to :word

  include Neoid::Relationship

  neoidable do |c|
    c.relationship start_node: :word, end_node: :word, type: :followed_bys
  end
end