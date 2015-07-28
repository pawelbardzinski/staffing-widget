And /^the device is in portrait mode$/ do
	if element_does_not_exist("button marked:'Show Records'")
		rotate(:left)
	end
end

Then /^I reduce the census$/ do
	currentCensus = query("textField marked:'Current Census'", :text).first.to_i
	macro 'I touch the "Decrease Census" button'
    # just in case the census is 0
	if (currentCensus != 0)
		assert query("textField marked:'Current Census'", :text).first.to_i < currentCensus
	end
end

Then /^I increase the census$/ do
	currentCensus = query("textField marked:'Current Census'", :text).first.to_i
	macro 'I touch the "Increase Census" button'
	macro 'I touch the "Increase Census" button'
	assert 	query("textField marked:'Current Census'", :text).first.to_i > currentCensus
end

Then /^I manually enter the census$/ do
	updatedPreviousCensus = query("label marked:'Previous Census'", :text).first.to_i - 1
 	macro %'I enter "#{updatedPreviousCensus}" into the "Current Census" input field'
	macro 'I touch done'
	assert query("textField marked:'Current Census'", :text).first.to_i == updatedPreviousCensus 
end

Then /^I should not be allowed to edit the "([^\"]*)" field$/ do |name|
	element_does_not_exist(query("textField marked:'Current Census' isEnabled:1"))
end