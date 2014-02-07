class Word < Neo

	attr_reader :node
  
  def initialize(node)
  	@node = node
  end

  def followed_by(other_word, count=1)
  	neo.create_relationship "followed_by", @node, other_word.node, {count: count}
  end

  def self.create!(text)
  	node = neo.create_node text: text, count: 1
		neo.set_label node, 'Word'
		new node
  end
end

