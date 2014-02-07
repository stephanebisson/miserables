class Neo

	def self.destroy_all
		neo.execute_query 'MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n, r'
	end

	def self.neo
		$neo ||= Neography::Rest.new
		$neo
	end

	def neo
		self.class.neo
	end
end