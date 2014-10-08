require_relative 'user_command'

class AuthorSearchCommand < UserCommand

	def initialize (data_source)
		super (data_source)
		@author = ''
		@books = Array.new
	end

	def title 
		'Search by author.'
	end

   def input
   	   puts 'Search by Author.'
	   print "Author mame? "   
	   @author = STDIN.gets.chomp  
   end

    def execute
    	if @data_source.authorSearch(@author) == nil
    		puts "You have entered an invalid author"
    	else
            @data_source.authorSearch(@author).each {|b| puts b }
        end
	end

end