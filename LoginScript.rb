require "selenium-webdriver"
require "rspec"
include RSpec::Expectations


describe "LoginScript" do

  before do
    @driver = Selenium::WebDriver.for :firefox
    @base_url = "https://testing.beta.instructure.com"
  end
  
  after do
    @driver.quit
  end
  
  it "should_login" do
    @driver.get(@base_url + "/login")
    @driver.find_element(:id, "pseudonym_session_unique_id").clear
    @driver.find_element(:id, "pseudonym_session_unique_id").send_keys "mteacher1"
    @driver.find_element(:id, "pseudonym_session_password").send_keys "instruct"
    @driver.find_element(:class, "btn-primary").click
    if @driver.find_element(:id, "topbar").displayed?
       puts "found"
    else
       puts "Not found"
    end
    
  end

  it "should_logout" do
     @driver.find_element(:link, "Logout").click  
  
  end
end
