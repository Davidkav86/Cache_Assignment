require_relative 'book_in_stock'
require_relative 'database'
require 'dalli'

  class DataAccess 
  
    def initialize db_path
       @database = DataBase.new db_path
       @Remote_cache = Dalli::Client.new('localhost:11211')
       @local_cache = Hash.new 
    end
    
    def start 
    	 @database.start 
    end

    def stop
    end

    def findISBN isbn
      
       # if there is an entry in the local cache for the isbn
      if @local_cache["v_#{isbn}"] != nil
        
        localVersion = getLocalVersion isbn
        remoteVersion = @Remote_cache.get "v_#{isbn}"

        if  localVersion == remoteVersion
        # get the book and return it
          book = getFromLocalCache isbn
          print "Local cache accesed\n"
          book
        else
          setLocalCache isbn
          book = getFromLocalCache isbn
          book
        end

      # If there is no entry stored in the remote cache with the ISBN
      elsif @Remote_cache.get("v_#{isbn}") == nil

        # Test to make sure that a valid ISBN has been entered
        # This will prevent the program from crashing if an invalid ISBN has been entered
        if @database.findISBN isbn

           book = @database.findISBN isbn
           # create the entry in the remote cache 
           addRemoteCacheEntry book
           # create the entry in the local cache
           addLocalCacheEntry book

           book
        else
          print "An invalid ISBN has been entered"  
        end

      # there is an entry in the remote cache with the ISBN
      else
         # get the book from the remote cache
         book = getFromRemoteCache isbn
         # create the entry in the local cache
         addLocalCacheEntry book

         book
      end
       
    end

    def authorSearch(author)

      @database.authorSearch author
    end

    def updateBook book
        # update the book in the database
        updatedBook = @database.updateBook book

       # If there is no entry stored in the remote cache
       if @Remote_cache.get("v_#{updatedBook.isbn}") == nil

         addRemoteCacheEntry updatedBook

         addLocalCacheEntry updateBook

         puts "#{updatedBook.title}, by #{updatedBook.author} with ISBN - #{updatedBook.isbn} has been updated"

       else
         # update the remote cache
         setRemoteCache updatedBook

         # update the local cache to match the remote
         setLocalCache updatedBook.isbn

         puts "#{updatedBook.title}, by #{updatedBook.author} with ISBN - #{updatedBook.isbn} has been updated"
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
          
           if @local_cache 
             @local_cache.delete "v_#{isbn}"
             @local_cache.delete "#{version}_#{isbn}"
           end

          puts "Book has deleted from database and remote cache"

       end
    end
    
    # adds a book to the local cache
    def addLocalCacheEntry book
      # Create the version entry 
      @local_cache["v_#{book.isbn}"] = 1
      # Create the book entry
      @local_cache["1_#{book.isbn}"] = book.to_cache

      print " Local Cache set... \n" # for testing
    end

    # adds a book to the remote cache
    def addRemoteCacheEntry book
      # Create the version entry 
      @Remote_cache.set "v_#{book.isbn}",1 
      # Create the book entry
      @Remote_cache.set "1_#{book.isbn}", book.to_cache

      print " Remote Cache set... \n" # for testing
    end

    def setRemoteCache book
       # find the current version of the updated book
       version = @Remote_cache.get "v_#{book.isbn}"
     
       # increment the version of the updated book and save the updates with it
       @Remote_cache.set "#{version + 1}_#{book.isbn}", book.to_cache
       @Remote_cache.set "v_#{book.isbn}",version+1
      
    end

    def setLocalCache isbn 
       version = @Remote_cache.get "v_#{isbn}"

       @local_cache["v_#{isbn}"] = version

       book = getFromRemoteCache isbn

       @local_cache.delete("#{version - 1}_#{book.isbn}")

       @local_cache["#{version}_#{book.isbn}"] = book.to_cache

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

    #
    # Retrieves a book from the local cache using the ISBN
    #
    def getFromLocalCache isbn

       # find the current version of the book
       version = getLocalVersion isbn
      
       # use the version number to get the correct version of the book     
       serial = getLocalSerial "#{version}_#{isbn}"

       # create a new BookInStock object by passing the serial string into the from_cache method
       book = BookInStock.from_cache serial

       book

    end

    def getLocalVersion isbn
       @local_cache["v_#{isbn}"] 
    end

    def getLocalSerial key
      @local_cache[key]
    end

    def setComplexData books

      authorKey = "bks_#{books[0].author}"
      authorValue = ""
      version = "!"
      complexKey = "#{books[0].author}"
      complexData = ""

      books.each do |book|
          authorValue += "#{book.isbn},"
          version = @Remote_cache.get "v_#{book.isbn}"
          complexKey += "_#{book.isbn}_#{version}"
          complexData += "#{book.isbn},#{book.title},#{book.author},#{book.genre},#{book.quantity};"

      end


      puts "AuthorKey = #{authorKey} \n"
      puts "AuthorValue = #{authorValue} \n"
      puts "complexKey = #{complexKey} \n"
      puts "complexData = #{complexData}"

      @local_cache[authorKey] = authorValue
      @local_cache[complexKey] = complexData

    end

    def updateComplexData
    end
end



  
