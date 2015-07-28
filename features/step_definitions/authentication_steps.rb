Given /^I may already be logged in, log out$/ do
	# check if the alert exists
	if uia_query(:alert).count > 0
		# dismiss by touching 'OK'
		uia_tap_mark 'OK'
	end
	#wait for the existing reports to load
	macro 'I wait to not see "Progress"'
	if element_exists("button marked: 'Sign Out'")
		touch("button marked: 'Sign Out'")
	end
end

When /^I log in as the admin user$/ do
 	macro 'I wait to see "Username"'
	macro 'I enter "admin@test.com" into text field number 1'
	macro 'I enter "test" into text field number 2'
	macro 'I touch done'
	macro 'I should not see "Wrong username or password"'
	macro 'I wait to see "Sign Out"'
end

When /^I log in as "([^\"]*)"$/ do |name|
 	macro 'I wait to see "Username"'
	macro %'I enter "#{name}" into text field number 1'
	macro 'I enter "password" into text field number 2'
	macro 'I touch done'
	macro 'I should not see "Wrong username or password"'
	macro 'I wait to see "Sign Out"'
end