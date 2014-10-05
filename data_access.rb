require_relative 'book_in_stock'
require_relative 'database'
require 'dalli'

  class DataAccess 
  
    def initialize db_path
       @database = DataBase.new db_path
       @Remote_cache = Dalli::Client.new('localhost:11211')
       # Relevant data structure(s) for local cache
    end
    
    def start 
    	 @database.start 
    end

    def stop
    end

    def findISBN isbn

      # If there is no entry stored in the remote cache with the ISBN
      if @Remote_cache.get("v_#{isbn}") == nil
        
        # Test to make sure that a valid ISBN has been entered
        # This will prevent the program from crashing if an invalid ISBN has been entered
        if @database.findISBN isbn

           book = @database.findISBN isbn
           # Create the version entry 
           @Remote_cache.set "v_#{isbn}",1 
           # Create the book entry
           @Remote_cache.set "1_#{isbn}", book.to_cache 

           print " Cache set... \n" # for testing
           book

        else
          
        end


      else
         getFromRemoteCache isbn
      end
       
    end

    def authorSearch(author)

      @database.authorSearch author

       # if @Remote_cache.get("v_#{isbn}") == nil
        
       #   book = @database.findISBN isbn

       #   @Remote_cache.set "v_#{isbn}",1    
       #   @Remote_cache.set "1_#{isbn}", book.to_cache 

       #   print " Cache set... \n"
       #   puts book
       # end
    end

    def updateBook book
        # update the book in the database
        updatedBook = @database.updateBook book

       # If there is no entry stored in the remote cache
       if @Remote_cache.get("v_#{updatedBook.isbn}") == nil
        
         # Create the version entry 
         @Remote_cache.set "v_#{updatedBook.isbn}",1 
         # Create the book entry
         @Remote_cache.set "1_#{updatedBook.isbn}", updateBook.to_cache 

         puts "#{updatedBook.title}, by #{updatedBook.author} with ISBN #{updatedBook.isbn} has been updated"

       else
         # find the current version of the updated book
         version = @Remote_cache.get "v_#{updatedBook.isbn}"
     
         # increment the version of the updated book and save the updates with it
         @Remote_cache.set "#{version + 1}_#{updatedBook.isbn}", updatedBook.to_cache
         @Remote_cache.set "v_#{updatedBook.isbn}",version+1

         puts "#{updatedBook.title}, by #{updatedBook.author} with ISBN #{updatedBook.isbn} has been updated"
      end
      
    end

    def addBook book
       @database.addBook book
    end

    def deleteBook isbn
     
       @database.deleteBook isbn

       if @Remote_cache.get("v_#{isbn}") == nil
          puts "Book has been deleted from database"
       else
          version = @Remote_cache.get "v_#{isbn}"

          @Remote_cache.delete "v_#{isbn}"
          @Remote_cache.delete "#{version}_#{isbn}"

          puts "Book was deleted from database and remote cache"

       end
    end

    def checkRemoteCache isbn
      
       # find the current version of the book
       version = @Remote_cache.get "v_#{isbn}"
      
       # use the version number to get the correct version of the book     
       serial = @Remote_cache.get "#{version}_#{isbn}"
       # create a new BookInStock object by passing the serial string into the from_cache method
       book = BookInStock.from_cache serial
     
       # increment the version of the book and the version entry
       @Remote_cache.set "#{version + 1}_#{book.isbn}", book.to_cache
       @Remote_cache.set "v_#{book.isbn}",version+1

       puts " Version = #{version + 1}"

       book
    end

    #
    # Retrieves a book from the remote cache using the ISBN
    #
    def getFromRemoteCache isbn

       # find the current version of the book
       version = @Remote_cache.get "v_#{isbn}"
      
       # use the version number to get the correct version of the book     
       serial = @Remote_cache.get "#{version}_#{isbn}"
       # create a new BookInStock object by passing the serial string into the from_cache method
       book = BookInStock.from_cache serial

       book

    end
end



  
