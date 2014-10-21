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
      

      if @local_cache["v_#{isbn}"] != nil
        
        localVersion = getLocalVersion isbn
        remoteVersion = @Remote_cache.get "v_#{isbn}"

        if  localVersion == remoteVersion
          book = getFromLocalCache isbn
          print "Local cache accesed\n"
          book
        else
          setLocalCache isbn
          book = getFromLocalCache isbn
          book
        end

      elsif @Remote_cache.get("v_#{isbn}")  == nil

        if @database.findISBN isbn

           book = @database.findISBN isbn 
           addRemoteCacheEntry book
           addLocalCacheEntry book

           book
        else 
        end

      else
         book = getFromRemoteCache isbn
         puts book
         addLocalCacheEntry book

         book
      end
       
    end

    def authorSearch author
      if @local_cache["bks_#{author}"] != nil
          localCacheAuthorSearch author
      
      elsif @Remote_cache.get("bks_#{author}") == nil
          books = @database.authorSearch author

          setComplexData books
          books   
      else
        remoteCacheAuthorSearch author
       end
    end

    def updateBook book
        updatedBook = @database.updateBook book

       if @Remote_cache.get("v_#{updatedBook.isbn}") == nil

         addRemoteCacheEntry updatedBook

         addLocalCacheEntry updateBook

         puts "#{updatedBook.title}, by #{updatedBook.author} with ISBN - #{updatedBook.isbn} has been updated"

       else
         setRemoteCache updatedBook
         setLocalCache updatedBook.isbn

         puts "#{updatedBook.title}, by #{updatedBook.author} with ISBN - #{updatedBook.isbn} has been updated"
      end
      
    end

    def addBook book
       @database.addBook book

       updateComplexData book.author
    end

    def deleteBook isbn
       book = @database.findISBN isbn
       @database.deleteBook isbn
       if @Remote_cache.get("v_#{isbn}") == nil
          puts "Book with ISBN: #{isbn} has been deleted from database"
       else
          version = @Remote_cache.get "v_#{isbn}"
        
          @Remote_cache.delete "v_#{isbn}"
          @Remote_cache.delete "#{version}_#{isbn}"

           if getFromLocalCache isbn != nil
             @local_cache.delete "v_#{isbn}"
             @local_cache.delete "#{version}_#{isbn}"
           end
          puts "Book has with ISBN: #{isbn} deleted from database and relevant caches"
       end

        updateComplexData book.author
    end
    
    def addLocalCacheEntry book
      @local_cache["v_#{book.isbn}"] = 1
      @local_cache["1_#{book.isbn}"] = book.to_cache
    end

    def addRemoteCacheEntry book
      @Remote_cache.set "v_#{book.isbn}",1 
      @Remote_cache.set "1_#{book.isbn}", book.to_cache
    end

    def setRemoteCache book
       version = @Remote_cache.get "v_#{book.isbn}"
       @Remote_cache.set "#{version + 1}_#{book.isbn}", book.to_cache
       @Remote_cache.set "v_#{book.isbn}",version+1
       @Remote_cache.delete "#{version}_#{book.isbn}"   
    end

    def setLocalCache isbn 
       version = @Remote_cache.get "v_#{isbn}"
       @local_cache["v_#{isbn}"] = version
       book = getFromRemoteCache isbn
       @local_cache.delete("#{version - 1}_#{book.isbn}")
       @local_cache["#{version}_#{book.isbn}"] = book.to_cache

    end

    def getFromRemoteCache isbn
       version = @Remote_cache.get "v_#{isbn}"    
       serial = @Remote_cache.get "#{version}_#{isbn}"
       book = BookInStock.from_cache serial

       book
    end

    def getFromLocalCache isbn
       version = getLocalVersion isbn    
       serial = getLocalSerial "#{version}_#{isbn}"

       if serial == nil
        return nil
       end

       book = BookInStock.from_cache serial
       book
    end

    def remoteCacheAuthorSearch author
       authorValue = @Remote_cache.get("bks_#{author}")
        isbnList = authorValue.split(",")
        
        complexKey = "#{author}"
        isbnList.compact.each do |isbn|
          version = @Remote_cache.get "v_#{isbn}"
          if version == nil
            version = "1"
          end
          complexKey += "_#{isbn}_#{version}"
        end
        

        complexData = @Remote_cache.get(complexKey)

        convertComplexDataStringToBookObjects complexData, author
    end
    
    def localCacheAuthorSearch author
       authorValue = getLocalAuthorValue author

        isbnList = authorValue.split(",")
        
        complexKey = "#{author}"

        isbnList.compact.each do |isbn|
          version = @Remote_cache.get "v_#{isbn}"
          if version == nil
            version = "1"
          end
          complexKey += "_#{isbn}_#{version}"
        end
        
        complexData = getLocalComplexData complexKey

        convertComplexDataStringToBookObjects complexData, author
    end
    
    def getLocalVersion isbn
       @local_cache["v_#{isbn}"] 
    end

    def getLocalAuthorValue author
      @local_cache["bks_#{author}"]
    end

    def getLocalComplexData complexKey
      @local_cache[complexKey]
    end

    def getLocalSerial key
      @local_cache[key]
    end

    def setComplexData books
  
      authorKey = "bks_#{books[0].author}"
      authorValue = ""
      version = "1"
      complexKey = "#{books[0].author}"
      complexData = ""

      books.each do |book|
          authorValue += "#{book.isbn},"
          version = @Remote_cache.get "v_#{book.isbn}"
          if version == nil
            version = "1"
          end
          complexKey += "_#{book.isbn}_#{version}"
          complexData += "#{book.isbn},#{book.title},#{book.author},#{book.genre},#{book.quantity},#{book.price};"

      end

      puts "Complex Entity Data = #{complexData}"

      @Remote_cache.set authorKey, authorValue
      @Remote_cache.set complexKey, complexData

      @local_cache[authorKey] = authorValue
      @local_cache[complexKey] = complexData

    end

    def updateComplexData author
        authorValue = @Remote_cache.get("bks_#{author}")
        if authorValue == nil
          return
        end
        isbnList = authorValue.split(",")
        
        complexKey = "#{author}"

        isbnList.compact.each do |isbn|
          version = @Remote_cache.get "v_#{isbn}"
          if version == nil
            version = "1"
          end
          complexKey += "_#{isbn}_#{version}"
        end
        
        @Remote_cache.delete "bks_#{author}"
        @Remote_cache.delete complexKey

        @local_cache.delete "bks_#{author}"
        @local_cache.delete complexKey

        books = @database.authorSearch author
        setComplexData books
        books
    end

    def convertComplexDataStringToBookObjects complexData, author
        if complexData == nil
          books = updateComplexData author
          return books
        end
        
        stringDataList = complexData.split(";")
        books = []

        stringDataList.each do |bookString|

          tempList = bookString.split(",")
          isbn = tempList[0]
          title = tempList[1]
          author = tempList[2]
          genre = tempList[3]
          quantity = tempList[4]
          price = tempList[5]

          book = BookInStock.new(isbn, title, author, genre, price, quantity)
          books << book

        end
        puts "Complex Entity Data: #{complexData}"
        books
    end

end



  
