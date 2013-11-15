namespace :utility do
  desc 'generate a bunch of sections'
 
  task :create_sections => :environment do

    COURSE_ID = 9 #This can be whatever you want

    section_name = ["alpha", "bravo", "charlie", "delta", "echo", "foxtrot", "gulf", "hotel", "india", "juliet", "kilo", "lima", "mike", "november", "oscar", "papa", "quebec", "romeo", "sierra", "tango", "uniform", "vector", "whiskey", "xray", "yankee", "zulu"]

    c=Course.find(COURSE_ID)
    section_name.each do |i| 
	c.course_sections.create(:name => i)
	puts "section #{i} created" 
    end
  end
end
