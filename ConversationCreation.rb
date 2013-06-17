#!/usr/bin/ruby
require 'rubygems'
require 'json'
require 'Faker'

@fName = Faker::Name.name
conver=0
#Student conversation creator

=begin
while conver <= 20 do
  `curl "http://54.243.89.220/api/v1/conversations" \
        -F "recipients[]=#{conver}" \
        -F "body=Hello #{fname} you are student #{conver}" \
        -H "Authorization: Bearer 1~f8dS80fRXLgQoiQ1Pk7z8snZtzfXmCtopPygL8FuvHVuoJcWzHtARFzyTtYexyh2" | jsonpretty > curlOutput.txt`
    conver+=1
end
=end 

#Teacher conversation creator

while conver <= 20 do
  `curl "http://54.243.89.220/api/v1/conversations" \
        -F "recipients[]=#{conver}" \
        -F "body=Hello #{Faker::Name.name} you are student #{conver}" \
        -F "scope=unread" \
        -H "Authorization: Bearer 1~hLH6eGqviuyF80Ivswp7yn4QviABk77jYL2YVIodlT3gmJRYBOHZa8XzdZ2RnWjJ" | jsonpretty > curlOutput.txt`
    conver+=1
end



=begin
#TA conversation creator
while conver <= 100 do
  `curl "http://canvas.dev:3000/api/v1/conversations" \
        -F "recipients[]=#{conver}" \
        -F "body=Hello student #{conver}" \
        -H "Authorization: Bearer 1~XJBa2TeLFqO18RUEWdqxDplUqHbKP1ZjQ1PauOnmeYW89pEm40O9eegbaahfYYBG" | jsonpretty > curlOutput.txt`
    conver+=1
end
=end

#Designer conversation creator
=begin
while conver <= 100 do
  `curl "http://canvas.dev:3000/api/v1/conversations" \
        -F "recipients[]=#{conver}" \
        -F "body=Hello student #{conver}" \
        -H "Authorization: Bearer 1~tmJNf86TxsFxh8FjDJ9fvh7dyma0YylmjkAiKU43f8ky1LGumt8nYTy3JgNA8R75" | jsonpretty > curlOutput.txt`
    conver+=1
end
=end

#Account Admin
=begin
while conver <= 30 do
  `curl "http://canvas.dev:3000/api/v1/conversations" \
        -F "recipients[]=#{conver}" \
        -F "body=Hello student #{conver}" \
        -H "Authorization: Bearer 1~pIRB2SaNAWinPaev4UnQiEcA0tBxQh48g8EXRB9juecc7UTDRT26gnkcS8Y6Nque" | jsonpretty > curlOutput.txt`
    conver+=1
end
=end


#Observer conversation creator
=begin
while conver <= 100 do
  `curl "http://canvas.dev:3000/api/v1/conversations" \
        -F "recipients[]=#{conver}" \
        -F "body=Hello student #{conver}" \
        -H "Authorization: Bearer 1~c18RkT8sS0WRzyd6oqUG0iEjGL2A9CNcpIBD4z0dYh81RsPLfpOuStkmx27l3aAY" | jsonpretty > curlOutput.txt`
    conver+=1
end
=end
