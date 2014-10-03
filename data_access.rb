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

      if @Remote_cache.get("v_#{isbn}") == nil
        
         book = @database.findISBN isbn

         @Remote_cache.set "v_#{isbn}",1      # Create the version entry 
         @Remote_cache.set "1_#{isbn}", book.to_cache # Create the book entry

         print " Cache set"
      else
         checkRemoteCache isbn
      end
       
    end

    def authorSearch(author)
       @database.authorSearch author
    end

    def updateBook book
       @database.updateBook book
    end

    def addBook book
       @database.addBook book
    end

    def deleteBook isbn
       @database.deleteBook isbn
    end

    def checkRemoteCache isbn
      
       # get the current version of the book
       version = @Remote_cache.get "v_#{isbn}"
      
       # get the correct version of the book     
       serial = @Remote_cache.get "#{version}_#{isbn}"
       # create a new BookInStock object by passing the serial string into the from_cache method
       book = BookInStock.from_cache serial
     
       # increment the version of the book and the version entry
       @Remote_cache.set "#{version + 1}_#{book.isbn}", book.to_cache
       @Remote_cache.set "v_#{book.isbn}",version+1

       
       print " Version = #{version + 1}"
       puts book
    end
end



  
