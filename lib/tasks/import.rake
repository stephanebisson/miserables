namespace :import do
  desc "imports les miserables into neo4j"
  task data: :environment do
  	neo = Neography::Rest.new
	  empty_graph neo
	  authors.each do |author|
	  	capture_author neo, author
	  end
  end

  desc "compares different authors"
  task compare: :environment do
  	neo = Neography::Rest.new
	  compare_authors neo, authors[0], authors[1]
	  # authors.combination(2) do |author1, author2|
	  # 	compare_authors author1, author2
	  # end
  end

end

def empty_graph(neo)
	neo.execute_query 'MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n, r'
	neo.execute_query 'CREATE CONSTRAINT ON (w:Word) ASSERT w.text IS UNIQUE;'
	neo.execute_query 'CREATE CONSTRAINT ON (a:Author) ASSERT a.name IS UNIQUE;'
end

def authors
	['maupassant', 'victorhugo', 'flaubert', 'zola']
end

def worth_it(word)
	word.present? && word.length > 1
end

def clean_up(word)
	word \
		.strip
		.downcase
		.gsub(/([!_\.\,\?;"])/, '')
		.gsub(/^([a-z]{1}')/, '')
end

def capture_author(neo, name)
	neo.execute_query %{ MERGE (:Author {name: "#{name}"}) }

	previous = nil
	text = File.read "lib/data/#{name}/sample.txt"
	text.gsub! /\s+.{1}\./, ''
	text.split(/\.\!\?/).each do |sentence|
		words = sentence.split.map{|w| clean_up w}.select{|w| worth_it w}
  	words.each_with_index do |word, index| 
  		first = index == 0
  		last = index == (words.length - 1)
  		capture neo, word, previous, first, last, name
  		previous = word
  	end
  end
end

def capture(neo, word, previous, first, last, author)
	neo.execute_query %{ MERGE (w:Word {text: "#{word}"}) }

	neo.execute_query %{ MATCH (a:Author {name: "#{author}"}), (w:Word {text: "#{word}"})
											 MERGE (a)-[r:uses]->(w)
											 ON CREATE SET r.count = 1, r.starter = #{first ? 1 : 0}, r.ender = #{last ? 1 : 0}
											 ON MATCH SET r.count = r.count + 1, r.starter = r.starter + #{first ? 1 : 0}, r.ender = r.ender + #{last ? 1 : 0} }


	neo.execute_query %{ MATCH (w1:Word {text: "#{previous}"}), (w2:Word {text: "#{word}"})
											 MERGE (w1)-[r:followed_by {author: "#{author}"}]->(w2)
											 ON CREATE SET r.count = 1
											 ON MATCH SET r.count = r.count + 1 }
end

def compare_authors(neo, author1, author2)
	sample = 100
	w1 = top_words neo, author1, sample
	w2 = top_words neo, author2, sample

	score = levenshtein w1, w2
	
	neo.execute_query %{
		match (a1:Author {name: "#{author1}"}), (a2:Author {name: "#{author2}"})
		merge (a1)-[r:similar_to]->(a2)
		on create set r.score = #{score}
		on match set r.score = #{score}
	}

	neo.execute_query %{
		match (a1:Author {name: "#{author1}"}), (a2:Author {name: "#{author2}"})
		merge (a1)<-[r:similar_to]-(a2)
		on create set r.score = #{score}
		on match set r.score = #{score}
	}

end

def top_words(neo, author, limit)
	neo.execute_query(%{ match (a:Author {name: "#{author}"})-[r:uses]->(w:Word) return w.text order by r.count desc limit #{limit} })['data']
end

def levenshtein(first, second)
  matrix = [(0..first.length).to_a]
  (1..second.length).each do |j|
    matrix << [j] + [0] * (first.length)
  end
 
  (1..second.length).each do |i|
    (1..first.length).each do |j|
      if first[j-1] == second[i-1]
        matrix[i][j] = matrix[i-1][j-1]
      else
        matrix[i][j] = [
          matrix[i-1][j],
          matrix[i][j-1],
          matrix[i-1][j-1],
        ].min + 1
      end
    end
  end
  return matrix.last.last
end




