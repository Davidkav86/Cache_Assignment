require_relative 'user_command'

class DeleteBookCommand < UserCommand

	def initialize (data_source)
		super (data_source)
		@isbn  = ''
		@userInput = ''
   
	end

	def title 
		'Delete Book. '
	end

	def input
   	   puts 'Delete Book.'

   	   print "Book ISBN: "   
	   @isbn = STDIN.gets.chomp 
	   print "The ISBN you entered is #{@isbn} \n"
	   print "Are you sure you want to delete this book? (yes/no) \n"
	   @userInput = STDIN.gets.chomp

    end

    def execute

	   if @userInput[0] == "y"
	   	 @data_source.deleteBook @isbn

	   else
	   	print "You have chosen not to delete the book" 
	   end

	end



end