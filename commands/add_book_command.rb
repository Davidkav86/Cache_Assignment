require_relative 'user_command'

class AddBookCommand < UserCommand

	def initialize (data_source)
		super (data_source)
		@isbn  = ''
        @title = ''
        @price = ''
        @author = ''
        @genre = ''
        @quantity = ''
	end

	def title 
		'Add Book. '
	end

	def input
   	   puts 'Add Book.'
	   print "Book ISBN: "   
	   @isbn = STDIN.gets.chomp  
	   print"Book title: "
	   @title = STDIN.gets.chomp
	   print"Book author: "
	   @author = STDIN.gets.chomp
	   puts "Book Genre: "
       $GENRE.each_index {|i| print " (#{i+1}) #{$GENRE[i]} "}
       print ' ? '
       response = STDIN.gets.chomp.to_i 
       @genre = $GENRE[response - 1] if (1..$GENRE.length).member? response
	   print"Book price: "
	   @price = STDIN.gets.chomp
	   print"Book quantity: "
	   @quantity = STDIN.gets.chomp
    end

    def execute
       book = BookInStock.new(@isbn,@title,@author,@genre,@price,@quantity)

       @data_source.addBook(book)
	end



end