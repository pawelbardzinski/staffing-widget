@ipad
Feature: Enter Census Data
  As a staff member
  I want to enter census data 

Background:
  Given I may already be logged in, log out
  
Scenario: Coordinator inputs census 
  When I log in as "coordinator@staffingwidget.com"
  And the device is in portrait mode
  Then I wait to not see "Progress"
  Given I see the "Census Screen"
  Then I touch "Show Records"
  Then I wait to see "Census Records List"
  Then I touch "Upcoming"
  Then I wait to not see "Progress"
  Then I swipe left
  Then I reduce the census
  Then I increase the census
  Then I manually enter the census
  Then I touch the "Save" button
  Then I wait to not see "Progress"

Scenario: CNO not allowed to input census
  When I log in as "chiefofficer@staffingwidget.com"
  And the device is in portrait mode
  Then I wait to not see "Progress"
  Given I see the "Census Screen"
  Then I touch "Show Records"
  Then I wait to see "Census Records List"
  Then I touch "Upcoming"
  Then I wait to not see "Progress"
  Then I swipe left
  And I should not see a "Increase Census" button
  And I should not see a "Decrease Census" button
  And I should not see a "Save" button
  And I should not be allowed to edit the "Current Census" field
