#!/usr/bin/ruby
require 'csv'

#Global/Constant Variables
CURRENT_DIR = File.expand_path(File.dirname(__FILE__))
FILE_NAME = "#{CURRENT_DIR}/Token_Holder.csv"
ASTERISK = "#######################################################################"
#If the file exists use the file that was created otherwise create a new one
if File.exists?(FILE_NAME)  == true
  @load_csv=CSV.read(FILE_NAME)
else 
  @load_csv=[]
end  
##########################################################
#(Method list)
#This method prints out contents of the csv file

def print_users
    @load_csv.each_with_index { |user,index|
    puts "#{index + 1}: #{user}"
    }
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

#################################################################################
#(Main)
#
puts ASTERISK
puts "This is a tool to hold your tokens for testing just make sure not to reset your database\n or you will lose your tokens"
puts ASTERISK
begin

puts ASTERISK
puts "1.Read the users you have saved so far\n2.Add new users"
puts "3.Delete a row\n4.Quit\n"
puts ASTERISK
@choice=gets.chomp.to_i
=begin
while the choice is not 4 continue to ask user what they want to do
=end
  case @choice
    when 1 	    
      print_users 
    when 2
      puts ASTERISK
      puts "How many users did you want to save for now?"
      @num_token=gets.chomp.to_i
      puts ASTERISK     
      
      loads_tokens_csv(@num_token)

      write_to_csv(@loadcsv)
    when 3
      #Not pretty but works
      puts ASTERISK
      puts "Here is what I have so far"
      puts ASTERISK
      print_users
      puts ASTERISK
      puts "Please give me the number you would like me to remove"
      puts ASTERISK
      @delete_row = gets.chomp.to_i

      delete_user(@load_csv,@delete_row)

  else
      puts ASTERISK	  
      puts "Exiting"
      puts ASTERISK
  end
end until @choice == 4
# load existing CSV file into memory
# prompt user for actions
#   - list - param for filtering (i.e. list users, list ma*)
#   - get
#   - del
#   - add
#   - edit
#   - quit
#   - Load token into clipboard
# on change of data, persist in memory data to CSV again
