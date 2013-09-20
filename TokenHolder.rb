#!/usr/bin/ruby
require 'csv'
#Screwed up on the latest commit :(
#Global/Constant Variables
$asterisk = "#" * 10
##########################################################
#(Method list)


#This class contains all the methods that the main program uses
class Helper

  CURRENT_DIR = File.expand_path(File.dirname(__FILE__))
  FILE_NAME = "#{CURRENT_DIR}/Token_Holder.csv"
  
  def initialize()
    @file_exist = File.exists?(FILE_NAME)
    @file_exist ? @load_csv=CSV.read(FILE_NAME) : @load_csv=[]
  end

  #Here are the variables that are needed in the methods below
  attr_accessor :num_token, :delete_row

  #If the file exists use the file that was created otherwise create a new one
  def print_users
    if !@load_csv.empty?
       @load_csv.each_with_index { |user,index|
       puts "#{index + 1}: #{user}"
       }
    else 
       puts "Nothing to display"    
    end
  end
  #This method writes to the csv file
  def write_to_csv(loadcsv)
    CSV.open(FILE_NAME,"wb")  {|csv|
     @load_csv.each do |line|
       csv << line
     end 
     }
  end

  #This method gets tokens from the user and puts them in the array
  def loads_tokens_csv(num_token)
   i = 1
    while i <= @num_token  
      puts "Give me the name of user #{i} you wish to save for later"
      @name=gets.chomp
      puts "Give me the role of user #{i} you wish to save for later"
      @role=gets.chomp
      puts "Give me the token of user #{i} you wish to save for later"
      @token=gets.chomp

      @load_csv << ["#{@name},","#{@role},","#{@token}" + "\n"]
      i += 1
    end
  end

  #This method deletes a user from the csv and then resaves the csv to memory
  def delete_user(csv,dr)
      @delete_offset = @delete_row - 1
      @load_csv.delete_at(@delete_offset)
      write_to_csv(@load_csv)
  end
end
#################################################################################
#(Main)
#

#Instantiate the Helper class
helper=Helper.new()

puts $asterisk
puts "This is a tool to hold your tokens for testing just make sure not to reset your database\n or you will lose your tokens"
puts $asterisk

begin

puts $asterisk
puts "1.Read the users you have saved so far\n2.Add new users"
puts "3.Delete a row\n4.Quit\n"
puts $asterisk
@choice=gets.chomp.to_i

  case @choice
    when 1 	    
      helper.print_users 
    when 2
      puts $asterisk
      puts "How many users did you want to save for now?"
      helper.num_token=gets.chomp.to_i
      puts $asterisk     
      
      helper.loads_tokens_csv(@num_token)

      helper.write_to_csv(@loadcsv)
    when 3
      #Not pretty but works
      puts $asterisk
      puts "Here is what I have so far"
      puts $asterisk
      helper.print_users
      puts $asterisk
      puts "Please give me the number you would like me to remove"
      puts $asterisk
      helper.delete_row = gets.chomp.to_i

      helper.delete_user(@load_csv,@delete_row)

  else
      puts $asterisk	  
      puts "Exiting"
      puts $asterisk
  end 
end until @choice == 4
