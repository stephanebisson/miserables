class PhraseController < ApplicationController
  def next
  	neo = Neography::Rest.new
  	word = params[:word]
  	result = neo.execute_query %{MATCH (w1:Word {text:"#{word}"})-[r:followed_by]->(w2:Word) RETURN w2.text ORDER BY r.count DESC LIMIT 7}
  	words = result['data'].flatten
  	# render json: result

  	respond_to do |format|
  	  format.html { render json: words }
  	  format.json { render json: words }
  	end
  end

  def index

  end
end
