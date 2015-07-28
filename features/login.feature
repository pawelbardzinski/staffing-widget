Feature: Log In
  As a User
  I want to login 
  So I can begin using Stafficiency

Background:
  Given I may already be logged in, log out

@iphone
Scenario: Admin Login on iPhone
  When I log in as the admin user
  Then I see the worksheet screen

@ipad
Scenario: Admin Login on iPad
  When I log in as the admin user
  Then I wait to see "Census Screen"
  
@iphone 
Scenario: Coordinator Login on iPhone
  When I log in as "coordinator@staffingwidget.com"
  Then I see the worksheet screen

@ipad 
Scenario: Coordinator Login on iPad
  When I log in as "coordinator@staffingwidget.com"
  Then I wait to see "Census Screen"


