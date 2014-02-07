namespace :import do
  desc "imports les miserables into neo4j"
  task data: :environment do
  	neo = Neography::Rest.new

  	empty_graph neo
  	previous = nil
  	index = 0
  	File.read("lib/miserables.txt").split.map{|w| clean_up w}.select(&:present?).each do |word| 
  		capture neo, word, previous
  		previous = word
  		index = index + 1
  		# puts "#{index}" #if index % 100 == 0
  		puts word
  	end
  end

end

def empty_graph(neo)
	neo.execute_query 'MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n, r'
	neo.execute_query 'CREATE CONSTRAINT ON (w:Word) ASSERT w.text IS UNIQUE;'

end

def clean_up(word)
	word \
		.strip
		.downcase
		.gsub(/([!_\.\,\?;"])/, '')
		.gsub(/^([a-z]{1}')/, '')
end

def capture(neo, word, previous)
	neo.execute_query %{ MERGE (w:Word {text: "#{word}"}) 
											 ON CREATE SET w.count = 1
											 ON MATCH SET w.count = w.count + 1
											 RETURN w }

	neo.execute_query %{ MATCH (w1:Word {text: "#{previous}"}), (w2:Word {text: "#{word}"})
											 MERGE (w1)-[r:followed_by]->(w2)
											 ON CREATE SET r.count = 1
											 ON MATCH SET r.count = r.count + 1
											 RETURN w1, w2, r}
end

def capture_old(neo, word, previous)
	node = neo.find_nodes_labeled("Word", {text: word}).first
	if node.nil?
		node = neo.create_node text: word, count: 1
		neo.set_label node, 'Word'
	else
		neo.set_node_properties(node, {count: node['data']['count'] + 1}) 
	end

	if previous.present?
		previous_node = neo.find_nodes_labeled("Word", {text: previous}).first
		relationship = neo.get_node_relationships(previous_node, "out")
		puts "-> #{relationship}"
		if relationship.nil?
			relationship = neo.create_relationship "followed_by", previous_node, node
			neo.set_relationship_properties relationship, {count: 1}
		else
			prop = neo.get_relationship_properties(relationship, ["count"])
			neo.set_relationship_properties relationship, {count: prop['count'] + 1}
		end
	end

end


