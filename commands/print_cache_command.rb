require_relative 'user_command'

class PrintCacheCommand < UserCommand

	def initialize (data_source)
		super (data_source)
		@input = 0
	end

	def title 
		'Print contents of cache.'
	end

   def input
   	   puts 'Print contents of cache.'
	   print "Print Remote Cache: Enter - 1\n"   
	   print "Print Local Cache: Enter - 2\n"   
	   @input = STDIN.gets.chomp  
   end

    def execute
        @data_source.printCache @input
	end

end