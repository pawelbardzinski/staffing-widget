Feature: Log In
  As a User
  I want to login 
  So I can begin entering census data

@iphone
Scenario: Admin Login on iPhone
  Given I may already be logged in, log out
  When I log in as the admin user
  Then I see the worksheet screen

@ipad
Scenario: Admin Login on iPad
  Given I may already be logged in, log out
  When I log in as the admin user
  Then I see the census screen
  
@iphone 
Scenario: Coordinator Login on iPhone
  Given I may already be logged in, log out
  When I log in as "coordinator@staffingwidget.com"
  Then I see the worksheet screen

@ipad 
Scenario: Coordinator Login on iPad
  Given I may already be logged in, log out
  When I log in as "coordinator@staffingwidget.com"
  Then I see the census screen


